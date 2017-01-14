#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")
JAVA_AGENT="$SCRIPT_PATH/java"
MEMORY_CONF="$SCRIPT_PATH/memoryConfig.sh"
  
[[ "$1" == "--install" ]] && {
   JAVA_ORIG=$(which java)
   
   sed -i '/JAVA_ORIG=/d' /etc/profile
   echo "export JAVA_ORIG=$JAVA_ORIG" >> /etc/profile   

   sed -i "/PATH=$(echo ${SCRIPT_PATH//\//\\/})/d" /etc/profile
   echo "export PATH=$SCRIPT_PATH:\$PATH" >> /etc/profile
 
   mv $SCRIPT $JAVA_AGENT
   
   chown --reference=$JAVA_ORIG $JAVA_AGENT
   chmod --reference=$JAVA_ORIG $JAVA_AGENT
} || { 
   [[ "$1" == "--uninstall" ]] && { 
      sed -i '/JAVA_ORIG=/d' /etc/profile
      sed -i "/PATH=$(echo ${SCRIPT_PATH//\//\\/})/d" /etc/profile
      
      rm -f $JAVA_AGENT
      rm -f $MEMORY_CONF
   } || {
      source $MEMORY_CONF
      $JAVA_ORIG "$@"
   }
}
