#!/bin/bash

#ts=$(date +%s)
files="config.ini Snd.py test_rer.py Observer.py repl_client.py storm.py VectorClock.py Rcv.py server.py TCPServer.py"

tar -zcf rervalCode.tar.gz $files 