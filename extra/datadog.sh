#!/usr/bin/env bash

# Update Env Vars with new paths for apt packages
export PATH="$HOME/.apt/usr/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.apt/usr/lib/x86_64-linux-gnu:$HOME/.apt/usr/lib/i386-linux-gnu:$HOME/.apt/usr/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$HOME/.apt/usr/lib/x86_64-linux-gnu:$HOME/.apt/usr/lib/i386-linux-gnu:$HOME/.apt/usr/lib:$LIBRARY_PATH"
export INCLUDE_PATH="$HOME/.apt/usr/include:$HOME/.apt/usr/include/x86_64-linux-gnu:$INCLUDE_PATH"
export CPATH="$INCLUDE_PATH"
export CPPPATH="$INCLUDE_PATH"
export PKG_CONFIG_PATH="$HOME/.apt/usr/lib/x86_64-linux-gnu/pkgconfig:$HOME/.apt/usr/lib/i386-linux-gnu/pkgconfig:$HOME/.apt/usr/lib/pkgconfig:$PKG_CONFIG_PATH"

DDCONF="/app/.datadog-agent/agent/datadog.conf"

# Set the Dyno tags
DYNOHOST="$( hostname )"
sed -i "s/^[# ]*tags:.*$/tags: dyno:$DYNO, dynohost:$DYNOHOST/" $DDCONF

# Update the Datadog conf file with any env vars named DD_*
IFS=$'\n'
for e in $( env ); do
  if [[ $e == DD_* ]]; then 
    # Just grab the varname
    VARNAME=${e%%=*}
    VARVALUE=${e#*=}
    CONFSTRING="$( echo ${VARNAME#*_} | tr '[:upper:]' '[:lower:]' )"

    # Append any tags, otherwise overwrite values
    if [ "$VARNAME" == "DD_TAGS" ]; then
      sed -i -e "s!^\(tags:.*\)!\1, $VARVALUE!" $DDCONF
    else
      sed -i -e "s!^[# ]*$CONFSTRING:.*!$CONFSTRING: $VARVALUE!" $DDCONF
    fi
  fi
done

if [ -z "$DD_API_KEY" ]; then
  echo "DD_API_KEY environment variable not set. Run: heroku config:add DD_API_KEY=<your API key>"
  DISABLE_DATADOG_AGENT=1
fi

if [ -z "$DD_HOSTNAME" ]; then
  echo 'DD_HOSTNAME environment variable not set. Run: heroku config:set DD_HOSTNAME=$(heroku apps:info|grep ===|cut -d' ' -f2)'
  DISABLE_DATADOG_AGENT=1
fi

if [ -n "$DISABLE_DATADOG_AGENT" ]; then
  echo "The Datadog Agent has been disabled. Unset the DISABLE_DATADOG_AGENT or set missing environment variables."
else
  # Run the Datadog Agent
  echo "Starting Datadog Agent on dyno $DYNO"
  /app/.datadog-agent/bin/agent &
fi
