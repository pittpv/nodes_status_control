# Nodes Status Control
The script monitors the status of node containers in Docker and, if necessary, restarts them. Additionally notifying by telegram message. 

Checking the processor and memory load of the container and notifying you when the specified limits are exceeded.

- main script
- configuration file

# Prerequisits

- docker
- screen
- curl
- bc
- jq
- telegram bot token, telegram chat id

# Can control
- Shardeum node with CLI status monitoring and restart
- Any other nodes (containers) running in Docker 
