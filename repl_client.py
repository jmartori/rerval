import socket
import sys

import time
import signal, os

import json
from Snd import Snd

from VectorClock import VectorClock
from Rcv import Rcv
from threading import Thread

import numpy as np

# for the CMD import 
try:
    import gnureadline
    import sys
    sys.modules['readline'] = gnureadline
except ImportError:
    pass
import cmd

import configparser

import logging
# def id_generator(size=7, chars=string.ascii_uppercase + string.digits):
# 	return ''.join(random.choice(chars) for _ in range(size))
# clientId = "C-" + id_generator(size=5)

def deliv_worker():
	while True:
		item = rcv.q_deliv.get()
		d_stats['l_deliv'].append(item)
		d_stats['count_deliv'] += 1



#### START MAIN #### 

if __name__ == "__main__":
	config_filename, clientId = sys.argv[1], int(sys.argv[2])

	# Load config
	config = configparser.ConfigParser()
	config.read(config_filename)

	# Start Logging 
	logging.basicConfig(filename=config['default']['LogFilename']+str(clientId)+"."+config['default']['LogExt'], filemode="a", level=logging.DEBUG, format='[%(asctime)s] (%(levelname)s) %(message)s')
	logging.critical("Starting Client " + str(clientId))


	if config['default']['SocketType'] == 'udp':
		sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	elif config['default']['SocketType'] == 'tcp':
		sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
		sock.connect((config['default']['ServerAddress'], int(config['default']['ServerPort']) ))
	else:
		print("Error: SocketType is neither udp or tcp.")
		exit(1)


	d_stats = dict()
	d_stats['t_init'] = int(time.strftime("%s"))

	vc = VectorClock(static=bool(config['VectorClock']['Static']), max_entries=int(config['VectorClock']['MaxEntries']), key=clientId)

	log = list() # To append and recorder all sent operations.
	snd = Snd(clientId, host=config['default']['ServerAddress'], port=int(config['default']['ServerPort']), sock=sock, vc=vc, log = log, stats = d_stats, config = config)
	rcv = Rcv(clientId, host=config['default']['ServerAddress'], port=int(config['default']['ServerPort']), sock=sock, vc=vc, snd=snd, log = log, stats = d_stats, config = config)


	deliv_thread = Thread(target=deliv_worker)
	deliv_thread.daemon = True
	deliv_thread.start()

	d_stats['storm_val'] = 0
	d_stats['count_deliv'] = 0
	d_stats['l_deliv'] = list()
	d_stats['vc'] = vc
	d_stats['membership'] = dict()
	d_stats['ms_conns'] = dict()

	d_stats['config'] = config



	class ReplCli(cmd.Cmd):
		def __init__(self, client_id, stats):
			cmd.Cmd.__init__(self)
			self.client_id = client_id
			self.stats = stats
			self.prompt = "(Client " + str(client_id) + ") "

		def do_bj(self, line):
			snd.bj()

		def help_bj(self):
			print('\n'.join([
				'bj',
				'Send a bonjour message to the server.',
			]))

		def do_exit(self, line):
			return True
		
		def help_exit(self):
			print('\n'.join([
				'exit',
				'Send a goodbye message to the server, and leave.',
			]))

		def do_storm(self, line):
			val = line.split()
			sp_time = float(val[1])
			t0 = time.time()
			for i in range(int(val[0])):
				snd.send_all(str_msg=str( i + d_stats['storm_val']), vc=vc)
				# as in a 'uniform' distribution. Its not but is would/could look like one.
				if not sp_time == 0:
					time.sleep(sp_time)
			t1 = time.time()
			d_stats['storm_val']+=int(val[0])
			delta_t = t1 - t0
			print("Elapsed: " + str(delta_t))
			print("Rate: " + str(float(val[0])/delta_t))

		def help_storm(self):
			print('\n'.join([
				'storm <num> <delay>',
				'Generates messages to send to the connected clients.',
			]))

		def do_run(self, line):
			val = line.split()
			for t in [0.1, 0.01, 0.001, 0.0001, 0.00001]:	
				for i in range(int(val[0])):
					snd.send_all(str_msg=str( i + d_stats['storm_val']), vc=vc)
					# as in a 'uniform' distribution. Its not but is would/could look like one.
					time.sleep(t)
				d_stats['storm_val']+=int(val[0])

		def do_log(self, line):
			val = line.split()	
			if len(val) > 0:
				if val[0] == "send":
					print(self.stats['log'])
				elif val[0] == "limbo":
					print(self.stats['l_limbo'])
				elif val[0] == "membership":
					print(self.stats['membership'])
				# elif val[0] == "deliv":
				# 	print(d_stats['l_deliv'])
				# elif val[0] == "dups":
				# 	print (rcv.dups)
		def do_vc (self,line):
			print(self.stats['vc'])
		
		def help_log(self):
			print('\n'.join([
				'log <send>|<limbo>|<deliv>|<dups>',
				'Prints some inner client info.',
			]))	

		def do_flush(self, line):
			print('Not Yet implemented')
			# val = line.split()	
			# if val[0] == "limbo":
			# 	for i in range(len(rcv.l_limbo)):
			# 		del rcv.l_limbo[0]
		
		def help_flush(self):
			print('\n'.join([
				'flush <limbo>',
				'Removes all limbo data.',
			]))
		def do_exec(self, line):
			try:
				print(exec( "print(" + line + ")"))
			except:
				pass

		def help_exec(self):
			print('\n'.join([
				'exec <line>',
				'Executes the given expression. No questions asked.',
			]))

		def do_summary(self, line):
			print(self.stats['tvop'])
			print(self.stats['count_missing'])
			print(self.stats['count_deliv'])

		def do_sleep(self, line):
			time.sleep(float(line))

		def do_time(self, line):
			print(time.time())

	ReplCli(client_id = clientId, stats = d_stats).cmdloop()
