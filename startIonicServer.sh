#!/usr/bin/env bash
################################################################################
# Usage:                                                                       #
#     startIonicServer.sh [android,ios] {api host} {ngrok port}                #
# Examples:                                                                    #
#     startIonicServer.sh android api.develop 80                               #
#     The previous command is the same as                                      #
#     startIonicServer.sh                                                      #
#                                                                              #
# If needed ngrok will output logs to ./ngrok.log                              #
################################################################################
PREVIOUS_NGROK_PROCESS=$(ps -ef | grep 'ngrok' | grep -v 'grep' | awk '{print $2}')
PREVIOUS_EMULATOR_PROCESS=$(ps -ef | grep 'Android' | grep -v 'grep' | awk '{print $2}')
if [ -z "$PREVIOUS_EMULATOR_PROCESS" ]
  then
    echo 'not found'
      PREVIOUS_EMULATOR_PROCESS=$(ps -ef | grep 'xcode' | grep -v 'grep' | awk '{print $2}')
fi

killngrok()
{
  if [ -z "$PREVIOUS_NGROK_PROCESS" ]
  then
        echo "Ngrok was not running, good to go"
  else
        echo "Stopping previous background Ngrok process $PREVIOUS_NGROK_PROCESS"
        kill -9 $PREVIOUS_NGROK_PROCESS
        sleep 2
        echo "Ngrok stopped"
  fi
}

truncate -s0 ngrok.log
# Set local port from command line arg or default to 8080
DEVICE_OS=${1-'android'}
LOCAL_HOST=${2-'localhost'}
LOCAL_PORT=${3-80}

if [ -z "$PREVIOUS_NGROK_PROCESS" ]
  then
      echo "Start Ngrok in background for [$LOCAL_HOST] on port [ $LOCAL_PORT ]"
      nohup ngrok http --host-header=${LOCAL_HOST} --log=ngrok.log ${LOCAL_PORT} &>/dev/null &
      sleep 3
  else
      echo "Ngrok was already running and will be reused"
fi

echo -n "Extracting Ngrok public url ."
NGROK_PUBLIC_URL=""
while [ -z "$NGROK_PUBLIC_URL" ]; do
  # Run 'curl' against ngrok API and extract public (using 'sed' command)
  NGROK_PUBLIC_URL=$(curl --silent --max-time 1000 --connect-timeout 1000 \
                            --show-error http://127.0.0.1:4040/api/tunnels | \
                            sed -nE 's/.*public_url":"([^"]*).*/\1/p')
  sleep 1
  echo -n "."
done
export NGROK_PUBLIC_URL

echo "NGROK_PUBLIC_URL => [ $NGROK_PUBLIC_URL ]"

if [ -z "$PREVIOUS_EMULATOR_PROCESS" ]
  then
      echo "Starting Ionic Server"
      ionic capacitor run ${DEVICE_OS} -l --external --open --consolelogs
      sleep 3
  else
      echo "Emulator was already running and will be reused"
      ionic capacitor run ${DEVICE_OS} -l --external --consolelogs
fi



