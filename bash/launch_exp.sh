#!/bin/bash

IP_SERVER="localhost" # Address that the server allows
IP_CLIENT="localhost" # address to access the server from the client
PORT="5005"

CMD_SERVER="python3 server.py $IP_SERVER $PORT"
CMD_CLIENT="python3 repl_client.py $IP_CLIENT $PORT"


xterm -title "Server 1" -e "$CMD_SERVER" &

xterm -title "Client 1" -e "$CMD_CLIENT 1" &
xterm -title "Client 2" -e "$CMD_CLIENT 2" &