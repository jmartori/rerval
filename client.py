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



	##
	snd.bj()

	# Should we wait a bit so every client is listening?? Yes
	time.sleep(float(config['Client']['waitTimeBeforeStorm']))
	print("Let the show begin!")
	sys.stdout.flush()

	sp_time = 1/float(config['Client']['rateOperations'])

	t0 = time.time()
	for i in range(int(config['Client']['numOperations'])):
		snd.send_all(str_msg=str(i), vc=vc)
		if not sp_time == 0:
			time.sleep(sp_time)
	t1 = time.time()

	# write d_stats to log? 
	flag = 1
	while flag:
		for entry in vc.vc:
			if not entry == 0:
				if not entry == config['Client']['numOperations']:
					flag = 0
		if not flag == 0:
			flag += 1
			if flag == 4:
				flag = 0
				logging.debug("Exit without VC complete.")

		# if we are not leaving, wait a bit.
		if not flag:
			time.sleep(float(config['Client']['waitTimeAfterStorm']))

	snd.send_ar()


	str_stats = str(d_stats["count_drop"]) + "," + str(d_stats["count_snd"]) + "," + str(d_stats["count_missing"]) + "," + str(d_stats["count_recovery"]) + "," + str(d_stats['count_deliv']) + "," + str(d_stats["count_limbo"]) + "," + str(d_stats["already_in_limbo"]) + "," + str(d_stats["already_in_rer"]) + "," + str(d_stats["tvop"]) + "," + str(d_stats["count_fp"]) + "," + str(d_stats["count_A3"])
	logging.debug(str_stats)
	with open('summary_' + str(clientId) + ".log", "w") as f:
		f.write(str_stats)
		f.write("\n")

