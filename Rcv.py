from queue import Queue
from threading import Thread
from threading import Semaphore
import json
import socket
from VectorClock import VectorClock
import copy
import hashlib
import time

import logging

# so that the TCP_client can behave like "servers"
from TCPServer import TCPServer

def jdefault(o):
		return(o.__dict__)

class Rcv:
	def __init__ (self, src_id, host, port, vc, sock, snd, log, stats, config):
		#self.logging = logging
		self.src_id = src_id
		self.config = config
		self.host = host
		self.port = port
		self.sock = sock
		self.vc = vc
		self.log = log
		self.dups = set()
		self.sem_limbo = Semaphore()

		self.snd = snd

		self.d_stats = stats
		self.d_stats['count_ack'] = 0
		self.d_stats['count_nack'] = 0
		self.d_stats['count_dup'] = 0
		self.d_stats['tvop'] = 0 # stands for, The Virtue Of Patience, and counts the number of ops "recovered" it waiting time.
								# But it really doesnt because is not counting properly.
		self.d_stats['count_missing'] = 0
		self.d_stats['count_recovery'] = 0
		self.d_stats['count_received'] = 0
		self.d_stats["count_limbo"] = 0
		self.d_stats["count_fp"] = 0
		self.d_stats["count_A3"] = 0
		
		self.d_stats["already_in_limbo"] = 0
		self.d_stats["already_in_rer"] = 0


		# Dict to store missing operations for RER to wait
		self.rer = dict()
		self.wt = float(self.config['rer']['wt'])
		self.wt_iter = float(self.config['rer']['wtIter']) # If 0, it with eat to many resources (now waits ~1ms)

		# Limbo HeartBeat
		self.hb = float(self.config['limbo']['hb'])

		# Received messages
		self.q_rcv = Queue()

		# Messages with dependencies to be fulfilled
		self.l_limbo = list()

		# Messages ready to be used by the application
		self.q_deliv = Queue()

		self.rcv_thread = Thread(target=self.worker)
		self.rcv_thread.daemon = True
		self.rcv_thread.start()

		self.rer_thread = Thread(target=self.rer_worker)
		self.rer_thread.daemon = True
		self.rer_thread.start()

		self.processer_thread = Thread(target=self.checker)
		self.processer_thread.daemon = True
		self.processer_thread.start()

		self.processer_thread = Thread(target=self.limbo_hb)
		self.processer_thread.daemon = True
		self.processer_thread.start()

		# Only for TCP
		if config['default']['SocketType'] == 'tcp':
			self.server = TCPServer(config['Server']['ListeningToAddress'], int(config['Server']['ListeningToPort']), max_threads = 16, stats=stats, config = config, queue = self.q_rcv, whoami = 'client')
			self.server_thread = Thread(target=self.server.serve_forever)
			self.d_stats['ms_conns'] = self.server.conns
			self.server_thread.daemon = True
			self.server_thread.start()

		self.d_stats['l_limbo'] = self.l_limbo
		self.d_stats['log'] = self.log

		self.d_stats['last_vc_seen'] = None

	def limbo_hb(self):

		while True:
			# To dissable this, just add a ridiculously large hb time and done!
			time.sleep(self.hb)

			# Check in the limbo
			old_len = 0
			len_j = len(self.l_limbo)
			for j in range (len_j):
				len_i = len(self.l_limbo)
				old_len = len(self.l_limbo)
				mark_for_deletion = list()
				for i in range(len_i):
						item = self.l_limbo[i]
						if self.vc.happened_before(item['vc']):
							self.vc.inc(item['vc'].key)
							self.q_deliv.put(item['msg'])
							# its been delivered, so leave the limbo
							
							#del self.l_limbo[i-1]
							mark_for_deletion.append(i)
						# else:
						# 	# ask again
						# 	for entry in range(0, self.vc.max_entries-1):
						# 		if self.vc.vc[entry] < item['vc'].vc[entry]:
						# 			# This may generate duplicate values, that we are not checking
						# 			self.rer[(entry,self.vc.vc[entry])] = time.time()

				for e in reversed(mark_for_deletion):
					del self.l_limbo[e]					

				if old_len == len(self.l_limbo):
					# no message was recovered. so lets break out
					# if some message was recovered, lets try again and again.
					## A better data structure would make this easier and faster.
					break

	def rer_worker(self):
		self.d_stats['rer'] = dict()
		self.d_stats['rer']['send_missing'] = 0
		self.d_stats['rer']['count_missing'] = 0
		self.d_stats['rer']['waiting'] = self.rer

		#if self.config['default']['SocketType'] == 'udp':
		if self.config['rer']['enabled'] == "True":
			while True:
				# Sleep a bit, and then go work
				time.sleep(self.wt_iter)

				cur_time = time.time()
				
				#entry[1] is num
				#entry[0] is dst_id
				self.d_stats['rer']['count_missing'] = len(self.rer)			
				for entry in list(self.rer):
					try:
						if 	self.rer[entry] + self.wt < cur_time:
							self.snd.missing(num=entry[1], dst_id=entry[0])
							del self.rer[entry]
							self.d_stats['rer']['send_missing'] += 1
					except KeyError:
						#print ("KE: rer_worker >>> " + str(entry))
						continue						
		# The RER is not enabled so the thread "dies"
		#else:
		# TCP Doesnt need recovery, no??
			
	def worker(self):
		while True:
			try: 
				if self.config['default']['SocketType'] == 'tcp':
					# Here we receive the messages from the Server. The messages that come from 
					# the clients are received from TCPServer
					while True:
						received = self.sock.recv(1024).decode("utf-8")
						
						logging.debug("TCP Received Message")
						logging.debug(received)
						self.q_rcv.put(received)
				else:
					while True:
						received = self.sock.recv(1024).decode("utf-8")
						logging.debug("UDP Received Message")
							
						self.q_rcv.put(received)
			except UnicodeDecodeError:
				logging.debug("UnicodeDecodeError in a Received Message")
				pass
			else:
				self.q_rcv.put(received)
				#logging.debug("Message Received " + str(received))

	def inLimbo(self, dst_id, num):
		try:
			for item in list(self.l_limbo):
				if item.src_id == dst_id and item.vc.vc[dst_id] == num:
					return True
		except Exception:
			# write in logging
			logging.debug("Exception in inLimbo")
			return False
		return False

	def inRER (self, item):
		if (item['vc'].vc[item['src_id']], item['src_id']) in self.rer:
			return True
		return False


	def check_missing(self, item):
		for entry in range(0, self.vc.max_entries-1):
			if self.vc.vc[entry] < item['vc'].vc[entry]:
				# This may generate duplicate values, that we are not checking
				if not (entry,self.vc.vc[entry]) in self.rer:
					if not self.inLimbo(entry, self.vc.vc[entry]):
						self.rer[(entry, self.vc.vc[entry])] = time.time()
					else:
						self.d_stats['already_in_limbo'] += 1	
				else:
					self.d_stats['already_in_rer'] += 1

	def check_limbo(self):
		old_len = 0
		for j in range (len(self.l_limbo)):
			old_len = len(self.l_limbo)
			mark_for_deletion = list()
			for i in range(len(self.l_limbo)):
					item = self.l_limbo[i]
					if self.vc.happened_before(item['vc']):
						self.vc.inc(item['vc'].key)
						self.q_deliv.put(item['msg'])
						logging.debug("[stats] (D, " + str(item['src_id']) + ", " + str(self.src_id) + ", " + str(item['vc'].vc[item['src_id']]) + ")")
						# its been delivered, so leave the limbo
						
						#del self.l_limbo[i-1]
						mark_for_deletion.append(i)
					else:
						# ask again
						self.check_missing(item)


			for e in reversed(mark_for_deletion):
				del self.l_limbo[e]					

			if old_len == len(self.l_limbo):
				# no message was recovered. so lets break out
				# if some message was recovered, lets try again and again.
				## A better data structure would make this easier and faster.
				break

	def checker(self):
		# If item is ready to be delivered go ahead.
		#	And then check if the limbo item can be delivered.
		
		# Else add it to the limbo queue
		# 	And ask for the missing elements

		# Lets go!
		while True:
			try:
				item = json.loads(self.q_rcv.get())
			except ValueError:
				logging.debug("JSON Couldn't load the message!")
				continue
			else:
				#print(item)
				
				msg_type = item['type']
				# reassemble the vc if needed
				if msg_type == 'DATA_2ALL' or msg_type == 'DATA_P2P' or msg_type == 'recovery':	
					aux = VectorClock(static=True, max_entries=item['vc']['max_entries'], key=item['vc']['key'])
					aux.vc = item['vc']['vc']
					item['vc'] = aux
					self.d_stats['last_vc_seen'] = item['vc']
					if msg_type == 'recovery':
						self.d_stats['count_recovery'] += 1

					self.d_stats['count_received'] += 1

					logging.debug("[stats] (R, " + str(item['src_id']) + ", " + str(self.src_id) + ", " + str(item['vc'].vc[item['src_id']]) + ")")
					
					# Lets check if message is in the rer_worker waiting list
					# if its there we remove it and continue as normal.
					if self.inRER(item):
						del self.rer[(item['vc'].vc[item['src_id']], item['src_id'])]
						self.d_stats['tvop'] += 1



					# if the message is duplicated, means that it should already be delivered or in limbo
					if not self.duplicate(item['vc']):
						# Its ugly but we can check it here. for , A1, A2, A3 cases.
						if msg_type == 'recovery':
							logging.debug("I'm in receovery!( I know... its not funny)")

							if self.vc.vc[item['src_id']] >= item['vc'].vc[item['src_id']]:
								self.d_stats['count_fp'] += 1

						if self.vc.happened_before(item['vc']):
							# item can be delivered.
							
							self.vc.inc(item['vc'].key)
							self.q_deliv.put(item['msg'])
							#logging.debug("[stats] (D, " + str(item['src_id']) + ", " + str(self.src_id) + ", " + str(item['vc'].vc[item['src_id']]) + ")")
							if msg_type == 'recovery':
								# the message has been recovered. with the recovery
								logging.debug("[stats] (DR, " + str(item['src_id']) + ", " + str(self.src_id) + ", " + str(item['vc'].vc[item['src_id']]) + ")")
							else:
								logging.debug("[stats] (D, " + str(item['src_id']) + ", " + str(self.src_id) + ", " + str(item['vc'].vc[item['src_id']]) + ")")
							# Now Check if limbo stuff can be delivered.
							mark_for_deletion = list()
							len_i = len(self.l_limbo)
							for i in range(len_i):
								item = self.l_limbo[i]
								if self.vc.happened_before(item['vc']):
									self.vc.inc(item['vc'].key)
									self.q_deliv.put(item['msg'])
									logging.debug("[stats] (D, " + str(item['src_id']) + ", " + str(self.src_id) + ", " + str(item['vc'].vc[item['src_id']]) + ")")
									# its been delivered, so leave the limbo
									#del self.l_limbo[i]
									mark_for_deletion.append(i)

								else:
									# ask again
									self.check_missing(item)
							
							for i in reversed(mark_for_deletion):
								del self.l_limbo[i]

						else:
							#it couldnt be delivered, so add to limbo and ask for missing msgs
							self.l_limbo.append(item)
							self.d_stats["count_limbo"] += 1
							self.check_missing(item)
					else:
						if msg_type == 'recovery':
							self.d_stats['count_fp'] += 1
						elif msg_type == 'DATA_2ALL' or msg_type == 'DATA_P2P':
							self.d_stats['count_A3'] += 1
						# It was a duplicate but... you can check if something can be delivered.
						# Check in the limbo
						self.check_limbo()
						

				elif msg_type == 'ack':
					# What do we want to do with ack?? 
					self.d_stats['count_ack'] +=1

				elif msg_type == 'missing':

					# We send what they want.
					missing_msg = self.log[item['num']]
					self.snd.recovery( 
						dst_id = item['src_id'], 
						str_msg = missing_msg['msg'], 
						vc = missing_msg['vc']
					)
					self.d_stats['count_missing'] +=1

				elif msg_type == 'nack':
					# Something went wrong with the AR.
					self.d_stats['count_nack'] += 1

				elif msg_type == 'debug':
					print(item['msg'])

				elif msg_type == 'ack_bj':
					# We update the membership dict with what was sent.
					self.d_stats['membership'] = item['msg']

					# If dst_id exists but the address has changed, then we are screwed.
					for dst_id, address in self.d_stats['membership'].items():
						if not dst_id == self.src_id:
							if not dst_id in self.d_stats['ms_conns']:
								# We have to create the connection to this address.
								sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
								sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
								sock.connect((address, int(self.d_stats['config']['default']['ServerPort']) ))								
								self.d_stats['ms_conns'][dst_id] = sock


					v_fileno = list()
					v_id = list()
					for dst_id, conn in self.d_stats['ms_conns'].items():
						v_fileno.append(conn.fileno())
						v_id.append(dst_id)			

					self.d_stats['ms_fileno'] = v_fileno
					self.d_stats['ms_fileno_id'] = v_id
				self.q_rcv.task_done()

	def duplicate(self, o):
		hash_item = hashlib.md5(bytes(json.dumps(o, default=jdefault),"utf-8")).hexdigest()
		if hash_item in self.dups:
			return True
		else:
			self.dups.add(hash_item)
		return False