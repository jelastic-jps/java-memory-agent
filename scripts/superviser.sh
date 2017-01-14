#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")

[[ "$1" == "--install" ]] && {
   JAVA_ORIG=$(which java)
   
   sed -i '/JAVA_ORIG=/d' /etc/profile
   echo "JAVA_ORIG=$JAVA_ORIG" >> /etc/profile   

   sed -i "/PATH=$(echo ${SCRIPT_PATH//\//\\/})/d" /etc/profile
   echo "PATH=$SCRIPT_PATH:\$PATH" >> /etc/profile
 
   JAVA_AGENT="$SCRIPT_PATH/java";
   mv $SCRIPT $JAVA_AGENT
   
   chown --reference=$JAVA_ORIG $JAVA_AGENT
   chmod --reference=$JAVA_ORIG $JAVA_AGENT
} || {
   source "$SCRIPT_PATH/memoryConfig.sh"
   $JAVA_ORIG "$@"
}
