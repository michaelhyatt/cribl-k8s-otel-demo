# autostart.sh 

the script will start everything including port forwarding. 
and stop everything when you hit any key
Note : it takes about 5-10 min for evrything to spin up

## prerequisites

This autostart suppose you have run the full setup once, to get the correct env variables, and the correct URL in ngork, etc...
if you want to set your env setup for good you could add them to your .profile.
Example 
```
nano ~/.zprofile
```
add those lines to the file
CRIBL_STREAM_VERSION=4.13.3
CRIBL_STREAM_WORKER_GROUP=otel-demo-k8s-wg
CRIBL_STREAM_TOKEN=xx
CRIBL_STREAM_LEADER_URL=xxx.cribl.cloud
CRIBL_EDGE_VERSION=4.13.3
CRIBL_EDGE_FLEET=otel-demo-k8s-fleet
CRIBL_EDGE_LEADER_URL=xxx.cribl.cloud
CRIBL_EDGE_TOKEN=xxx
NGROK_AUTHTOKEN=xxx
NGROK_API_KEY=xxx

save & exit (Ctrl+X), Y

reload the profile
```
source ~.zprofile
env
```
verify the variables appear in the env.


## on first use
  You need to change permissions : chmod +x autostart.sh 

## Start everything
Run
```
./autostart.sh
```
## Verify things are spinning up 
in ngrok.com consoole : you will see endpoint : 1 online
in k9s you will see namespaces, services etc coming alive
if you encounter an error : look for the log in Cribl search (k8s logs) or in your terminal with k9s (keep on pressing enter on red lines, it will bring you to the logs)

## shutting down 

After your demo, When you press any key, it will turn off the entire cluster. 
Note : 
if this doesn't work, use stop.sh

```
chmod +x stop.sh
./stop.sh
```