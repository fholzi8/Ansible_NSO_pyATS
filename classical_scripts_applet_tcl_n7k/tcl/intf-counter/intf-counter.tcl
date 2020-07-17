::cisco::eem::event_register_interface name $intf parameter txload entry_op ge entry_val 192 entry_val_is_increment FALSE
#
#------------------------------------------------------------------
# EEM policy to monitor interface for a TX load of more than 75% (ie 192/255)
# Upon an event trigger, the policy will send a syslog message indicating
# interface has exceeded threshold 
#
# Environment variable INTF needs to be set with the interface to be monitored - ie G6/2, F3/1, etc
# September 2006 - Carl Solder (csolder@cisco.com)
#
# Copyright (c) 2006 by cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------

# namespace imports
#
namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

# Check that envionment variable has been set
if {![info exists intf]} { 
set result \ 
"Policy cannot be run: variable intf has not been set" 
error $result $errorInfo 
}

array set arr_einfo [event_reqinfo]
if {$_cerrno != 0} {
    set result [format "component=%s; subsys err=%s; posix err=%s;\n%s" \
	$_cerr_sub_num $_cerr_sub_err $_cerr_posix_err $_cerr_str]
    error $result 
}

# Set variable $msg with the counter value that was captured by this event
set count_value $arr_einfo(value)
action_syslog msg "Interface $intf has exceeded the packets per second limit on transmit"
action_syslog msg "Event triggered with txload of $count_value out of 255"
 
  


