#!/bin/bash

if [ ! -e /forge/.init_done ]; then
  /init.sh $@
fi
#Forge changed the name of their jars. Removed Universal accordingly.
exec java $@ -jar /forge/forge-*.jar nogui
