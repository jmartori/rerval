from threading import Thread
from queue import Queue

import logging
import socket
import json

import copy

import time

class TCPServer:
	def __init__(self, host, port, max_threads, stats, config, whoami, queue):
		self.host = host
		self.port = port
		self.config = config

		self.stats = stats

		self.whoami = whoami

		self.queue = queue

		# not yet enforced
		self.max_threads = max_threads
		self.t_listeners = list()

		self.workers_id = 0
		self.conns = dict()
		self.shutdown_now = False

		self.t_init = stats['t_init']

	def elapsed_time(self):
		return (int(time.strftime("%s")) - self.t_init)

	def send(self, conn, json_msg):
		conn.send(bytes(json_msg,"utf-8"))

	def serve_forever(self):
		sock = socket.socket()
		try:
			sock.bind((self.host, self.port))
		except OSError:
			print("Address already in use.")
			logging.critical("Address already in use.")
			return False
		else:
			sock.settimeout(int(self.config['Server']['ListenTimeOut']))
			while not self.shutdown_now:
				# We have to make a time out in accept so that the shutdown_now work before a user connects.
				try:
					sock.listen(5)
					conn, addr = sock.accept()
				except socket.timeout:
					pass
				else:
					# This means that the clients id has to be the same as the worker_id or
					# we are screwed.
					self.conns[self.workers_id] = conn

					t = Thread(target=self.worker, args=(self.workers_id, conn))

					t.daemon = True
					t.start()

					self.t_listeners.append(t)

					self.workers_id += 1

		return True

	def shutdown(self):
		self.shutdown_now = True
		# Check if sth else needs to be cleaned
		return True

	def worker(self, num, conn):
		msg = ""
		f = False
		cp = 0
		while not self.shutdown_now:
			if self.whoami == 'client':
				rcv = conn.recv(1).decode("utf-8")
				if len(rcv) > 0:
					msg += rcv
					if rcv == '{':
						f = True
						cp += 1
					elif rcv == '}':
						cp -= 1

					if cp == 0 and f == True:
						self.queue.put(msg)
						logging.debug(msg)
						msg = ""
						f = False
			else:
				msg = conn.recv(1024).decode("utf-8")
				if len(msg) > 0:
					self.handle(msg, num, conn)
		conn.close()

	def handle(self, msg, num, conn):
		logging.debug("Start of Handle")
		
		# Move them to a class with singleton.
		neighbours_ids = self.stats['neighbours_ids'] # Unnecessary. but its works as an alias. # Fix them in the future.
		neighbours_lastmsg_time = self.stats['neighbours_lastmsg_time']
		t_init = self.stats['t_init'] 
		
		try:
			d_rcv = json.loads(msg)
		except ValueError:
			return 
		else:
			# print(d_rcv)
			msg_type = d_rcv['type']
			msg_src_id = d_rcv['src_id']

			msg_src_addr = conn

			if msg_type == "BJ": # msg is BonJour
				neighbours_ids[msg_src_id] = msg_src_addr
				neighbours_lastmsg_time[msg_src_id] = self.elapsed_time()
				# [0] so that we only get the ip address and not the port.
				self.stats['membership'][msg_src_id] = conn.getpeername()[0]

				msg = dict()
				msg['type'] = 'ack_bj'
				msg['src_id'] = msg_src_id
				msg['msg'] = copy.deepcopy(self.stats['membership'])

				#Send a copy of the memberships/neighbours_ids to all the connected neighbours.
				for msg_id, conn_dst in neighbours_ids.items():
					self.send(conn_dst, json.dumps(msg))

				logging.info("Type BJ from " + str(msg_src_id))

			elif msg_type == "AR":
				msg = dict()
				if msg_src_id in neighbours_ids and msg_src_id in neighbours_lastmsg_time:
					del neighbours_ids[msg_src_id]
					del neighbours_lastmsg_time[msg_src_id]

					msg['type'] = 'ack'
					
					logging.info("Type AR from " + str(msg_src_id))
				else:
					msg['type'] = 'nack'
					msg['msg'] = "Wrong msg_src_id. Couldn't AR."

				self.send(conn,json.dumps(msg))

			elif msg_type == "DATA_P2P":
				msg_dst_id = d_rcv['dst_id']
				msg_dst_addr = neighbours_ids[msg_dst_id]
				neighbours_lastmsg_time[msg_src_id] = self.elapsed_time()

				msg = dict()
				msg['type'] = msg_type
				msg['src_id'] = msg_src_id
				msg['dst_id'] = msg_dst_id
				msg['vc'] = d_rcv['vc']
				msg['msg'] = d_rcv['msg']

				conn_dst = neighbours_ids[msg_dst_id]
				self.send(conn_dst, json.dumps(msg))

				msg = dict()
				msg['type'] = 'ack'
				self.send(conn,json.dumps(msg))
				logging.info("Type P2P from " + str(msg_src_id) + " to " + str(msg_dst_id))

			elif msg_type == "recovery":
				msg_dst_id = d_rcv['dst_id']
				msg_dst_addr = neighbours_ids[msg_dst_id]
				neighbours_lastmsg_time[msg_src_id] = self.elapsed_time()

				msg = dict()
				msg['type'] = msg_type
				msg['src_id'] = msg_src_id
				msg['dst_id'] = msg_dst_id
				msg['vc'] = d_rcv['vc']
				msg['msg'] = d_rcv['msg']

				conn_dst = neighbours_ids[msg_dst_id]
				self.send(conn_dst,json.dumps(msg))

			elif msg_type == "DATA_2ALL":
				neighbours_lastmsg_time[msg_src_id] = self.elapsed_time()
				msg = dict()
				msg['type'] = msg_type
				msg['src_id'] = msg_src_id
				msg['msg'] = d_rcv['msg']
				msg['vc'] = d_rcv['vc']

				### CHECK THE MSG_ID THING
				for msg_id,conn_dst in neighbours_ids.items():
					if not conn_dst == conn:
						self.send(conn_dst,json.dumps(msg))

				msg = dict()
				msg['type'] = 'ack'
				self.send(conn,json.dumps(msg))
				logging.info("Type 2ALL from " + str(msg_src_id))

			elif msg_type == "ack":
				msg_dst_id = d_rcv['dst_id']
				msg_dst_addr = neighbours_ids[msg_dst_id]
				neighbours_lastmsg_time[msg_src_id] = self.elapsed_time()

				msg = dict()
				msg['type'] = msg_type
				msg['src_id'] = msg_src_id
				msg['vc'] = d_rcv['vc']

				self.send(conn,json.dumps(msg))

			elif msg_type == "missing":
				msg_dst_id = d_rcv['dst_id']
				msg_dst_addr = neighbours_ids[msg_dst_id]
				neighbours_lastmsg_time[msg_src_id] = self.elapsed_time()

				msg = dict()
				msg['type'] = msg_type
				msg['src_id'] = msg_src_id
				msg['num'] = d_rcv['num']

				conn_dst = neighbours_ids[msg_dst_id]
				self.send(conn_dst,json.dumps(msg))

			else:
				# If we get here, something went wrong!!!
				raise(Hell)