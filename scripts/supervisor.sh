#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")
AGENT_DIR="/java_agent"
JAVA="$AGENT_DIR/java"
MEMORY_CONF="$AGENT_DIR/memoryConfig.sh"
ENVS_FILE="$AGENT_DIR/envs"
  
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
      
   mkdir -p $AGENT_DIR   
   echo "export JAVA_ORIG=$JAVA_ORIG" > $ENVS_FILE 
   echo "export JAVA_BIN=$JAVA_BIN" >> $ENVS_FILE 

   sed -i "/PATH=$(echo ${AGENT_DIR//\//\\/})/d" /etc/profile
   echo "export PATH=$AGENT_DIR:\$PATH" >> /etc/profile
 
   [ $SCRIPT != $JAVA ] && { 
      mv $SCRIPT $JAVA
      /bin/chown --reference=$JAVA_ORIG $JAVA
      /bin/chmod --reference=$JAVA_ORIG $JAVA 
   }
   
   echo "Java memory agent has been installed"

elif [[ "$1" == "--uninstall" ]]; then
      sed -i "/PATH=$(echo ${AGENT_DIR//\//\\/})/d" /etc/profile
      
      source $ENVS_FILE
      rm -f $JAVA_BIN
      mv $JAVA_ORIG $JAVA_BIN

      rm -rf $AGENT_DIR       
      
      echo "Java memory agent has been uninstalled"      
else
      source $ENVS_FILE
      source $MEMORY_CONF
      $JAVA_ORIG "$@"
fi
