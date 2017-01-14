#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")

[[ "$1" == "--install" ]] && {
   JAVA_ORIG=$(which java)
   echo "JAVA_ORIG=$JAVA_ORIG" >> /etc/environment   
   echo "PATH=$SCRIPT_PATH:\$PATH" >> /etc/environment
 
   mv $SCRIPT "$SCRIPT_PATH/java"
   chmod $( stat -f '%p' ${JAVA_ORIG} ) "$SCRIPT_PATH/java"
}

source "$SCRIPT_PATH/memoryConfig.sh";

$JAVA_ORIG "$@"
