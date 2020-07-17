::cisco::eem::event_register_timer cron name trackSynFlow cron_entry "* * * * *" maxrun 200

################################################################################
# EEM policy to track abnormal syn traffic flows
#
# Dhanesh Kumar S (dhshanmu@cisco.com)
# Rajeswaran M C (rajmc@cisco.com)
#
# The policy is designed to run every minute and check the number of
# syn only flows in the given netflow monitor and to raise syslog
# messages if any abnormal syn flows are detected.  The flow also
# checks if there is sudden increase in syn only flows.
################################################################################
### The following EEM environment variables are used:
###
### synMonitorName (mandatory)		- The Netflow monitor name that the 
###                                       script will poll to calculate total 
###					  syn flows.
### Example: synMonitorName		  syn
###
### flowThreshold (Optional)		- Safe limit for total number of flows. 
###					  Flows greater than this number will 
###                                       make the script to check syn flows.  
###					  Defaults to 100
### Example: flowThreshold                1000
###
### synMaxPercentage (Optional)		- Allowable percentage of Syn flows out of
###					  total flows.  Default: 80
### Example: synMaxPercentage             68
###
### synBurst (optional)			- The total number of syn flows that can
###					  exceed within a specified time limit.
###					  Default: 100
### Example: synBurst                     1000
###
### synWaitTime (optional)		- The wait time in seconds to check for 
###					  Syn burst Default: 15
### Example: synWaitTime		  10
###
### debug (optional)			- If set to 1, debug messages are 
###					  printed with syslog. Default: 0
### Example: debug			  1
###
### action (optional)			- If set to 1, the respective interface
###					  from where the syn flows are will be shut-down.
###					  Default: 0 which will print Warning syslog
###					  message.
### Example : action			  0
################################################################################
### Required netflow configuration
### !
### flow record tcp_flows
###  match ipv4 protocol
###  match ipv4 source address
###  match ipv4 destination address
###  match transport tcp source-port
###  match transport tcp destination-port
###  match interface input
###  collect transport tcp flags
### !
### !
### flow monitor tcp_flows 
###  record tcp_flows
### !
### !
### interface GigabitEthernet3/1
###  no switchport
###  ip flow monitor tcp_flows input
###  ip address 1.1.1.1 255.255.255.0
### !
################################################################################
# Copyright (c) 2011 by cisco Systems, Inc.
# All rights reserved.
#------------------------------------------------------------------
# The namespace import commands that follow import some cisco TCL extensions
# that are required to run this script

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

# Check if the all the environment variables exist.  
# If manadatory variables are not present, print out an error
# If optional variables are not present, create and assign the default value

if {![info exists synMonitorName]} {
     	set result "Policy cannot be run: variable synMonitorName has not been set"
     	action_syslog msg " $result : Exiting out"  
	return 0
}

if { $synMonitorName == "" } {
	set result "Policy cannot be run: Variable 'synMonitorName' have been set NULL"
     	action_syslog msg " $result : Exiting out"  
	return 0
}

if {![info exists flowThreshold] || ($flowThreshold == "" ) } {
     	set flowThreshold 100
}

if {![info exists synMaxPercentage] || ($synMaxPercentage == "" )} {
     	set synMaxPercentage 80
}

if {![info exists synBurst] || ($synBurst == "" )} {
     	set synBurst 100
}

if {![info exists synWaitTime] || ($synWaitTime == "") } {
     	set synWaitTime 15
}

if {![info exists action] || ($action == "" )} {
     	set action 0
}

if {![info exists debug] || ($debug == "" )} {
     	set debug 0
}

set totalFlows 0
set interfaceList { }
set cmd_output ""

## Procedure to get the total number of Syn only flows using the cli command
## show flow monitor <monitor Name> cache
proc checkSynFlows { } {

   	global errorInfo synMonitorName flowThreshold debug totalFlows interfaceList cmd_output

	## Open cli to get the output of the flow cache to get the syn flows
	## and related parameters
   	if [catch {cli_open} result] {
      		error $result $errorInfo
   	} else {
     	array set cli1 $result
   	}
   	if [catch {cli_exec $cli1(fd) "en"} result] {
      		error $result $errorInfo
   	}
   	if [catch {cli_exec $cli1(fd) "sh flow monitor $synMonitorName cache"} result] {
      		error $result $errorInfo
   	} else {
      		set cmd_output $result
   	}

   	if [catch {cli_close $cli1(fd) $cli1(tty_id)} result] {
      		error $result $errorInfo
   	}

   	if {![regexp -nocase "Current entries:\[ |\t]+(\[0-9]+).*High" $cmd_output dummy totalFlows ]} {
        	set result "Couldn't extract total number of flows.  Exiting script"
        	action_syslog msg "$result" 
		return -1
   	}

   	if {$totalFlows < $flowThreshold} { 
      	 	#Not an Alarming situation. Return -1 
		if {$debug} {
			action_syslog msg "Total Flows doesn't exceed flow threshold"
			action_syslog msg "Total Flows $totalFlows   Threshold: $flowThreshold"
		}
       		return -1
   	}
	
	set myList [regexp -all -inline -nocase {[a-z]+[0-9]+/[0-9]+} $cmd_output]
	set interfaceList [lsort -unique $myList]
   	
	set actualSynFlows [regexp -nocase -all {IP PROTOCOL:[ |\t]+6[\r\n]+tcp flags:[ |\t]+0x02} $cmd_output]
   	return $actualSynFlows 

} ;### End of Procedure


set actualSynFlows [checkSynFlows]

if { $actualSynFlows < 0 } {
	## The cli output is not expected hence exiting the script
	## the proc checkSynFlows returned -1
	return 0
}

set allowedSynFlows [expr $synMaxPercentage * $totalFlows / 100]


if { $actualSynFlows < $allowedSynFlows || $actualSynFlows == 0} {
	if {$debug} {
		action_syslog msg "Total syn flows are less than critical Value."
		action_syslog msg "Actual Syn Flows: $actualSynFlows"
		action_syslog msg "Allowed Syn Flows: $allowedSynFlows"
	}
} else {
	action_syslog priority warning msg "WARNING: Total No of Syn flows exceeded $synMaxPercentage% of Total Flows."
	action_syslog priority warning msg "WARNING: Total Flows: $totalFlows   Total Syn Flows: $actualSynFlows"

	## Wait for synWaitTime and check again total Syn Flows.
	## If the syn flows increase more than synBurst value, generate syslog message

	after [expr $synWaitTime * 100]

	set newSynFlows [lindex [checkSynFlows] 0]
	set deltaSynFlows [expr $newSynFlows - $actualSynFlows ]

	if { $deltaSynFlows > $synBurst } {
        	action_syslog priority warning msg "WARNING: Syn flows have increased by $deltaSynFlows within $synWaitTime seconds"
	} else {
		if {$debug} {
			action_syslog msg "Syn Flows didn't increase more than $synBurst within $synWaitTime seconds."
		}
	}

	## Getting the interface specific values to provide a log about the particular interface
	## or to take an action based on the user input

	foreach interface $interfaceList {
		set int_totalFlows [regexp -nocase -all "$interface" $cmd_output ] 
		set int_actualSynFlows [regexp -nocase -all "$interface\[\r\n]+IP PROTOCOL:\[ |\t]+6\[\r\n]+tcp flags:\[ |\t]+0x02" $cmd_output ] 
		set int_allowedSynFlows [expr $synMaxPercentage * $int_totalFlows / 100]

		if { $int_actualSynFlows < $int_allowedSynFlows } {
			if {$debug} {
			action_syslog msg "Total syn flows in the interface $interface are less than critical Value."
			action_syslog msg "Actual Syn Flows in the interface $interface : $int_actualSynFlows"
			}
		} else {
		   action_syslog priority warning msg "WARNING: In interface $interface Total No of Syn flows exceeded $synMaxPercentage% of Total Flows."
		   action_syslog priority warning msg "WARNING: In interface $interface Total Flows: $int_totalFlows - Total Syn Flows: $int_actualSynFlows"

			## After giving the warning message if the user set the action to shut the interface
			## the following code will execute and shut the interface
			if { $action } {
				action_syslog priority warning msg "WARNING: The interface $interface will be shut-down"
		
   				# Open CLI and shut the interface 
   				if [catch {cli_open} result] {
      					error $result $errorInfo
   				} else {
     					array set cli1 $result
   				} 
   	
				if [catch {cli_exec $cli1(fd) "en"} result] {
      					error $result $errorInfo
   				}
   				if [catch {cli_exec $cli1(fd) "configure terminal"} result] {
      					error $result $errorInfo
   				}
   				if [catch {cli_exec $cli1(fd) "interface $interface"} result] {
      					error $result $errorInfo
   				}
   				if [catch {cli_exec $cli1(fd) "shut"} result] {
      					error $result $errorInfo
   				}
   				if [catch {cli_exec $cli1(fd) "end"} result] {
      					error $result $errorInfo
   				}

   				if [catch {cli_close $cli1(fd) $cli1(tty_id)} result] {
      					error $result $errorInfo
   				}		
			} ; ## End of if part when action is set to 1 to shut the interface

			## Checking if the interface is exceeding the Total allowed percentage
			## and returning out as the problematic interface is shut and no other interface
			## have a syn attack problem

			if { $int_actualSynFlows >= [expr $actualSynFlows  * 95 / 100] } {
				action_syslog priority warning msg "WARNING: In $interface Total No of Syn flows exceeded $actualSynFlows of Total Flows."
				action_syslog priority warning msg "WARNING: Syn flows in Total Flows: $actualSynFlows \
					                            - Total Syn Flows in the interface: $int_actualSynFlows"
				break
				## No need to check any other interface just exit
			}

		} ;## end of else when th einterface exceeds the given limits

	} ;## End of foreach to iterate on every interface in the flow

} ; ## End of else part when the syn flow exceeds and global action is taken
