#!/bin/bash

# Absolute path to this script, e.g. /home/user/bin/foo.sh
SCRIPT=$(readlink -f "$0")
# Absolute path this script is in, thus /home/user/bin
SCRIPT_PATH=$(dirname "$SCRIPT")
AGENT_DIR="/java_agent"
#JAVA="$AGENT_DIR/java"
VARIABLES_CONF="$AGENT_DIR/variablesparser.sh"
MEMORY_CONF="$AGENT_DIR/memoryConfig.sh"
ENVS_FILE="$AGENT_DIR/envs"

install () {
   JAVA_BIN=$1
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
   JAVA_BIN=$1
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
   
   [[ $JAVA_BIN != */bin/java ]] && {  JAVA_BIN=$JAVA_BIN"/bin/java"; } 
   
   FUNC=${1:2}
   $FUNC $JAVA_BIN
 
   for D in `find /usr/{java,lib} -maxdepth 5 -mindepth 3 -type f -name "java"`; 
   do 
      $FUNC $D; 
   done
     
else
      JAVA_ORIG="$SCRIPT.orig"
      [ -f "$VARIABLES_CONF" ] && source $VARIABLES_CONF
      source $MEMORY_CONF
      $JAVA_ORIG "$@"
fi
