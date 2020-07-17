#	revision 0.9 2011-12-19 by fholzapfel
#	initial revision
#
#	description:	The script edit a file on the flash (for example)
#
#	usage: router#wol 2C-41-38-95-56-75
#	
#ios config:
#
#           * download the file into flash:.tcl/wakeonlan.tcl
#           * configure alias exec wol tclsh flash:.tcl/wakeonlan.tcl
#
package require udp

#puts "UDP Lib loaded"

proc WakeOnLan {broadcastAddr macAddr} {
     set net [binary format H* [join [split $macAddr -:.] ""]]
	 #puts "Net: $net"
     set pkt [binary format c* {0xff 0xff 0xff 0xff 0xff 0xff}]
	 #puts "Pkt: $pkt"
     for {set i 0} {$i < 16} {incr i} {
        append pkt $net
     }
     # Open UDP and Send the Magic Paket.
     set udpSock [udp_open]
	 #puts "UDP Socket loaded!"
     fconfigure $udpSock -translation binary -remote [list $broadcastAddr 4580] -broadcast 1
	 #puts "Zeile $pkt"
     puts $udpSock $pkt
     flush $udpSock;
     close $udpSock
}
set bcast "255.255.255.255"
set eth [lindex $argv 0]
puts "Tell me the mac: $eth"
set run [WakeOnLan $bcast $eth]

puts "PC with $eth started successful (hopefully)"