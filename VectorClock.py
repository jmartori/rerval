class VectorClock:
	def __init__ (self, key, static=True, max_entries=16):
		if static:
			self.vc = list()
			self.key = key
			self.max_entries = max_entries
			for i in range(0,max_entries-1):
				self.vc.append(0)
		else:
			raise Exception('NotImplementedError')

	def __str__ (self):
		return(str(self.vc))
	# def inc(self):
	# 	self.vc[self.key] += 1

	def inc(self, key):
		self.vc[key] += 1

	def happened_before(self,o, method="causal"):
		if method == 'causal':
			return self.happened_before_causal(o)
		elif method == 'fifo':
			return self.happened_before_fifo(o)
		elif method == 'none':
			return self.happened_before_none(o)
		else:
			raise Exception('NotImplementedError')			

	def happened_before_causal(self, o):
		hb = True
		for entry in range(0,self.max_entries-1):
			if o.vc[entry] > self.vc[entry]:
				# If only one message is missing we have to wait!
				hb = False
				break
		return hb

	def happened_before_fifo(self, o):	
		return o.vc[o.vc.key] > self.vc[o.vc.key]
		
	def happened_before_none(self, o):
		return True