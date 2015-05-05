#! /bin/sh
### BEGIN INIT INFO
# Provides:          addok
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: start addok gunicorn server
# Description:       addok gunicorn server daemon
### END INIT INFO

# Author: Yohan Boniface <yohan.boniface@data.gouv.fr>

# Do NOT "set -e"

PATH=/sbin:/usr/sbin:/bin:/usr/bin
DESC="Addok server"
NAME="addok"
PIDFILE=/var/run/$NAME.pid
SCRIPTNAME=/etc/init.d/$NAME

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# VIRTUALENV_ROOT should be set either via default or env var.
[ -x "$VIRTUALENV_ROOT" ] || exit 0

. "$VIRTUALENV_ROOT/bin/activate"
DAEMON="$VIRTUALENV_ROOT/bin/gunicorn"

# Export ADDOK_CONFIG_MODULE if defined in default/addok, and for workarounding
# issues when forwarding env vars to sudo.
[ -z "$ADDOK_CONFIG_MODULE" ] && export ADDOK_CONFIG_MODULE=ADDOK_CONFIG_MODULE
[ -n "$LC_ALL" ] && export LC_ALL=$LC_ALL
[ -n "$LANG" ] && export LANG=$LANG
[ -n "$LANGUAGE" ] && export LANGUAGE=$LANGUAGE

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

RUN_WITH_USER=''
[ -n "$USER" ] && RUN_WITH_USER="-u $USER"

DAEMON_ARGS="addok.server:app -b $HOST:$PORT -w 4 -p $PIDFILE -D --name $NAME --error-logfile $ADDOK_LOG_DIR/server-error.log --log-file=$ADDOK_LOG_DIR/server.log $RUN_WITH_USER"

#
# Function that starts the daemon/service
#
do_start()
{
    # Return
    #   0 if daemon has been started
    #   1 if daemon was already running
    #   2 if daemon could not be started
    ADDOK_CONFIG_MODULE=$ADDOK_CONFIG_MODULE start-stop-daemon --start --quiet --pidfile $PIDFILE --exec $DAEMON --test > /dev/null || return 1
    ADDOK_CONFIG_MODULE=$ADDOK_CONFIG_MODULE start-stop-daemon --start --pidfile $PIDFILE --exec $DAEMON -- $DAEMON_ARGS || return 2
}

#
# Function that stops the daemon/service
#
do_stop()
{
    # Return
    #   0 if daemon has been stopped
    #   1 if daemon was already stopped
    #   2 if daemon could not be stopped
    #   other if a failure occurred
    ADDOK_CONFIG_MODULE=$ADDOK_CONFIG_MODULE start-stop-daemon --quiet --stop --pidfile $PIDFILE
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2
    # Wait for children to finish too if this is a daemon that forks
    # and if the daemon is only ever run from this initscript.
    # If the above conditions are not satisfied then add some other code
    # that waits for the process to drop all resources that could be
    # needed by services started subsequently.  A last resort is to
    # sleep for some time.
    ADDOK_CONFIG_MODULE=$ADDOK_CONFIG_MODULE start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
    [ "$?" = 2 ] && return 2
    # Many daemons don't delete their pidfiles when they exit.
    rm -f $PIDFILE
    return $RETVAL
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
    ADDOK_CONFIG_MODULE=$ADDOK_CONFIG_MODULE start-stop-daemon --stop --signal HUP --quiet --pidfile $PIDFILE
    return 0
}

case "$1" in
  start)
    [ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
    do_start
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  stop)
    [ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
    do_stop
    case "$?" in
        0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
        2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
    esac
    ;;
  status)
    status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
    ;;
  reload)
    log_daemon_msg "Reloading $DESC" "$NAME"
    do_reload
    log_end_msg $?
    ;;
  restart|force-reload)
    #
    # If the "reload" option is implemented then remove the
    # 'force-reload' alias
    #
    log_daemon_msg "Restarting $DESC" "$NAME"
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
            0) log_end_msg 0 ;;
            1) log_end_msg 1 ;; # Old process is still running
            *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        # Failed to stop
        log_end_msg 1
        ;;
    esac
    ;;
  *)
    #echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
    echo "Usage: $SCRIPTNAME {start|stop|status|reload|force-reload}" >&2
    exit 3
    ;;
esac

: