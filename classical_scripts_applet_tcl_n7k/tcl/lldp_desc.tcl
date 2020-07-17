#::cisco::eem::event_register_timer watchdog time 60 name "setlldp_description"

#__revision__ 	=	0.5 2015-01-09 by fholzapfel
#__author__ 	= 	'fholzi8 (att) gmail.com (Florian Holzapfel)'
#
#__description__=	The script edit the description of an interface via its lldp neighbors
#
#__usage__		=	router#tclsh flash:.tcl/lldp_description.tcl
#	

proc print_description {id} {
	
	set allintf [exec "show interfaces status | inc connected"]
	set lines [split $allintf "\n"]
	foreach intf $lines {
		set if [lindex $intf 0]
		if {[string match "Po*" $if ]} {
			continue
		} 
		if {[string equal $if ""]} {
			continue
		}
		set llist [ exec "show lldp neighbors $if | inc $if" ]
		if {[string equal $llist ""]} {
			continue
		}
		set ilist [ string map {" " "x"} $llist ]
		set illdp [ split $ilist "x"]
		set hostname ""
		set hostname [lindex $illdp 0]
		set vi_cap ""
		set vi_cap [lindex $illdp 24]
		set capability ""
		if {[string match "R" $vi_cap]} {
			set capability "Router"
		} elseif {[string match "B" $vi_cap]} {
			set capability "Switch"
		} elseif {[string match "T" $vi_cap]} {
			set capability "Telephone"
		} elseif {[string match "W" $vi_cap]} {
			set capability "AccessPoint"
		} elseif {[string match "S" $vi_cap]} {
			set capability "Station"
		} else {
			set capability "Other"
		}
		set rem_desc [exec "show lldp entry $hostname | inc  Port Description"]
		set rem_port [lindex [split $rem_desc "\n"] 0]
		
		if {[string equal $capability "Station" ]} {
			if  {[regexp {Port Description: (.*)} $rem_port match remote_intf]} {
				set rem_intf $remote_intf
			} else {
				set rem_intf [lindex $illdp 39]
			}
		} else {
			set rem_intf [lindex $illdp 39]
		}
		set rem_host [exec "show lldp entry $hostname | inc  IP"]
		set hostip ""
		set hostip [lindex $rem_host 1]
		set r_if ""
		set r_if [string trim $rem_intf]
		set description ""
		lappend description $hostname
		if {![string equal $hostip ""]} {
			lappend description "\($hostip\)"
		}
		if {![string equal $r_if ""]} {
			lappend description on $r_if
		}
		if {![string equal $capability ""]} {
			lappend description type: $capability
		}
		puts "Desc: $description"
	}
}

set id 1

print_description $id
	
