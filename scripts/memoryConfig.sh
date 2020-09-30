#!/bin/bash

#defaults
XMX_DEF=${XMX_DEF:-AUTO}
#if auto then set XMX = 80% * total available RAM
XMX_DEF_PERCENT=${XMX_DEF_PERCENT:-80}
XMS_DEF=${XMS_DEF:-32M}
XMINF_DEF=${XMINF_DEF:-0.1}
XMAXF_DEF=${XMAXF_DEF:-0.3}
GC_DEF=${GC_DEF:-G1GC}
G1_J7_MIN_RAM_THRESHOLD=8000
FULL_GC_PERIOD=${FULL_GC_PERIOD:-300}
FULL_GC_AGENT_DEBUG=${FULL_GC_AGENT_DEBUG:-0}
CPU_COUNT=$(grep -i "physical id" /proc/cpuinfo -c 2>/dev/null)
CPU_COUNT=${CPU_COUNT:-1}
GC_SYS_LOAD_THRESHOLD_RATE=${GC_SYS_LOAD_THRESHOLD_RATE:-0.3}
G1PERIODIC_LT_DEF=$(echo $CPU_COUNT $GC_SYS_LOAD_THRESHOLD_RATE | awk '{print $1*$2}')
G1PERIODIC_LT_DEF=${G1PERIODIC_LT_DEF:-0.3}
G1PERIODIC_GC_INTERVAL=${G1PERIODIC_GC_INTERVAL:-900k}
G1PERIODIC_GC_SYS_LOAD_THRESHOLD=${G1PERIODIC_GC_SYS_LOAD_THRESHOLD:-${G1PERIODIC_LT_DEF}}
OPEN_J9_OPTIONS=(-XX:+IdleTuningCompactOnIdle -XX:+IdleTuningGcOnIdle -XX:IdleTuningMinIdleWaitTime=180 -Xjit:waitTimeToEnterDeepIdleMode=50000)
grep -qiE 'OpenJ9' <<< "$JAVA_VERSION" && OPEN_J9=true || OPEN_J9=false

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



#checking the need of MaxPermSize param 
if ! echo ${ARGS[@]} | grep -q "\-XX:MaxPermSize"
then
        [[ -z "$MAXPERMSIZE" ]] && { 
        	#if java version <= 7 then configure MaxPermSize otherwise ignore 
        	[[ ${JAVA_VERSION%%[.|u|+]*} -le 7 ]] && {
			let MAXPERMSIZE_VALUE=$XMX_VALUE/10; 
        		[[ $MAXPERMSIZE_VALUE -ge 64 ]] && {
				[[ $MAXPERMSIZE_VALUE -gt 256 ]] && { MAXPERMSIZE_VALUE=256; }
				MAXPERMSIZE="-XX:MaxPermSize=${MAXPERMSIZE_VALUE}M";
                	}
		}
  	}
        ARGS=($MAXPERMSIZE "${ARGS[@]}"); 
fi

if ! echo ${ARGS[@]} | grep -q "\-XX:+Use.*GC"
then	
	[[ -z "$GC" ]] && {
        	[[ ${JAVA_VERSION%%[.|u|+]*} -le 7 ]] && {
	    		[[ "$XMX_VALUE" -ge "$G1_J7_MIN_RAM_THRESHOLD" ]] && GC="-XX:+UseG1GC" || GC="-XX:+UseParNewGC";
	    	} || {
	    		GC="-XX:+Use$GC_DEF";
	    	}
     	}
        ARGS=("$GC" "${ARGS[@]}"); 
        
fi 
   
#enabling string deduplication feature https://blogs.oracle.com/java-platform-group/entry/g1_from_garbage_collector_to
if ! echo ${ARGS[@]} | grep -q "UseStringDeduplication"
then
	if  `echo $ARGS | grep -q "\-XX:+UseG1GC"`
	then
    			ARGS=("-XX:+UseStringDeduplication" "${ARGS[@]}"); 
	fi 
fi

[ "$VERT_SCALING" != "false" -a "$VERT_SCALING" != "0" ] && {
    if [[ ${JAVA_VERSION%%[.|u|+]*} -ge 12 ]]; then
	if ! echo ${ARGS[@]} | grep -q "G1PeriodicGCInterval"; then
		ARGS=("-XX:G1PeriodicGCInterval=${G1PERIODIC_GC_INTERVAL}" "${ARGS[@]}");
	fi
	if ! echo ${ARGS[@]} | grep -q "G1PeriodicGCSystemLoadThreshold"; then
		ARGS=("-XX:G1PeriodicGCSystemLoadThreshold=${G1PERIODIC_GC_SYS_LOAD_THRESHOLD}" "${ARGS[@]}");
	fi
    else
	if [ "x$OPEN_J9" == "xtrue" ]; then
	    for i in ${OPEN_J9_OPTIONS[@]}; do
		echo ${ARGS[@]} | grep -q '\'${i%=*} || ARGS=($i "${ARGS[@]}");
	    done
	else
	    if ! echo ${ARGS[@]} | grep -q "\-javaagent\:[^ ]*jelastic\-gc\-agent\.jar"
	    then
		[ -z "$AGENT_DIR" ] && AGENT_DIR=$(dirname $(readlink -f "$0"))
		AGENT="$AGENT_DIR/jelastic-gc-agent.jar"
		[ ! -f $AGENT ] && AGENT="$AGENT_DIR/lib/jelastic-gc-agent.jar"
		ARGS=("-javaagent:$AGENT=period=$FULL_GC_PERIOD,debug=$FULL_GC_AGENT_DEBUG" "${ARGS[@]}"); 
	    fi
	fi
    fi
}

[ "x${UNLOCK_EXPERIMENTAL,,}" != "xfalse" -a "x$UNLOCK_EXPERIMENTAL" != "x0" ] && {
    if ! echo ${ARGS[@]} | grep -q "\-XX:+UnlockExperimentalVMOptions"
    then
        ARGS=("-XX:+UnlockExperimentalVMOptions" "${ARGS[@]}"); 
    fi
}

if ! echo ${ARGS[@]} | grep -q "\-server"
then
    	ARGS=("-server" "${ARGS[@]}"); 
fi

set -- "${ARGS[@]}"
