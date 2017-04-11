class Backplane:
	def __init__(self):
		self.neighbours_ids = dict()
		self.neighbours_lastmsg_time = dict()

	def add_neighbour(self, msg_id, msg_addr):
		if msg_id in self.neighbours_ids:
			return False, "Error: neighbours already there."
		else:
			self.neighbours_ids[msg_id] = msg_addr
			self.neighbours_lastmsg_time[msg_id] = int(time.strftime("%s"))
			## Add an entry to the VC
		return True

	def  del_neighbour(self, msg_id):
		if msg_id not in self.neighbours_ids:
			return False, "Error: neighbour already left."
		else:
			del self.neighbours_ids[msg_id]
			del self.neighbours_lastmsg_time[msg_id]
			## the entry to the VC cannot be removed
		return True

	def get_address(self, msg_id):
		if msg_id not in self.neighbours_ids:
			return False, "Error: neighbour here with that name."
		else:
			return True, self.neighbours_ids[msg_id]
			
			