#!/bin/bash

#PATH=download/robox/build/src:$PATH
export XDG_RUNTIME_DIR=/run/user/`id -u`
#export DBUS_SESSION_BUS_ADDRESS=/run/user/$(id -u)/bus
ANBOX="anbox"
SESSIONMANAGER="$ANBOX session-manager"
LAUNCHER="$ANBOX launch"
BINDMOUNTDIR=$HOME/anbox-data
SOCKETDIR=$XDG_RUNTIME_DIR/anbox
ROBOXLOGDIR=/tmp/robox
ROBOXALLLOG="" # Populated dynamically
SOCKETS="anbox_bridge qemu_pipe anbox_audio"
INPUTS="event0  event1"
ANBOX_LOG_LEVEL="debug"
EGL_LOG_LEVEL="debug"
DOCKERNAME=""
SESSIONMANAGERPID=""
FRAMEBUFFERPID=""
START=""
STOP=""
VNC="true"
instance=0
instance=""
EXECUTIONS=0
FAILED=255
SUPPORTEDINSTANCES=253 # Restricted by Class C networking (!1 && !255)
                       # Remember Robox IP addresses start at <MASK>.2
DISPLAY=:0

function warning() {
    echo -e "\e[01;31m$instancenum: $@ \e[0m"
}

function out() {
    if [[ "$QUIET" == "true" ]]; then return; fi
    echo -e "\e[01;32m$instancenum: $@ \e[0m"
}

function debug() {
    if [[ "$DEBUG" != "true" ]]; then return; fi
    echo -e "\e[01;33m$instancenum: $@ \e[0m"
}

function check_and_remove_docker()
{
	  echo "check_and_remove_docker  $instance"
    sudo docker ps -a | grep $instance$  > /dev/null 2>&1
    if [[ $? -eq 0 ]]; then
    	#sudo docker stop $instance 
    	sudo docker rm -f $instance
    fi
	#out "`sudo docker ps -a | grep $instance`"
}

function start_framebuffer()
{
    out "$instancenum: STARTING Frame Buffer"
    cmd="sudo Xorg -config /etc/X11/xorg0.conf $display -sharevts"

    # LEE: Might need a sleep here
    ps aux | grep Xorg | grep "Xorg[[:space:]]*$display " > /dev/null
    if [ $? -gt 0 ]; then
        warning "\e[01;31m  Create Xorg service\e[0m"
        debug $cmd
        eval $cmd &
        sleep 3
    else
        out "The Xorg service has been created \e[0m"
    fi
}

function start_session_manager()
{
    
    windowing=""
    warning "BINDMOUNTDIR:$BINDMOUNTDIR, XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR"
    if [ -d $XDG_RUNTIME_DIR/anbox/$instancenum ]; then
    	sudo rm -rfv $XDG_RUNTIME_DIR/anbox/$instancenum 
	    sudo rm -rfv $BINDMOUNTDIR/$instancenum 
    fi

    PID=$(ps aux | grep session-manager | grep "run-multiple=$instancenum" | column -t | cut -d$' ' -f3)
    if [[ "$PID" != "" ]]; then
		  out "exsist , STOPPING Session Manager ($PID)"
      		  kill -9 $PID
    else
		  out "NOT stopping Session Manager, it's not running"
    fi
    
    ## can't run as root
    cpurange=$((4*instancenum))-$((4*instancenum+3))
    #taskset -c $cpurange anbox session-manager --run-multiple=1 --standalone --experimental windowing="" --window-size=720,1280
    cmd="taskset -c $cpurange $SESSIONMANAGER --run-multiple=$instancenum --standalone --single-window --experimental $windowing --window-size=720,1280"

    echo $cmd
    export DISPLAY=$DISPLAY
    export EGL_PLATFORM=x11
    export EGL_LOG_LEVEL="fatal"
    export SDL_VIDEODRIVER=x11

    #eval $cmd
    eval $cmd & >/dev/null
    if [ $? -ne 0 ]; then
        warning "session manager failed"
        exit
    fi
    SESSIONMANAGERPID=$(ps aux | grep session-manager | grep "run-multiple=$instancenum" | column -t | cut -d$' ' -f3)
   
    TIMEOUT=0
    while true; do
	    ps -h $SESSIONMANAGERPID > /dev/null
	    if [[ $? -gt 0 ]]; then
			if [[ $TIMEOUT -gt 2 ]]; then
				warning "FAILED to start the Session Manager"
				return $FAILED
			else
				TIMEOUT=$(($TIMEOUT+1))
			fi
	      sleep 2
    	else
    	    break
    	fi
    done
}

function configure_networking()
{
    #unique_ip=$instancenum
    unique_ip=`ps -ef | grep proxy | grep 172.17.0 | awk '{print $16}' | awk -F "." '{print $4}' | sort -nur | sed -n '1p'`
    if [[ ! $unique_ip ]]; then
        unique_ip=1
    fi
    unique_ip=$(($unique_ip + 1))
    final_ip=172.17.0.$unique_ip

    out "CREATING network configuration (using $final_ip)"

    mkdir -p $BINDMOUNTDIR/$instancenum/data/misc/ethernet
	  echo "mkdir -p $BINDMOUNTDIR/$instancenum/data/misc/ethernet"

    $ANBOX generate-ip-config --ip=$final_ip --gateway=172.17.0.1
    if [[ $? -ne 0 ]]; then
        warning "FAILED to configure Networking"
        return $FAILED
    fi

    cp ipconfig.txt $BINDMOUNTDIR/$instancenum/data/misc/ethernet
}

function start()
{
    ps aux | grep -v grep | grep "$instance \|$instance$" > /dev/null
    if [[ $? -eq 0 ]]; then
      OUT=`ps aux | grep -v grep | grep "$instance \|$instance$"`
      out $OUT
      warning "$instance is already running -- please stop it before continuing"
      return $FAILED
    fi

    sudo docker network inspect bridge | grep \"$instance\" > /dev/null
    if [[ $? -eq 0 ]]; then
		    sudo docker network disconnect -f bridge $instance
    fi

    # Export current log level values
    export ANBOX_LOG_LEVEL=$ANBOX_LOG_LEVEL
    export EGL_LOG_LEVEL=$EGL_LOG_LEVEL
    start_framebuffer
    # Raise system resource limits - required for many containers
    sudo sysctl -w fs.inotify.max_user_instances=8192 > /dev/null
    sudo sysctl -w fs.file-max=1000000 > /dev/null
    sudo sysctl -w kernel.shmmni=24576 > /dev/null
    sudo sysctl -w kernel.pid_max=200000 > /dev/null

    ulimit -n 4096
    ulimit -s unlimited
    ulimit -c unlimited

    start_session_manager

<<EOF
    configure_networking
    if [[ $? -eq $FAILED ]]; then
	  	return $FAILED
    fi
    sudo chmod -R 777 $XDG_RUNTIME_DIR/anbox
    yypts=$((5557 + 2 * $instancenum))
    while [ true ]; do
      #curl 192.168.10.62:$instancenum
      adb connect 192.168.10.62:$yypts
      sleep 1
    done
EOF
    debug "Ensuring all sockets are useable"
  
}

function stop()
{

	ps aux | grep -v grep | grep "run-multiple=$instancenum" > /dev/null
	if [[ $? -ne 0 ]]; then
		out "Nothing to do"
		# Remove possible remnent files anyway, just in case
		sudo rm -rf $XDG_RUNTIME_DIR/anbox/$instancenum 
		sudo rm -rf $BINDMOUNTDIR/$instancenum 
		exit 0
	fi
 

    # Stop Docker
    sudo docker ps -a | grep $instance$ > /dev/null
    if [[ $? -eq 0 ]]; then
		out "REMOVING Docker"
		sudo docker rm -f $instance
		if [[ $? -ne 0 ]]; then
			warning "FAILED to remove Docker container"
		fi
    else
		out "NOT stopping Docker, it's not running"
    fi

    # Stop Session Manager
    PID=$(ps aux | grep session-manager | grep "run-multiple=$instancenum" | column -t | cut -d$' ' -f3)
    echo $PID
    if [[ "$PID" != "" ]]; then
		out "STOPPING Session Manager ($PID)"
		if [[ "$PERF" == "true" ]]; then
			kill -INT $PID
		else
			kill -9 $PID
		fi
    else
		out "NOT stopping Session Manager, it's not running"
    fi

    out sudo rm -rf $XDG_RUNTIME_DIR/anbox/$instancenum
    out sudo rm -rf $BINDMOUNTDIR/$instancenum


    sudo rm -f /tmp/.X$instancenum-lock

    # Remove unattached shared memory (VNC does not free it properly)
    IDS=`ipcs -m | grep '^0x' | grep $USER | awk '{print $2, $6}' | grep ' 0$' | awk '{print $1}'`
    for id in $IDS; do
	ipcrm shm $id &> /dev/null
    done
}

main ()
{
    mkdir -p $XDG_RUNTIME_DIR
    #mkdir -p $DBUS_SESSION_BUS_ADDRESS
    instancenum=$2
    instance=instance$instancenum
    if [[ "$1" == "start" ]]; then
      out "Attempting to start instance $instance\n"
      start
    elif  [[ "$1" == "kill" ]]; then
      kill 
    elif  [[ "$1" == "stop" ]]; then
      out "Attempting to stop instance $instance\n"
      stop
    fi

    return $?
}

main $@
exit $?
