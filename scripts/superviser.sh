#!/bin/bash

[[ "$1" == "--install" ]] && {
   JAVA_ORIG=$(which java)
   echo "JAVA_ORIG=$JAVA_ORIG" >> /etc/environment
   
   # Absolute path to this script, e.g. /home/user/bin/foo.sh
   SCRIPT=$(readlink -f "$0")
   # Absolute path this script is in, thus /home/user/bin
   SCRIPT_PATH=$(dirname "$SCRIPT")
   echo "PATH=$SCRIPT_PATH:\$PATH" >> /etc/environment
  
   mv $SCRIPT "$SCRIPT_PATH/java"
   chmod $( stat -f '%p' ${JAVA_ORIG} ) "$SCRIPT_PATH/java"
}

$JAVA_ORIG "$@"
