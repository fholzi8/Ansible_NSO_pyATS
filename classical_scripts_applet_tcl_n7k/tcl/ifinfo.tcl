#__revision__ 	=	0.5 2015-01-09 by fholzapfel
#__author__ 	= 	'fholzi8 (att) gmail.com (Florian Holzapfel)'
#__description	= 	This script show more information of interfaces (cable-length, dot1x-state, poe, in/output-rate, mac)
#
# ios config:
#   conf t
#	kron occurrence TDR at 3:30 recurring
#	 policy-list tdr-testing-part1
#	 policy-list tdr-test-part2
#	kron policy-list tdr-testing-part1
#	 cli test cable-diagnostics tdr interface fa0/1 - 12
#	kron policy-list tdr-testing-part2
#	 cli test cable-diagnostics tdr interface fa0/13 - 24
#	!and so on
#	mkdir flash:.tcl
#	alias exec ifinfo tclsh flash:.tcl/ifinfo.tcl
#	alias exec sri sh run | inc 
#	alias exec srs sh run | sec 
#	alias exec srb sh run | begin  
#
#copy the tcl-script to following location flash:.tcl/
#(i.e.:  copy tftp://1.1.1.1/ifinfo.tcl flash:.tcl/ifinfo.tcl)
#


proc printOutput {dataName} {  
	upvar $dataName data  
	global lineFormat  
	if {! [array exists data]} { return }  
	puts [format $lineFormat $data(IF) $data(DESC) $data(STATUS) $data(VLAN) $data(DUPLEX) $data(SPEED) $data(RXBS) $data(TXBS) $data(MACADDR) $data(POWER) $data(AUTH) $data(LENGTH) $data(TDRSTATUS) $data(HOST)]
} 
proc multi_table {x} {
	return [expr $x*150]
}

proc printProcess {id} {  
	global lineFormat  
	set lineFormat "%-12s %-20s %-10s %-4s %-6s %-6s %-8s %-8s %-14s %-8s %-17s %-12s %-15s %-15s"  
	set cmdtext ""
	set max ""
	set cmdtext [exec "show inventory | in DESC"]
	#die max_anzahl der access-ports anhand der switch bezeichnung
	if {[regexp -nocase {.*WS-C2960.*-([0-9]+).*-.*} $cmdtext ignore maxint] } {
		set max $maxint
	} 
	set iftype_value [lindex [exec "sh interfaces counters | in 0"] 0]
	if {[string match "*\/1" $iftype_value]} {
		set type [string range $iftype_value 0 end-1]
	}
	#puts "!-------\n!Type: $type\n!-----\n"
	puts [format $lineFormat {Interface} {Description} {Status} {VLAN} {Duplex} {Speed} {RXBS} {TXBS} {MacAddress} {PoEState} {AuthState} {Cable-Length} {TDR-Status} {Hostname}]  
	set table "--------------------------------------------------------------------------------------------------------------------------------------------------------------------"
	#multi_table table
	puts $table
	printOutput ifinfo
	for { set i 1 } { $i <= $max } { incr i 1 } {
		set if ""
		#interfacetyp zusammenbauen
		lappend if $type$i
		
		#interface status es werden die stati: Description, Duplex, Speed, Vlan
		set value ""
		set value [exec "show int $if statu | in $if"]
		#puts "Line $i: $value\n"
		set desc [string range $value 10 28]
		set help_ifstatus [string range $value 29 41]
		set ifstatus [lindex $help_ifstatus 0]
		if {[string equal $ifstatus "disabled"]} { 
			continue
		}
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
		
		#registrierte eap-mac
		set eapolmac [lindex [exec "show dot1x all summ | in $if"] 2]
		
		#registrierter username aka hostname
		set hostname [lindex [exec "show authentication sessions interface $if | in User"] 1]
		if {[string equal $hostname ""]} {
			set hostname "N/A"
		}
		set host $hostname
		if {[string match "*\.company\.local" $hostname]} {
			set host1 [ string map {".company.local" ""} $hostname ]
			set host [ string map {"host/" ""} $host1 ]
		} elseif {[string match "company-INTERN*" $hostname]} {
			set host [ string map {"company-INTERN" ""} $hostname ]
		}
		
		
		
		
		#ersetzen der mac-addresse durch registirerte dot1x-mac
		if {[string equal $mac ""]} {
			set mac $eapolmac
		}
		if {[string equal $authstate ""]} {
			set authstate "dot1x not enabled"
		}
		#bestimmung der kabellaenge
		set tdr_value ""
		set tdr_value [exec "stdr $if | in meters "]
		#puts "Line $i: $tdr_value\n"
		set lines [ split $tdr_value "\n" ]
		set max_length ""
		set error_status ""
		set temp 0
		set len 0
		foreach line $lines {
			set help_length [string range $line 27 32]
			set length [lindex $help_length 0]
			#set length [string trim $length]
			if {[string is integer -strict $length]} {
				set templ [ expr $temp + $length ]
			} else {
				set templ 1
			}
			set temp $templ
			set help_status [string range $line 58 75]
			set status [lindex $help_status 0]
			if {![string equal $status "Normal"]} { 
				set error_status $status
			}
			#lappend error_status $status
		}
		set len [ expr $temp/4.0 ]
		lappend len m
		if {[string equal $error_status ""]} {
			set error_status "Normal"
		}
		
		#bestimmung der receive und transmit rate
		set xbs_value ""
		set xbs_value [exec "sh int $if controller | in put rate"]
		set values [ split $xbs_value "\n" ]
		set input ""
		set output ""
		foreach val $values {
			if {[regexp -nocase {.*input rate ([0-9]+) bit.*} $val ignore max_in] } {
				#if { $max_in > 800000 } {
				#	set input [ expr $max_in/1000000.0 ]
				#	lappend input mbps
				#} elseif { $max_in > 800 } {
					set input [ expr $max_in/1000 ]
					lappend input kbps
				#} else {
				#	set input $max_in
				#	lappend input bps
				#}
			}
			if {[regexp -nocase {.*output rate ([0-9]+) bit.*} $val ignore max_out] } {
				#if { $max_out > 800000 } {
				#	set output [ expr $max_out/1000000.0 ]
				#	lappend output mbps
				#} elseif { $max_out > 800 } {
					set output [ expr $max_out/1000 ]
					lappend output kbps
				#} else {
				#	set output $max_out
				#	lappend output bps
				#}			
			}
		}
		
		
		#werte in die liste eintragen fuer output
		set ifinfo(IF) $if
		set ifinfo(DESC) $desc
		set ifinfo(VLAN) $vlan
		set ifinfo(STATUS) $ifstatus
		set ifinfo(DUPLEX) $duplex
		set ifinfo(SPEED) $speed
		set ifinfo(RXBS) $input
		set ifinfo(TXBS) $output
		set ifinfo(MACADDR) $mac
		set ifinfo(HOST) $host
		set ifinfo(POWER) $powerstate
		set ifinfo(AUTH) $authstate
		set ifinfo(LENGTH) $len	
		set ifinfo(TDRSTATUS) $error_status
		
		#println
		if {[array exists ifinfo]} { 
			printOutput ifinfo 
		}
	}
}


#hier kann man noch argc einlesen und der funktion übergeben
set id 1
printProcess $id



