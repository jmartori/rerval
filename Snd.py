from queue import Queue
from threading import Thread
import json
import socket
import copy
import logging

# for the tc_client
import numpy as np

def jdefault(o):
		return o.__dict__

def isLost(p):
	v = np.random.choice([False, True], size=1, p=[1-p, p])
	return(v[0])


class Snd:
	def __init__ (self, src_id, host, port, sock, vc, log, stats, config):
		self.d_stats = stats
		self.d_stats['count_queue_snd'] = 0
		self.d_stats['count_snd'] = 0
		self.d_stats['count_drop'] = 0
		self.config = config
		self.src_id = src_id
		self.host = host
		self.port = port
		self.sock = sock #socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
		self.vc = vc
		self.log = log
		self.socketType = config['default']['SocketType']

		# TC client for udp message loss
		if config['tcClient']['enabled'] == "True":
			self.tc_enabled = True
		else:
			self.tc_enabled = False
		self.isLost = isLost
		self.tc_ploss = float(config['tcClient']['p_loss'])

		self.q_snd = Queue()
		self.snd_thread = Thread(target=self.worker)
		self.snd_thread.daemon = True
		self.snd_thread.start()



	def bj(self):
		msg = dict()

		msg['type'] = "BJ"
		msg['src_id'] = self.src_id

		if self.socketType == 'tcp':
			self.q_snd.put((msg, self.sock))
		else:
			self.q_snd.put((msg, None))

	def send_all(self, str_msg, vc):
		msg = dict()


		msg['type'] = "DATA_2ALL"
		msg['src_id'] = self.src_id
		msg['vc'] = vc
		msg['msg'] = str_msg

		# Why deepcopy here??
		#self.q_snd.put(copy.deepcopy(msg))
		if self.socketType == 'tcp':
			for dst_id, conn in self.d_stats['ms_conns'].items():
				if not int(dst_id) == int(self.src_id):
					self.q_snd.put((copy.deepcopy(msg), conn))
		else:
			self.q_snd.put((copy.deepcopy(msg), None))

		# it not we get just the references!!
		logging.debug("[stats] (Q, " + str(self.src_id) + ", " + str(self.vc.vc[self.src_id]) + ")")
		self.log.append(copy.deepcopy(msg))

		self.vc.inc(self.vc.key)

	def ack(self, dst_id, vc):
		pass
		# msg = dict()
		# msg['type'] = 'ack'
		# msg['src_id'] = self.src_id
		# msg['dst_id'] = dst_id
		# msg['vc'] = vc

		#self.q_snd.put(msg)

	# Its a dangeours function!!
	# So maybe dont use me?? 
	# def send(self,d):
	# 	self.q_snd.put(d)
	# 	self.d_stats['count_queue_snd'] +=1

	def missing(self, dst_id, num):
		msg = dict()

		msg['src_id'] = self.src_id
		msg['type'] = 'missing'
		msg['dst_id'] = dst_id
		msg['num'] = num

		if self.socketType == 'tcp':
			self.q_snd.put((msg, self.d_stats['ms_conns'][dst_id]))
		else:
			self.q_snd.put((msg, None))
		
		logging.debug("[stats] (SM, " + str(dst_id) + ", " + str(self.src_id) + ", " + str(num) + ")")


	def recovery(self,dst_id,vc, str_msg):
		msg = dict()

		msg['type'] = 'recovery'
		msg['src_id'] = self.src_id
		msg['dst_id'] = dst_id
		msg['vc'] = vc
		msg['msg'] = str_msg

		if self.socketType == 'tcp':
			self.q_snd.put((msg, self.d_stats['ms_conns'][dst_id]))
		else:
			self.q_snd.put((msg, None))
		# str_msg should be the num of the message (if it was generated by repl_client: storm <int> <time> )
		logging.debug("[stats] (SR, " + str(dst_id) + ", " + str(self.src_id) + ", " + str(str_msg) + ")")

	def send_p2p(self, dst_id, vc, str_msg):
		msg = dict()

		msg['type'] = 'DATA_P2P'
		msg['src_id'] = self.src_id
		msg['dst_id'] = dst_id
		msg['vc'] = vc
		msg['msg'] = str_msg

		if self.socketType == 'tcp':
			self.q_snd.put((msg, self.d_stats['ms_conns'][dst_id]))
		else:
			self.q_snd.put((msg, None))

	def send_ar(self):
		msg = dict()
		msg['type'] = "AR"
		msg['src_id'] = self.src_id

		if self.socketType == 'tcp':
			self.q_snd.put((msg, self.sock))
		else:
			self.q_snd.put((msg, None))

	def worker(self):
		while True:
			# Queue get blocks the worker until a item is retrieved.	
			item, sock = self.q_snd.get()

			
			if self.socketType == 'udp':
			# UDP
				if (self.tc_enabled == True and not self.isLost(self.tc_ploss)) or self.tc_enabled == False:
					self.sock.sendto(bytes(json.dumps(item, default=jdefault),"utf-8"),(self.host, self.port))
				else: #the message was "lost"
					self.d_stats['count_drop'] += 1	

			else:
			# TCP
				sock.send(bytes(json.dumps(item, default=jdefault),"utf-8"))
			
			self.d_stats['count_snd'] += 1

			# There is a -1 because the send_all fucntion added +1 to the vc 
			logging.debug("[stats] (S, " + str(self.src_id) + ", " + str(self.vc.vc[self.src_id]-1) + ")")
			self.q_snd.task_done()
