#       revision 0.9 2011-09-26 by user
#       initial revision
#
#       description:    This script set the hsrp priority to the defined value
#
#       ios config:
#                       * download the file into flash:.tcl/hsrp_change.tcl 
#                       * configure alias exec hsrp tclsh flash:.tcl/hsrp_change.tcl for example
#
#                       **invoke with hsrp $priority
#
#
if { $argc == 1 } {
        set priority [lindex $argv 0]
} else {
        puts "Usage: hsrp $priority   for example debbi-vpn01#hsrp 230";
        return; 
}
ios_config "interface GigabitEthernet0/0.101" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.106" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.111" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.115" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.116" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.117" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.119" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.120" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.121" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.122" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.123" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.124" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.125" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.126" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.135" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.136" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.137" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.138" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.140" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.141" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.142" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.143" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.147" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.150" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.151" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.152" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.153" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.156" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.160" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.161" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.162" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.170" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.171" "standby 0 priority $priority"
ios_config "interface GigabitEthernet0/0.580" "standby 0 priority $priority"
puts "HSRP Priority is set to $priority"
puts "HSRP State changed in 4 seconds"
after 1000
puts "HSRP State changed in 3 seconds"
after 1000
puts "HSRP State changed in 2 seconds"
after 1000
puts "HSRP State changed in 1 seconds"
after 1000
puts "HSRP State change is done"
set status [exec sh standby | in (Gigabit|State|Priority)]
puts $status
puts "sh standby | in (Gigabit|State|Priority)"
