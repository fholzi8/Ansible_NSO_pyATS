#
# simple portscanner per ip
# (proof of concept)
# Version 0.8a
# date 13.11.2008
# (c) by packetlevel.ch
#
# 
# ios installation:
#
#     download the file scanip.tcl into flash:scanip.tcl
#     configure a alias:  alias exec scanip tclsh flash:scanip.tcl
#     execute with: scanip [ip-address] [port] [port]
#                   scanip [ip-address]               <- scan the ip with a default port list
#  
#
#################################################
#
# known bugs. 
# 
# - slow, if ip dosn't exist
# - 
#
#################################################
#
# scanip help
#
proc scanhelp {} {
puts {scanip.tcl Version 0.8a / (c) 2008 by packetlevel.ch}
puts {Usage: scanip [ip-address] [port] [port] ...}; 
puts {       scanip [ip-address]  (use default port list)};
}
#
# simple ip address test
#
proc isIP {str} {
   set ipnum1 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set ipnum2 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set ipnum3 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set ipnum4 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
   set fullExp {^($ipnum1)\.($ipnum2)\.($ipnum3)\.($ipnum4)$}
   set partialExp {^(($ipnum1)(\.(($ipnum2)(\.(($ipnum3)(\.(($ipnum4)?)?)?)?)?)?)?)?$}
   set fullExp [subst -nocommands -nobackslashes $fullExp]
   set partialExp [subst -nocommands -nobackslashes $partialExp]
      if [regexp -- $fullExp $str] {
         return 1
      } else {
         return 0
      }
}
#
# simple port check ( 1 - 65535 ) 
#
proc isPORT {dport} {
 set isPORT "1"
 if {[string is integer $dport] == 1} then {
    if {$dport > 65535} then {set isPORT "0"}
    if {$dport < 1}   then {set isPORT "0"}
   } else { set isPORT "0" }
 return $isPORT
}
#
# default scan  with a default port list
#
proc defaultscan  {daddr} {
	foreach port {21 22 23 25 80 110 443 445 3128 8080 } {
	connect $daddr $port
	}
}
#
# open 
#
proc opensocket { ip port } { 
	set sock [socket $ip $port] }
#
# simple try and error to connect 
#
proc connect {ip port} {

if { [catch { opensocket $ip $port } sock] } {

set EXIT_MSG "$ip:$port ERR : $sock"
set expCode1 "timeout"
set expCode2 "connection timed out"
set expCode3 "connection refused"
set expCode4 "Unknown host"
set expCode5 "no route to host"
set expCode6 "unable to connect"
set expCode7 "host is unreachable"

if { [ regexp $expCode1 $sock ] } { 
	set EXIT_MSG "$ip:$port Port Closed: <$expCode1>"
	puts $EXIT_MSG }

if { [ regexp $expCode2 $sock ] } { 
	set EXIT_MSG "$ip:$port Port Closed: <$expCode2>"
	puts $EXIT_MSG }

if { [ regexp $expCode3 $sock ] } {
	set EXIT_MSG "$ip:$port Port Closed: <$expCode3>"
	puts $EXIT_MSG }

if { [ regexp $expCode4 $sock ] } { 
	set EXIT_MSG "$ip:$port Port Closed: <$expCode4>"
	puts $EXIT_MSG }

if { [ regexp $expCode5 $sock ] } { 
	set EXIT_MSG "$ip:$port Port Closed: <$expCode5>"
	puts $EXIT_MSG }

if { [ regexp $expCode6 $sock ] } { 
	set EXIT_MSG "$ip:$port Port Closed: <$expCode6>"
	puts $EXIT_MSG }

if { [ regexp $expCode7 $sock ] } { 
	set EXIT_MSG "$ip:$port Port Closed: <$expCode7>"
	puts $EXIT_MSG }

} else {
	set EXIT_MSG "$ip:$port Port Open:"
	close $sock
	puts $EXIT_MSG }
}
#################################################
#
# main / arguments 
#
if { $::argc > 0 } {
	set ipaddr [lindex $argv 0 ]
#	puts "IP Adresse $ipaddr"
	if {! [isIP $ipaddr]}  { scanhelp;return  }
	set i 1
	set max $argc
	if { $max < 2 } { defaultscan $ipaddr} 
	while {$i< $max} {
   		 set port [lindex $argv $i]
#   		 puts "Target  $ipaddr $port"
   		 if {! [isPORT $port]} { puts "invalid port: $port" } else {
    		      connect $ipaddr $port
    		      }
   		 incr i
		 }

        } else {
		scanhelp;
	        return;
  	        }
  
  
  
