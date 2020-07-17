#       revision 0.1 2013-02-18 by user
#       initial revision
#
#       description:    This script show more information of interfaces
#
#       ios config:
#                       
#


proc printOutput {dataName} {  
	upvar $dataName data  
	global lineFormat  
	if {! [array exists data]} { return }  
	puts [format $lineFormat $data(IF) $data(DESC) $data(STATUS) $data(VLAN) $data(DUPLEX) $data(SPEED) $data(MACADDR) $data(POWER) $data(AUTH)]
} 

proc printProcess {iftype} {  
	global lineFormat  
	set lineFormat "%-12s %-20s %-15s %-5s %-15s %-10s %-15s %-10s %-15s"  
	puts [format $lineFormat {Interface} {Description} {Status} {VLAN} {Duplex} {Speed} {MacAddress} {PowerState} {AuthState} ]  
	printOutput ifinfo
	set cmdtext ""
	set max ""
	set cmdtext [exec "show inventory | in DESC"]
	#die max_anzahl der access-ports anhand der switch bezeichnung
	if {[regexp -nocase {.*WS-C2960S-([0-9]+).*-.*} $cmdtext ignore maxint] } {
		set max $maxint
	}
	for { set i 1 } { $i <= $max } { incr i 1 } {
		set if ""
		lappend if $iftype$i
		#interface status
		set value ""
		set value [exec "show int $if statu | in $if"]
		#puts "Line $i: $value\n"
		set desc [string range $value 10 28]
		set help_ifstatus [string range $value 29 41]
		set ifstatus [lindex $help_ifstatus 0]
		set help_duplex [string range $value 53 59]
		set duplex [lindex $help_duplex 0]
		set help_speed [string range $value 60 66]
		set speed [lindex $help_speed 0]
		set help_vlan [string range $value 42 52]
		set vlan [lindex $help_vlan 0]
		#trunk ports werden ausgeschlossen
		if {[string equal $vlan "trunk"]} { 
			continue
		}		
		#mac address 
		set mac [lindex [exec "show mac add int $if | in $if"] 1]
		#power inline status
		set powerstate [lindex [exec "show power inline $if | in $if"] 2]
		#dot1x status
		set authstate [lindex [exec "show dot1x all summ | in $if"] 3]
		set eapolmac [lindex [exec "show dot1x all summ | in $if"] 2]
		
		if {[string equal $mac ""]} {
			set mac $eapolmac
		}
		if {[string equal $authstate ""]} {
			set authstate "dot1x not enabled"
		}
		
		set ifinfo(IF) $if
		set ifinfo(DESC) $desc
		set ifinfo(VLAN) $vlan
		set ifinfo(STATUS) $ifstatus
		set ifinfo(DUPLEX) $duplex
		set ifinfo(SPEED) $speed
		set ifinfo(MACADDR) $mac
		set ifinfo(POWER) $powerstate
		set ifinfo(AUTH) $authstate
		
		if {[array exists ifinfo]} { 
			printOutput ifinfo 
		}
	}
}


#hier kann man noch argc einlesen und der funktion übergeben
set id Fa0/
printProcess $id



