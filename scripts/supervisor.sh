#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")
JAVA="$SCRIPT_PATH/java"
MEMORY_CONF="$SCRIPT_PATH/memoryConfig.sh"
  
if [[ "$1" == "--install" ]]; then
   
   #checking link to java 
   LINK=$(which java)
   JAVA_BIN=$(readlink -f $LINK)
   JAVA_ORIG="${JAVA_BIN}.orig"
     
   #moving files around 
   mv $JAVA_BIN $JAVA_ORIG 
   cp $SCRIPT $JAVA_BIN
   
   #chmod +x $JAVA_BIN
   /bin/chown --reference=$JAVA_ORIG $JAVA_BIN
   /bin/chmod --reference=$JAVA_ORIG $JAVA_BIN      
    
   #[ $LINK != $JAVA_BIN ] && ln -s $JAVA_BIN $LINK
      
   sed -i '/JAVA_ORIG=/d' /etc/profile
   echo "export JAVA_ORIG=$JAVA_ORIG" >> /etc/profile   

   sed -i "/PATH=$(echo ${SCRIPT_PATH//\//\\/})/d" /etc/profile
   echo "export PATH=$SCRIPT_PATH:\$PATH" >> /etc/profile
 
   [ $SCRIPT != $JAVA ] && { 
      mv $SCRIPT $JAVA
      /bin/chown --reference=$JAVA_ORIG $JAVA
      /bin/chmod --reference=$JAVA_ORIG $JAVA 
   }

elif [[ "$1" == "--uninstall" ]]; then
      sed -i '/JAVA_ORIG=/d' /etc/profile
      sed -i "/PATH=$(echo ${SCRIPT_PATH//\//\\/})/d" /etc/profile
      
      rm -f $JAVA_BIN
      mv $JAVA_ORIG $JAVA_BIN
      rm -f $JAVA
      rm -f $MEMORY_CONF
else
      source $MEMORY_CONF
      $JAVA_ORIG "$@"
fi
