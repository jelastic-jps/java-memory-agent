#!/bin/bash        

#defaults
XMX_DEF=${XMX_DEF:-AUTO}
#if auto then set XMX = 80% * total available RAM
XMX_DEF_PERCENT=${XMX_DEF_PERCENT:-80}
XMS_DEF=${XMS_DEF:-32M}
XMN_DEF=${XMN_DEF:-30M}
XMINF_DEF=${XMINF_DEF:-0.1}
XMAXF_DEF=${XMAXF_DEF:-0.3}
GC_DEF=${GC_DEF:-G1GC}
G1_J7_MIN_RAM_THRESHOLD=8000
FULL_GC_PERIOD=${FULL_GC_PERIOD:-300}
FULL_GC_AGENT_DEBUG=${FULL_GC_AGENT_DEBUG:-0}
	
function normalize {
  var="$(echo ${1} | tr '[A-Z]' '[a-z]')"
  prefix="$(echo ${2} | tr '[A-Z]' '[a-z]')"
  [[ "${var}" == "${prefix}"* ]] && { echo ${1}; } || { [[ "${var}" == "${prefix:1:100}"* ]] && echo "-"${1} || echo ${2}${1}; } 
}

ARGS=("$@")

if ! echo ${ARGS[@]} | grep -q "\-Xms[0-9]\+."
then
        [ -z "$XMS" ] && { XMS="-Xms$XMS_DEF"; }
        ARGS=("$(normalize $XMS -Xms)" "${ARGS[@]}"); 
fi

if ! echo ${ARGS[@]} | grep -q "\-Xmn[0-9]\+."
then
        [ -z "$XMN" ] && { XMN="-Xmn$XMN_DEF"; }
        ARGS=("$(normalize $XMN -Xmn)" "${ARGS[@]}"); 
fi

if ! echo ${ARGS[@]} | grep -q "\-Xmx[0-9]\+."
then
        [ -z "$XMX" ] && {
		[ "$XMX_DEF" == "AUTO" ] && {		
        		memory_total=`free -m | grep Mem | awk '{print $2}'`
			
			#checking cgroup memory limit in container https://goo.gl/gnF8m9
			CGROUP_MEMORY_LIMIT="/sys/fs/cgroup/memory/memory.limit_in_bytes"
			if [ -f $CGROUP_MEMORY_LIMIT ]; then
			   cgroup_limit=$((`cat $CGROUP_MEMORY_LIMIT`/1024/1024))
			   #choosing the smaller value
			   memory_total=$(( memory_total < cgroup_limit ? memory_total : cgroup_limit ))
			fi   
			
        		let XMX=memory_total*XMX_DEF_PERCENT/100
        		XMX="-Xmx${XMX}M"
		} || {
			XMX="-Xmx${XMX_DEF}"
		}
        }
        ARGS=("$(normalize $XMX -Xmx)" "${ARGS[@]}"); 
else 
	XMX=`echo ${ARGS[@]} | grep -o "\-Xmx[0-9]\+."`
fi

XMX_VALUE=`echo $XMX | grep -o "[0-9]*"`
XMX_UNIT=`echo $XMX | sed "s/-Xmx//g" | grep -io "g\|m"`
if [[ $XMX_UNIT == "g" ]] || [[ $XMX_UNIT == "G" ]] ; then 
	let XMX_VALUE=$XMX_VALUE*1024; 
fi

if ! echo ${ARGS[@]} | grep -q "\-Xminf[[:digit:]\.]"
then
        [ -z "$XMINF" ] && { XMINF="-Xminf$XMINF_DEF"; }
        ARGS=("$(normalize $XMINF -Xminf)" "${ARGS[@]}"); 
fi

if ! echo ${ARGS[@]} | grep -q "\-Xmaxf[[:digit:]\.]"
then
        [ -z "$XMAXF" ] && { XMAXF="-Xmaxf$XMAXF_DEF"; }
        ARGS=("$(normalize $XMAXF -Xmaxf)" "${ARGS[@]}"); 
fi

JAVA_VERSION=$(${JAVA_ORIG:-java} -version 2>&1 | grep version)
JAVA_VERSION=${JAVA_VERSION//\"/}
[ $(echo $JAVA_VERSION | awk '{ print $3 }'  | awk -F '[._-]' '{print $1}') -ge 9 ] && {
    JAVA_VERSION=$(echo $JAVA_VERSION | awk '{print $3}')
    JAVA_MAJOR_VERSION=$(echo $JAVA_VERSION |  awk -F '[._-]' '{print $1}');
    JAVA_MINOR_VERSION=$(echo $JAVA_VERSION |  awk -F '[._-]' '{print $2}');
    JAVA_UPDATE_VERSION=$(echo $JAVA_VERSION |  awk -F '[._-]' '{print $3}');
}||{
    JAVA_MAJOR_VERSION=$(echo $JAVA_VERSION |  awk -F '[._-]' '{print $2}');
    JAVA_MINOR_VERSION=$(echo $JAVA_VERSION |  awk -F '[._-]' '{print $3}');
    JAVA_UPDATE_VERSION=$(echo $JAVA_VERSION |  awk -F '[._-]' '{print $4}');
}
 
#checking the need of MaxPermSize param 
if ! echo ${ARGS[@]} | grep -q "\-XX:MaxPermSize"
then
        [ -z "$MAXPERMSIZE" ] && { 
        	#if java version <= 7 then configure MaxPermSize otherwise ignore 
        	[ $JAVA_MAJOR_VERSION -le 7 ] && {
			let MAXPERMSIZE_VALUE=$XMX_VALUE/10; 
        		[ $MAXPERMSIZE_VALUE -ge 64 ] && {
				[ $MAXPERMSIZE_VALUE -gt 256 ] && { MAXPERMSIZE_VALUE=256; }
				MAXPERMSIZE="-XX:MaxPermSize=${MAXPERMSIZE_VALUE}M";
                	}
		}
  	}
        ARGS=($MAXPERMSIZE "${ARGS[@]}"); 
fi
 
if ! echo ${ARGS[@]} | grep -q "\-XX:+Use.*GC"
then	
	[ -z "$GC" ] && {  
        	[ $JAVA_MAJOR_VERSION -le 7 ] && {
	    		[ "$XMX_VALUE" -ge "$G1_J7_MIN_RAM_THRESHOLD" ] && GC="-XX:+UseG1GC" || GC="-XX:+UseParNewGC";
	    	} || {
	    		GC="-XX:+Use$GC_DEF";
	    	}
     	}
        ARGS=("$GC" "${ARGS[@]}"); 
        
fi 
   
#if ! `echo $ARGS | grep -q "UseCompressedOops"`
#then
	#CompressedOops - compression of pointers in the Java Heap 
	#UseCompressedClassPointers - compression of pointers in JVM Metadata  
	#there is a dependency between the two options: UseCompressedOops must be on for UseCompressedClassPointers to be on
#	if ! `echo $ARGS | grep -q "UseCompressedClassPointers"`
#	then
#		ARGS="-XX:+UseCompressedClassPointers $ARGS"
#	fi
#    	ARGS="-XX:+UseCompressedOops $ARGS"
#fi

#enabling string deduplication feature https://blogs.oracle.com/java-platform-group/entry/g1_from_garbage_collector_to
if ! echo ${ARGS[@]} | grep -q "UseStringDeduplication"
then
	if  `echo $ARGS | grep -q "\-XX:+UseG1GC"`
	then
		#this feature works for java >= 1.8.0_20
		if [ $JAVA_MAJOR_VERSION -gt 8 ] || ([ $JAVA_MAJOR_VERSION -eq 8 ] && ([ $JAVA_MINOR_VERSION -gt 0 ] || [ $JAVA_UPDATE_VERSION -ge 20 ]))
		then	
    			ARGS=("-XX:+UseStringDeduplication" "${ARGS[@]}"); 
		fi 
	fi 
fi

if ! echo ${ARGS[@]} | grep -q "\-javaagent\:[^ ]*jelastic\-gc\-agent\.jar"
then	
	[ "$VERT_SCALING" != "false" -a "$VERT_SCALING" != "0" ] && {
		[ -z "$AGENT_DIR" ] && AGENT_DIR=$(dirname $(readlink -f "$0"))
		AGENT="$AGENT_DIR/jelastic-gc-agent.jar"
		[ ! -f $AGENT ] && AGENT="$AGENT_DIR/lib/jelastic-gc-agent.jar"
		ARGS=("-javaagent:$AGENT=period=$FULL_GC_PERIOD,debug=$FULL_GC_AGENT_DEBUG" "${ARGS[@]}"); 
	}
fi

if ! echo ${ARGS[@]} | grep -q "\-server"
then
    	ARGS=("-server" "${ARGS[@]}"); 
fi

set -- "${ARGS[@]}"
