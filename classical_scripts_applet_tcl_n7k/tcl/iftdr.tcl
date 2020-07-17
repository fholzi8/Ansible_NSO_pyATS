#       revision 0.1 2015-01-08 by fholzapfel
#       initial revision
#
#       description:    This script show tdr information about interfaces
#
#       ios config:
#                       
#


proc printOutput {dataName} {  
	upvar $dataName data  
	global lineFormat  
	if {! [array exists data]} { return }  
	puts [format $lineFormat $data(IF) $data(LENGTH) $data(STATUS)]
} 

proc printProcess {iftype} {  
	global lineFormat  
	set lineFormat "%-12s %-15s %-20s"  
	puts [format $lineFormat {Interface} {PairLength} {PairStatus} ]  
	puts "=============================================\n"
	#printOutput ifinfo
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
		set tdr_value ""
		set tdr_value [exec "stdr $if | in meters "]
		#puts "Line $i: $tdr_value\n"
		set lines [ split $tdr_value "\n" ]
		set max_length ""
		set error_status ""
		set len 0
		foreach line $lines {
			set help_length [string range $line 27 32]
			set length [lindex $help_length 0]
			lappend max_length $length 
			#lappend max_length m 
			#max_length [ expr {$max_length + $length} ]
			set help_status [string range $line 58 75]
			set status [lindex $help_status 0]
			if {![string equal $status "Normal"]} { 
				set error_status $status
			}
			#lappend error_status $status
		}
		#set len [ expr {$max_length / 4} ]
		set ifinfo(IF) $if
		set ifinfo(LENGTH) $max_length		
		#set ifinfo(LENGTH) $len
		#regsub -all "Normal" $error_status "" error_status
		if {[string equal $error_status ""]} {
			set error_status "Normal"
		}
		set ifinfo(STATUS) $error_status
		
		if {[array exists ifinfo]} { 
			printOutput ifinfo 
		}
	}
}
 
#hier kann man noch argc einlesen und der funktion übergeben
set id Gi1/0/
printProcess $id



