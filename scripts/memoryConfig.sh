#!/bin/bash        

# defaults
XMX_DEF="AUTO"
XMS_DEF="32M"
XMN_DEF="30M"
XMINF_DEF="0.1"
XMAXF_DEF="0.3"
GC_DEF="G1GC"
G1_J7_MIN_RAM_THRESHOLD=8000
FULL_GC_PERIOD=${FULL_GC_PERIOD:-300}
FULL_GC_AGENT_DEBUG=${FULL_GC_AGENT_DEBUG:-0}
	
function normalize {
  var="$(echo ${1} | tr '[A-Z]' '[a-z]')"
  prefix="$(echo ${2} | tr '[A-Z]' '[a-z]')"
  [[ "${var}" == "${prefix}"* ]] && { echo ${1}; } || { [[ "${var}" == "${prefix:1:100}"* ]] && echo "-"${1} || echo ${2}${1}; } 
}

if ! `echo $JAVA_OPTS | grep -q "\-Xms[[:digit:]\.]"`
then
        [ -z "$XMS" ] && { XMS="-Xms$XMS_DEF"; }
        JAVA_OPTS=$JAVA_OPTS" $(normalize $XMS -Xms)"; 
fi

if ! `echo $JAVA_OPTS | grep -q "\-Xmn[[:digit:]\.]"`
then
        [ -z "$XMN" ] && { XMN="-Xmn$XMN_DEF"; }
        JAVA_OPTS=$JAVA_OPTS" $(normalize $XMN -Xmn)"; 
fi

if ! `echo $JAVA_OPTS | grep -q "\-Xmx[[:digit:]\.]"`
then
        [ -z "$XMX" ] && {
		[ "$XMX_DEF" == "AUTO" ] && {		
        		#optimal XMX = 80% * total available RAM
        		#it differs a little bit from default values -Xmx http://docs.oracle.com/cd/E13150_01/jrockit_jvm/jrockit/jrdocs/refman/optionX.html
        		memory_total=`free -m | grep Mem | awk '{print $2}'`;
        		let XMX=memory_total*8/10;
        		XMX="-Xmx${XMX}M";
		} || {
			XMX="-Xmx${XMX_DEF}"
		}
        }
        JAVA_OPTS=$JAVA_OPTS" $(normalize $XMX -Xmx)";
fi

XMX_VALUE=`echo $XMX | grep -o "[0-9]*"`;
XMX_UNIT=`echo $XMX | sed "s/-Xmx//g" | grep -io "g\|m"`;
if [[ $XMX_UNIT == "g" ]] || [[ $XMX_UNIT == "G" ]] ; then 
	let XMX_VALUE=$XMX_VALUE*1024; 
fi

if ! `echo $JAVA_OPTS | grep -q "\-Xminf[[:digit:]\.]"`
then
        [ -z "$XMINF" ] && { XMINF="-Xminf$XMINF_DEF"; }
        JAVA_OPTS=$JAVA_OPTS" $(normalize $XMINF -Xminf)"; 
fi

if ! `echo $JAVA_OPTS | grep -q "\-Xmaxf[[:digit:]\.]"`
then
        [ -z "$XMAXF" ] && { XMAXF="-Xmaxf$XMAXF_DEF"; }
        JAVA_OPTS=$JAVA_OPTS" $(normalize $XMAXF -Xmaxf)"; 
fi

# checking the need of MaxPermSize setting 
JAVA_VERSION=$(${JAVA_ORIG:-java} -version 2>&1 | grep version |  awk -F '.' '{print $2}')

if ! `echo $JAVA_OPTS | grep -q "\-XX:MaxPermSize"`
then
        [ -z "$MAXPERMSIZE" ] && { 
        	# if java version <= 7 then configure MaxPermSize otherwise ignore 
        	[ $JAVA_VERSION -le 7 ] && {
			let MAXPERMSIZE_VALUE=$XMX_VALUE/10; 
        		[ $MAXPERMSIZE_VALUE -ge 64 ] && {
				[ $MAXPERMSIZE_VALUE -gt 256 ] && { MAXPERMSIZE_VALUE=256; }
				MAXPERMSIZE="-XX:MaxPermSize=${MAXPERMSIZE_VALUE}M";
                	}
		}
  	}
        JAVA_OPTS=$JAVA_OPTS" $MAXPERMSIZE";
fi
 
if ! `echo $JAVA_OPTS | grep -q "\-XX:+Use.*GC"`
then	
	[ -z "$GC" ] && {  
        	[ $JAVA_VERSION -le 7 ] && {
	    		[ "$XMX_VALUE" -ge "$G1_J7_MIN_RAM_THRESHOLD" ] && GC="-XX:+UseG1GC" || GC="-XX:+UseParNewGC";
	    	} || {
	    		GC="-XX:+Use$GC_DEF";
	    	}
     	}
        JAVA_OPTS=$JAVA_OPTS" $GC"; 
fi 
   
if ! `echo $JAVA_OPTS | grep -q "UseCompressedOops"`
then
    	JAVA_OPTS=$JAVA_OPTS" -XX:+UseCompressedOops"
fi

if ! `echo $JAVA_OPTS | grep -q "jelastic\-gc\-agent\.jar"`
then	
	[ "$VERT_SCALING" != "false" -a "$VERT_SCALING" != "0" ] && {
		SCRIPT_PATH=$(dirname $(readlink -f "$0"))
		AGENT="$SCRIPT_PATH/jelastic-gc-agent.jar"
		[ ! -f $AGENT ] && AGENT="$SCRIPT_PATH/lib/jelastic-gc-agent.jar"
		JAVA_OPTS="$JAVA_OPTS -javaagent:$AGENT=period=$FULL_GC_PERIOD,debug=$FULL_GC_AGENT_DEBUG"
	}
fi

export JAVA_OPTS
