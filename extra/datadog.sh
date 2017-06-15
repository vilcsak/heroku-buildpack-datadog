#!/usr/bin/env bash

# Update Env Vars with new paths for apt packages
export PATH="$HOME/.apt/usr/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.apt/usr/lib/x86_64-linux-gnu:$HOME/.apt/usr/lib/i386-linux-gnu:$HOME/.apt/usr/lib:$LD_LIBRARY_PATH"
export LIBRARY_PATH="$HOME/.apt/usr/lib/x86_64-linux-gnu:$HOME/.apt/usr/lib/i386-linux-gnu:$HOME/.apt/usr/lib:$LIBRARY_PATH"
export INCLUDE_PATH="$HOME/.apt/usr/include:$HOME/.apt/usr/include/x86_64-linux-gnu:$INCLUDE_PATH"
export CPATH="$INCLUDE_PATH"
export CPPPATH="$INCLUDE_PATH"
export PKG_CONFIG_PATH="$HOME/.apt/usr/lib/x86_64-linux-gnu/pkgconfig:$HOME/.apt/usr/lib/i386-linux-gnu/pkgconfig:$HOME/.apt/usr/lib/pkgconfig:$PKG_CONFIG_PATH"

# Update the Datadog conf file with any env vars named DD_*
for e in $( env ); do
  if [[ $e == DD_* ]]; then 
    # Just grab the varname
    VARNAME=${e%=*}
    VARVALUE=${e#*=}
    CONFSTRING="$( echo ${VARNAME#*_} | tr '[:upper:]' '[:lower:]' )"
    sed -i -e "s!^[# ]*$CONFSTRING:.*!$CONFSTRING: $VARVALUE!" /app/.datadog-agent/agent/datadog.conf
  fi
done

if [ -n $_DD_API_KEY ]; then
  # Run the Datadog Agent
  /app/.datadog-agent/bin/agent &
fi
