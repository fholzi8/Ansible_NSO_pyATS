#       revision 0.9 2011-09-26 by user
#       initial revision
#
#       description:    This script disable an interface and reenable it after an one hour
#
#       ios config:
#                       * download the file into flash:.tcl/shutdown.tcl 
#                       * configure alias exec down tclsh flash:.tcl/shutdown.tcl for example
#
#                       **invoke with down $interface_name
#

# ifname is set to first CLI parameter (interface name)
#
set ifname [lindex $argv 0]
if {[string equal $ifname ""]} { puts "Usage: down ifname"; return; }
if { [ catch { exec "show ip interface $ifname" } errmsg ] } {
  puts "Invalid interface $ifname, show ip interface failed"; return}

ios_config "interface $ifname" "shutdown"
puts [ exec "show ip interface brief | include $ifname" ]
