# class Singleton(object):
# 	_instances = {}
# 	def __new__(class_, *args, **kwargs):
# 		if class_ not in class_._instances:
# 			class_._instances[class_] = super(Singleton, class_).__new__(class_, *args, **kwargs)
# 			return class_._instances[class_]

# for the CMD import 
try:
    import gnureadline
    import sys
    sys.modules['readline'] = gnureadline
except ImportError:
    pass
import cmd

import time
from threading import Thread
import logging

class ReplCli(cmd.Cmd):
	def __init__(self, num, server, stats):
		cmd.Cmd.__init__(self)
		self.num = num
		self.prompt = "(Server "+ str(self.num) +") "
		self.stats = stats
		self.server = server

	def do_log(self, line):
		val = line.split()	
		
		if val[0] == "nids":
		 	print(self.stats['neighbours_ids'])
		if val[0] == "membership": 
			print(self.stats['membership'])
		# elif val[0] == "limbo":
		# 	print(rcv.l_limbo)
		# elif val[0] == "deliv":
		# 	print(d_stats['l_deliv'])
		# elif val[0] == "dups":
		# 	print (rcv.dups)
	
	def help_log(self):
		print('\n'.join([
			'log <nids>',
			'Prints some client info.',
		]))	

	def do_exit(self,line):
		logging.critical("Shuting down Server.")
		self.server.shutdown()
		return(-1)

	def help_exit(self):
		print("Exit and shutdown the server as properly as possible.")

	def do_exec(self, line):
		try:
			print(exec("print(" + line + ")"))
		except Exception:
			pass

	def do_config(self, line):
		val = line.split()
		try:
			
			if val[0] == 'write':
				if len(val) < 5:
					self.stats['config'][val[1]][val[2]] = str(val[3])
				else:
					pass
			elif val[0] == 'read':
				if len(val) < 4:
					print(self.stats['config'][val[1]][val[2]])
				else:
					pass
			else:
				pass
			
		except Exception:
		 	pass

	def help_exec(self):
		print('\n'.join([
			'exec <line>',
			'Executes the given expression. No questions asked.',
		]))


class Observer:
	def __init__(self, server, stats):
		self.input = ""
		self.server = server
		self.stats = stats

		self.cli_thread = Thread(target=ReplCli(num = self.stats['server_id'], server = server, stats = stats).cmdloop)
		self.cli_thread.daemon = True
		self.cli_thread.start()
		
		self.quitter_thread = Thread(target=self.worker)
		self.quitter_thread.daemon = True
		self.quitter_thread.start()

	def worker(self):
		flag = 0
		while True:
			if flag == 0 and self.stats['conns'] > 0:
				print("flag = 0 ; conns > 0")
				flag = 1
			if flag == 1 and self.stats['conns'] == 0:
				self.server.shutdown()

			time.sleep(float(self.stats['config']['Server']['ObserverQuitTime']))
	# def repl(self):
	# 	while True:
	# 		print(">>> ", end="")
	# 		self.raw_input = input()
	# 		self.input = self.raw_input.split()
	# 		if self.input[0] == "exit":
	# 			
	# 			break
	# 		elif self.input[0] == "show":
	# 			# Show time
	# 			print("neighbours_ids")
	# 			print(self.neighbours_ids)
	# 		else:
	# 			print("Something went wrong with your input.")