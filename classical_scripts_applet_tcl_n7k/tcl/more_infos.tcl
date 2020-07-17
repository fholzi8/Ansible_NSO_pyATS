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
	puts [format $lineFormat $data(IF) $data(DESC) $data(VLAN) $data(STATUS) $data(MACADDR) $data(POWER) $data(AUTH)]
} 

proc printProcess {pid} {  
	global lineFormat  
	set lineFormat "%-15s %-10s %-5s %-10s %-15s %-5s %-15s"  
	puts [format $lineFormat {Interface} {Description} {VLAN} {Status} {MacAddress} {PowerState} {AuthState} ]  
	set iftype "Gi1/0/"
	printOutput ifinfo
	for { set i 1 } { $i <= 48 } { incr i 1 } {
		set if ""
		lappend if $iftype$i
		set desc ""
		set desc1 [lindex [exec "show int $if statu | in $if"] 1]
		set desc2 [lindex [exec "show int $if statu | in $if"] 2]
		if {[string equal $desc1 ""]} {
			set desc $desc2
		} else {
			lappend desc $desc1 $desc2
		}
		set ifstatus [lindex [exec "show int $if statu | in $if"] 3]
		set vlan [lindex [exec "show int $if statu | in $if"] 4]
		if {[string equal $vlan "trunk"]} { 
			continue
		}
		set mac [lindex [exec "show mac add int $if | in $if"] 1]
		set powerstate [lindex [exec "show power inline $if | in $if"] 2]
		set authstate [lindex [exec "show dot1x all summ | in $if"] 3]
		if {[string equal $authstate ""]} {
			set authstate "dot1x not enabled"
		}
		set ifinfo(IF) $iftype$i
		set ifinfo(DESC) $desc
		set ifinfo(VLAN) $vlan
		set ifinfo(STATUS) $ifstatus
		set ifinfo(MACADDR) $mac
		set ifinfo(POWER) $powerstate
		set ifinfo(AUTH) $authstate
		
		if {[array exists ifinfo]} { 
			printOutput ifinfo 
		}
	}
}

set id 1
printProcess $id



