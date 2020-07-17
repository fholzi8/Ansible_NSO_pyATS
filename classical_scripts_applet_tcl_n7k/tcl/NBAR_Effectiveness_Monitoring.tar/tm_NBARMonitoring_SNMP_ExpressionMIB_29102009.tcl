###############################################################################################################
#
#  Revision #          :  1.1
#
# Copyright (c) September,2009 - Marisol Palmero
# All rights reserved.
# This script is based in CustomMIB script version 1.5 (ExpressionMIB), where customer 
# will be able to extract two or more values from a show command and made them available via SNMP.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Cisco, the name of the copyright holder nor the
#    names of their respective contributors may be used to endorse or
#    promote products derived from this software without specific prior
#    written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
#
#
#  Description         :  NBAR Effectiveness Monitoring Use case combines an EEM policy based in ED Timer and Expression-MIB (mib tree under 1.3.6.1.4.1.9.10.22). 
#                       The TCL Policy is able to extract "unknown" and "Total" In Packets counters from "show ip nbar protocol-discovery interface" command,
#                       and it calculates the NBAR Effectiveness discovered traffic, under the formula (Total-unknown)*100/Total. 
#  		            The Policy send a Threshold Notification(Syslog and SNMP Trap)in case that the NBAR Effectivenes is going below 80%(Warning) and also 70%(Critical).
#                       The Policy also creates an CLI alias "showIpNbarEffective", that shows the percentage of Unrecognized traffic. 
#
#
#  Requirements        :  -EEM env variables-    
#                         event manager environment countdown_entry <frequency>, frequency at which the Expression-MIB variable is updated.
#                         event manager environment match_interface <interface>, interface from which we would like to extract NBAR stats.
#                         event manager environment rw_community <rw_community_string>, ReadWrite SNMP Community string
#                         event manager environment ip_address <ip_address>, Ip address from the IOS device, normally it will be the managed ip address
#                         event manager environment exp_name <Expression name>, Expression name is the index that we use to identify every value we extract from the show command.
#                         event manager environment nbar_exp_name <NBAR Expression name>, Expression name for nbar effectiveness parameter.
#
#                       
#                         -Example EEM env variables- 
#                         event manager environment countdown_entry 60
#                         event manager environment match_interface Vlan1
#                         event manager environment rw_community private
#                         event manager environment ip_address 10.0.0.1 
#                         event manager environment exp_name cisco1,cisco2 
#                         event manager environment nbar_exp_name cisco
#
#                         -EEM event-
#                         Event Detector Timer
#
#                         -EEM action-
#                    
#                         -Prerequisites-
#                          Support for the Expression-MIB (12.0(5)T), 
#                          SNMP manager will be enabled in the router after executing the script
#                          We need to set two exp_name variables to associate the indexes to each of the values extracted under unknown and Total counted NBAR In Packets, 
#                          separated by comma ",". 
#                          "ip nbar protocol discovery" feature needs to be enabled under the interface for which we want to Monitor Efectivennes protocol discovery by the NBAR feature" 
#				   The script only applies to Incoming traffic. To change it for Outgoing traffic, it is needed to change $match_pattern variable within this script.
#				   
#				   			   
#                          
# 
#				   -Output-
#                         * snmpget under oid  1.3.6.1.4.1.9.10.22
#                         * Syslog message and snmp trap when the threshold of 80%(Warning) and 70% (Critical) on NBAR Efectiveness has been exceeded
#                          i.e. syslog message:
#                          %HA_EM-2-LOG: tm_NBARMonitoring_SNMP_RFC.tcl: Critical Threshold 80% for NBAR Effectiveness has been exceeded in the last 20 seconds
#                          snmp Trap packet:
#                          1135683: Sep 25 15:05:17.148: SNMP: Queuing packet to 10.48.71.148
#                          1135684: Sep 25 15:05:17.148: SNMP: V1 Trap, ent cEventMgrMIB, addr 10.48.86.34, gentrap 6, spectrap 2
#                          ceemHistoryEventEntry.2.137 = 21
#                          ceemHistoryEventEntry.3.137 = 0
#                          ceemHistoryEventEntry.4.137 = 0
#                          ceemHistoryEventEntry.5.137 = 0
#                          ceemHistoryEventEntry.6.137 = flash://tm_NBARMonitoring_SNMP_ExpressionMIB.tcl
#                          ceemHistoryEventEntry.7.137 = script: tm_NBARMonitoring_SNMP_ExpressionMIB.tcl 
#                          ceemHistoryEventEntry.9.137 = 80
#                          ceemHistoryEventEntry.10.137 = 0
#                          ceemHistoryEventEntry.11.137 = Threshold 80% for NBAR Effectiveness has been exceeded
#                          ceemHistoryEventEntry.13.137 = 0
#                          ceemHistoryEventEntry.14.137 = 0
#                          ceemHistoryEventEntry.15.137 = 0
#                          ceemHistoryEventEntry.16.137 = 0
#                          * Router#showIpNbarEffective
#                   45%  
# $Id: tm_NBARMonitoring_SNMP_ExpressionMIB.tcl,v 1.1 2009/10/28 13:55:43 mpalmero Exp $
###############################################################################################################
#####################################################################################
#
# EEM script will populate every X seconds (X seconds will be the frequency at which EEM policy is running),
# EEM policy is based on the CounterDown Event Detector.
#
# In the past we were tight to the SNMP support for certain values:
#   Today combining Expression-MIB and TCL (EEM makes a nice combination out of it),
# we are able to extract any or several given value from a show command, and access them via SNMP.
######################################################################################




::cisco::eem::event_register_timer watchdog name watchdog time $countdown_entry maxrun 240

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

###-------------------------------------------------------------------###
#												#
# 				Utility functions						#
#												#
####------------------------------------------------------------------###

proc CLICmd {cmd} {
    set clicmd ""
    lappend clicmd $cmd
    return [CLICmds $clicmd]
}

proc CLICmds {cmds} {
   global errorInfo
    if [catch {cli_open} result] {
        error $result $errorInfo 
    } else {
        array set cli1 $result
    }   
    if [catch {cli_exec $cli1(fd) "enable"} result] {
        error $result $errorInfo
    }
    foreach a_cmd $cmds {
        if [catch {cli_exec $cli1(fd) $a_cmd} result] {
            error $result $errorInfo
        } else {
            append cmd_output $a_cmd\n 
            append cmd_output $result
        }
    }
    if [catch {cli_close $cli1(fd) $cli1(tty_id)} result] {
        error $result $errorInfo
    }
    return $cmd_output
}

proc str2hdec {proc_string} {

   # function converts every character in the string into hexdecimal format.
   # between each value we have a dot.
   # Example: cisco -> 99.105.115.99.111

     set new_string ""
     set length [string length $proc_string]

     for {set i 0} {$i < $length} {incr i} {
           scan [string index $proc_string $i] %c temp_char
       append new_string "." $temp_char
     }
     return $new_string
   } 

####------------------------------------------------------------------###
#												#
# 		Sanity checks for environment variables				#
#												#
#---------------------------------------------------------------------###

if {![info exists match_interface]} {
    set result "EEM Policy Error: variable match_interface has not been set"
    error $result $errorInfo
}
if {![info exists exp_name]} {
    set result "EEM Policy Error: variable exp_name has not been set"
    error $result $errorInfo
}
if {![info exists nbar_exp_name]} {
    set result "EEM Policy Error: variable nbar_exp_name has not been set"
    error $result $errorInfo
}
if {![info exists countdown_entry]} {
    set result "EEM Policy Error: variable countdown_entry has not been set"
    error $result $errorInfo
}
if {![info exists ip_address]} {
    set result "EEM Policy Error: variable ip_address has not been set"
    error $result $errorInfo
}
if {![info exists  rw_community]} {
    set result "EEM Policy Error: variable  rw_community has not been set"
    error $result $errorInfo
}
#  
#
###-------------------------------------------------------------------###
#												#
#				Core script							#
#												#
###-------------------------------------------------------------------###

set match_pattern .*unknown\\s+(\[0-9\]+),.*Total\\s+(\[0-9\]+)
set capture_cmd_list ""
lappend capture_cmd_list "enable"
lappend capture_cmd_list "config t"
lappend capture_cmd_list "snmp-server manager"
lappend capture_cmd_list "exit "

	# $expr_index will be used to initialize the expExpressionIndex
set expr_index 1

	# $num_expr is the number of expressions we have to evaluate against the show command
      # $num_expr == 1
set num_expr [regexp -all -line {\,} $match_pattern]

	# $split_pattern is an array, each element contains one pattern. We use "," to split several expressions
set split_pattern [split $match_pattern ,]
	
	# $split_exp_name is an array, each element contains expression name. Expressions name are splitted by ","
set split_exp_name [split $exp_name ,]

	# $cli_result contains output of our show command



for {set j 0} {$j < [expr $num_expr+1]} {incr j 1} {
set match_cmd "show ip nbar protocol-discovery interface $match_interface"
set cli_result [CLICmd $match_cmd]
	set found [regexp -all -inline -line -- [lindex $split_pattern $j] $cli_result]
	set num_elem [regexp -all -line -- [lindex $split_pattern $j] $cli_result]
    
	if {[llength $found]} {
		set problem_present true
	} else {
		set problem_present false
	}

	if { $problem_present } {
		for {set i 0} {$i < $num_elem} {incr i 1} {
			set new_oid [str2hdec [lindex $split_exp_name $j]$i]
		      lappend capture_cmd_list "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.3$new_oid  integer 6"
		      lappend capture_cmd_list "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.3$new_oid integer 5"
		      lappend capture_cmd_list "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.2$new_oid gauge $expr_index"
		      lappend capture_cmd_list "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.3.1.1.2.$expr_index string [lindex $found [expr $i*2+1]]"
		      lappend capture_cmd_list "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.3$new_oid integer 1"
	      incr expr_index 1
		} 
	}
      set cli_result [CLICmds $capture_cmd_list]
}

#this script only applies for the Formula to monitor the NBAR Effectiveness
regexp {.*\= ([0-9]+)} [CLICmd "snmp get v2c $ip_address  $rw_community  oid 1.3.6.1.4.1.9.10.22.1.4.1.1.2.1.0.0.0"] ignore unknown 
regexp {.*\= ([0-9]+)} [CLICmd "snmp get v2c $ip_address  $rw_community  oid 1.3.6.1.4.1.9.10.22.1.4.1.1.2.2.0.0.0"] ignore Total 
set NBAREffect [expr {($Total-$unknown)*100/$Total}]


set nbar_index [str2hdec $nbar_exp_name]
set expr_nbar_index [expr {$num_elem+2}]
			CLICmd "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.3$nbar_index integer 6"
		      CLICmd "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.3$nbar_index integer 5"
		      CLICmd "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.2$nbar_index gauge $expr_nbar_index"
		      CLICmd "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.3.1.1.2.$expr_nbar_index string $NBAREffect"
		      CLICmd "snmp set v2c $ip_address $rw_community oid 1.3.6.1.4.1.9.10.22.1.2.3.1.3$nbar_index integer 1"

regexp {.*\= ([0-9]+)} [CLICmd "snmp get v2c $ip_address  $rw_community  oid 1.3.6.1.4.1.9.10.22.1.4.1.1.2.$expr_nbar_index.0.0.0"] ignore NBARRecognizedTraffic 

set capture_cmd_list_1 ""
lappend capture_cmd_list_1 "enable"
lappend capture_cmd_list_1  "config t"
lappend capture_cmd_list_1  "event manager environment NBARRecognizedTraffic $NBARRecognizedTraffic%"
lappend capture_cmd_list_1  "alias exec showIpNbarEffective show event manager environment NBARRecognizedTraffic"
lappend capture_cmd_list_1  "exit"
set cli_result [CLICmds $capture_cmd_list_1]


if {$NBARRecognizedTraffic < 40} {
action_syslog priority critical msg "Critical Threshold 40% for NBAR Effectiveness has been exceeded in the last $countdown_entry seconds"
action_snmp_trap intdata1 40 strdata "Threshold 40% for NBAR Effectiveness has been exceeded"
} elseif {$NBARUnrecognizedTraffic < 60} {
action_syslog priority warning msg "Warning Threshold 60% for NBAR Effectiveness has been exceeded in the last $countdown_entry seconds"
action_snmp_trap intdata1 60 strdata "Threshold 60% for NBAR Effectiveness has been exceeded"
} 

