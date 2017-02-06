#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")
AGENT_DIR="/java_agent"
#JAVA="$AGENT_DIR/java"
MEMORY_CONF="$AGENT_DIR/memoryConfig.sh"
ENVS_FILE="$AGENT_DIR/envs"
  
install () {
   PATH=$1
   [[ $PATH != */bin/java ]] && {  JAVA_BIN=$PATH"/bin/java"; } || {  JAVA_BIN=$PATH; } 
   
   JAVA_ORIG="${JAVA_BIN}.orig"
   
   if [ -f $JAVA_ORIG ]; then
      echo "Installation to $JAVA_BIN has been skipped as $JAVA_ORIG already exists"
   else
      #moving files around 
      mv $JAVA_BIN $JAVA_ORIG 
      cp $SCRIPT $JAVA_BIN  

      /bin/chown --reference=$JAVA_ORIG $JAVA_BIN
      /bin/chmod --reference=$JAVA_ORIG $JAVA_BIN    
   
      echo "Java memory agent has been installed to $JAVA_BIN"
   fi   
      
}

uninstall () {
   PATH=$1
   [[ $PATH != */bin/java ]] && {  JAVA_BIN=$PATH"/bin/java"; } || {  JAVA_BIN=$PATH; } 
   
   JAVA_ORIG="${JAVA_BIN}.orig"
   
   if [ -f $JAVA_ORIG ]; then
      rm -f $JAVA_BIN
      mv $JAVA_ORIG $JAVA_BIN
   
      echo "Java memory agent has been uninstalled at $JAVA_BIN"
   else
      echo "Java memory agent was not found at $JAVA_BIN, uninstallation has been skipped"
   fi      
  
}
  
  
if [[ "$1" == "--install" ]] || [[ "$1" == "--uninstall" ]]; then

   if [ -z "$JAVA_HOME" ]; then     
      #checking default link to java 
      LINK=$(which java)
      JAVA_BIN=$(readlink -f $LINK)
   else 
      JAVA_BIN=$JAVA_HOME 
   fi

   if [[ "$1" == "--install" ]] ; then
      install $JAVA_BIN
   else 
      uninstall $JAVA_BIN
   fi
   
   
   #JAVA_ORIG="${JAVA_BIN}.orig"
     
   #moving files around 
   #mv $JAVA_BIN $JAVA_ORIG 
   #cp $SCRIPT $JAVA_BIN
   
   #/bin/chown --reference=$JAVA_ORIG $JAVA_BIN
   #/bin/chmod --reference=$JAVA_ORIG $JAVA_BIN      
         
   #mkdir -p $AGENT_DIR   
   #echo "export JAVA_ORIG=$JAVA_ORIG" > $ENVS_FILE 
   #echo "export JAVA_BIN=$JAVA_BIN" >> $ENVS_FILE 

   #sed -i "/PATH=$(echo ${AGENT_DIR//\//\\/})/d" /etc/profile
   #echo "export PATH=$AGENT_DIR:\$PATH" >> /etc/profile
 
   #[ $SCRIPT != $JAVA ] && { 
   #   mv $SCRIPT $JAVA
   #   /bin/chown --reference=$JAVA_ORIG $JAVA
   #   /bin/chmod --reference=$JAVA_ORIG $JAVA 
   #}
   
   #echo "Java memory agent has been installed"    
else
      JAVA_ORIG="$SCRIPT.orig"
      source $MEMORY_CONF
      $JAVA_ORIG "$@"
fi
