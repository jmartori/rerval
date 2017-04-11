import socket
import threading
import socketserver as SocketServer
import sys
import time
import json
import logging
import signal

from threading import Thread

from queue import Queue

import numpy as np
from random import shuffle

# Fets per mi
from TCPServer import TCPServer
from Observer import Observer

import configparser

import copy


# def signal_handler(signal, frame):
# 	logging.info("Exiting ... ")
# 	server.shutdown()
def jdefault(o):

		return o.__dict__

def elapsed_time():

	return (int(time.strftime("%s")) - d_stats['t_init'])

# f is the function that generates the random values
# n is the number of element.
def plan_journey(f, n):
	# Should come from config and/or CLI
	p_loss = float(config['tc']['p_loss']) #f_lat_modelat(config['tc']['p_loss'])

	try:
		s = np.sort(f(n))
		s = np.insert(np.diff(s), 0, s[0])
		
		# inspired by Francesc Martori's thoughts
		v = np.random.choice([1,-1], size=n, p=[1-p_loss, p_loss])
		
		# So that we have ms we divide by 1000
		# if the message is loss, then it becomes negative. and the choice with the -1 means that either stays the same or goes negative with the p of p_loss
		v = (s/1000) * v
		#logging.debug(str(v) + " Journey Plan")
		return(v)
	except Exception:
		pass

def hybrid(n):
	p_exp = float(config['tc']['p_exp_hybrid'])
	exp_l = float(config['tc']['exp_lambda'])
	par_shape = float(config['tc']['par_shape'])
	par_scale = float(config['tc']['par_scale'])

	v_par = ((np.random.pareto(par_shape, n) + 1) * par_scale)
	v_exp = np.random.exponential(exp_l, size=n)

	v = np.concatenate([v_exp,v_par])
	v_p = np.concatenate([np.repeat(p_exp, n)/n, np.repeat(1-p_exp, n)/n])

	v = np.random.choice(v, size=n, p=v_p, replace=True)
	return(v)

def uniform(n):
	high = float(config['tc']['high_uniform'])
	v = np.random.uniform(size = n, low = 0, high = high)

	return (v)
	
def static(n):
	val = float(config['tc']['val_static'])
	p = float(config['tc']['prob_static'])

	v = np.random.choice([0,val], size=n, p=[1-p, p])

	return(v)

def pareto(n):
	# They should go to configuration or something
	a = float(config['tc']['par_shape'])
	m = float(config['tc']['par_scale'])
	return((np.random.pareto(a, n) + 1) * m)

def exponential(n):
	l = float(config['tc']['exp_lambda'])

	return(np.random.exponential(l, size=n))

def asBool(s):
	if s == 'False':
		return False
	elif s == 'True':
		return True
	else:
		# Or quantum logic not here please
		raise(SoThatWasNotAndOption)


class MyUDPHandler(SocketServer.BaseRequestHandler):
	def process_msg(self, d_rcv, t_init, socket, neighbours_ids, neighbours_lastmsg_time, f_lat_model, tc_enabled):
		msg_type = d_rcv['type']
		msg_src_id = d_rcv['src_id']

		msg_src_addr = self.client_address

		if msg_type == "BJ": # msg is BonJour
			neighbours_ids[msg_src_id] = msg_src_addr
			neighbours_lastmsg_time[msg_src_id] = elapsed_time()

			msg = dict()
			msg['type'] = 'ack'
			msg['src_id'] = msg_src_id
			self.send(socket, json.dumps(msg), neighbours_ids[msg_src_id]) ## msg_src_addr
			#logging.info("Type BJ from " + str(msg_src_id))
			d_stats['conns'] += 1

		elif msg_type == "AR":
			msg = dict()
			if msg_src_id in neighbours_ids and msg_src_id in neighbours_lastmsg_time:
				del neighbours_ids[msg_src_id]
				del neighbours_lastmsg_time[msg_src_id]

				msg['type'] = 'ack'
				
				d_stats['conns'] -= 1
				#logging.info("Type AR from " + str(msg_src_id))
			else:
				msg['type'] = 'nack'
				msg['msg'] = "Wrong msg_src_id. Couldn't AR."

			self.send(socket,json.dumps(msg), msg_src_addr)

		elif msg_type == "DATA_P2P":
			msg_dst_id = d_rcv['dst_id']
			msg_dst_addr = neighbours_ids[msg_dst_id]
			neighbours_lastmsg_time[msg_src_id] = elapsed_time()

			msg = dict()
			msg['type'] = msg_type
			msg['src_id'] = msg_src_id
			msg['dst_id'] = msg_dst_id
			msg['vc'] = d_rcv['vc']
			msg['msg'] = d_rcv['msg']

			if tc_enabled:
				v = plan_journey( f=f_lat_model, n=1)
				if v[0] >= 0:
					time.sleep(v[0])
					self.send(socket,json.dumps(msg), msg_dst_addr)
			else:	
				self.send(socket,json.dumps(msg), msg_dst_addr)
			
			#logging.info("Type P2P from " + str(msg_src_id) + " to " + str(msg_dst_id))

		elif msg_type == "recovery":
			msg_dst_id = d_rcv['dst_id']
			msg_dst_addr = neighbours_ids[msg_dst_id]
			neighbours_lastmsg_time[msg_src_id] = elapsed_time()

			msg = dict()
			msg['type'] = msg_type
			msg['src_id'] = msg_src_id
			msg['dst_id'] = msg_dst_id
			msg['vc'] = d_rcv['vc']
			msg['msg'] = d_rcv['msg']

			if tc_enabled:
				v = plan_journey( f=f_lat_model, n=1)
				if v[0] >= 0:
					time.sleep(v[0])
					self.send(socket,json.dumps(msg), msg_dst_addr)
			else:
				self.send(socket,json.dumps(msg), msg_dst_addr)

		elif msg_type == "DATA_2ALL":
			neighbours_lastmsg_time[msg_src_id] = elapsed_time()
			msg = dict()
			msg['type'] = msg_type
			msg['src_id'] = msg_src_id
			msg['msg'] = d_rcv['msg']
			msg['vc'] = d_rcv['vc']

			# plan for delays.

			l = list(neighbours_ids.items())
			if tc_enabled:
				np.random.shuffle(l)
				v = plan_journey( f=f_lat_model, n=len(l))

				for msg_id,msg_dst_addr in l:
					if not msg_dst_addr == msg_src_addr:
						if v[0] >= 0:
							time.sleep(v[0])
							self.send(socket,json.dumps(msg), msg_dst_addr)
						#else its a drop
						v = np.delete(v,0)
			else:
				for msg_id,msg_dst_addr in l:
					if not msg_dst_addr == msg_src_addr:
						self.send(socket,json.dumps(msg), msg_dst_addr)

			# msg = dict()
			# msg['type'] = 'ack'
			# self.send(socket,json.dumps(msg), msg_src_addr)
			#logging.info("Type 2ALL from " + str(msg_src_id))

		elif msg_type == "ack":
			msg_dst_id = d_rcv['dst_id']
			msg_dst_addr = neighbours_ids[msg_dst_id]
			neighbours_lastmsg_time[msg_src_id] = elapsed_time()

			msg = dict()
			msg['type'] = msg_type
			msg['src_id'] = msg_src_id
			msg['vc'] = d_rcv['vc']

			self.send(socket,json.dumps(msg), msg_dst_addr)

		elif msg_type == "missing":
			msg_dst_id = d_rcv['dst_id']
			try:
				msg_dst_addr = neighbours_ids[msg_dst_id]
			except KeyError:
				print("L150 Server.py : " + str(d_rcv))
				pass
			else:
				neighbours_lastmsg_time[msg_src_id] = elapsed_time()

				msg = dict()
				msg['type'] = msg_type
				msg['src_id'] = msg_src_id
				msg['num'] = d_rcv['num']
				
				if tc_enabled:
					v = plan_journey( f=f_lat_model, n=1)
					if v[0] >= 0:
						time.sleep(v[0])
						self.send(socket,json.dumps(msg), msg_dst_addr)
				else:
					self.send(socket,json.dumps(msg), msg_dst_addr)

		else:
			# If we get here, something went wrong!!!
			logging.debug("Error: msg_type doesn't exist")

	def send(self,socket,json_msg,addr):

		socket.sendto(bytes(json_msg,"utf-8"), addr)

	def handle(self):
		#logging.debug("Start of Handle")
		self.socket_type = config['Server']['SocketType']
		s_tc_enabled = config['tc']['enabled']
		tc_enabled = asBool(s_tc_enabled)

		# the eval is to convert the str into a function
		f_lat_model = eval(config['tc']['func_lat_model'])

		d_stats['count_rcv_msg'] += 1
		neighbours_ids = d_stats['neighbours_ids'] # Unnecessary. but its works as an alias. # Fix them in the future.
		neighbours_lastmsg_time = d_stats['neighbours_lastmsg_time']
		t_init = d_stats['t_init'] 

		data = self.request[0].strip()
		socket = self.request[1]
		
		try:
			d_rcv = json.loads(data.decode("utf-8"))
		except ValueError:
			logging.debug("JSON Couldn't load the message!")
			return 
		else:
			#l_threads = d_stats['l_threads']
			logging.debug(str(d_stats['count_rcv_msg']) + " " + str(d_rcv))
			t = Thread(target=self.process_msg, args=[d_rcv, t_init, socket, neighbours_ids, neighbours_lastmsg_time, f_lat_model, tc_enabled])
			t.daemon = True
			#l_threads.append(t)
			t.start()

if __name__ == "__main__":
	# Input Parameters
	config_filename = sys.argv[1]
	config = configparser.ConfigParser()
	config.read(config_filename)

	logging.basicConfig(filename=config['Server']['LogFilename'], filemode="w", level=logging.DEBUG, format='[%(asctime)s] (%(levelname)s) %(message)s')
	logging.critical("Starting Server")
	
	
	d_stats	= dict()
	d_stats['config'] = config
	d_stats['neighbours_ids'] = dict()
	d_stats['neighbours_lastmsg_time'] = dict()
	d_stats['t_init'] = int(time.strftime("%s"))
	d_stats['server_id'] = 1
	d_stats['membership'] = dict()
	d_stats['l_threads'] = list()
	d_stats['count_rcv_msg'] = 0

	d_stats['conns'] = 0

	# Launching server
	if config['Server']['SocketType'] == 'udp':
		server = SocketServer.UDPServer((config['Server']['ListeningToAddress'], int(config['Server']['ListeningToPort'])), MyUDPHandler)
	elif config['Server']['SocketType'] == 'tcp':
		server = TCPServer(config['Server']['ListeningToAddress'], int(config['Server']['ListeningToPort']), max_threads = 16, stats=d_stats, config = config, queue=None, whoami='server')
	else:
		logging.critical("Error: SocketType is neither udp or tcp.")
		exit(1)

	# Launching Observer

	obs = Observer(server, d_stats)

	# Now listen to petitions
	server.serve_forever()

