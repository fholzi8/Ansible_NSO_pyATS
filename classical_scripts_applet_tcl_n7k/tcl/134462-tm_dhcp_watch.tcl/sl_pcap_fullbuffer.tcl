#	revision 1.1 2011-10-14 by user
#	
#	description:	This script is part to capture traffic
#	ios config:
#			* download the file into flash:.tcl/sl_pcap_fullbuffer.tcl
#		    * trigger  syslog message:  "BUFCAP-5-BUFFER_FULL"
#
#                         
# Syslog Event registration
::cisco::eem::event_register_syslog occurs 1  pattern .*BUFCAP-5-BUFFER_FULL.* maxrun 300 queue_priority normal nice 0

#
# Namespace imports
#
namespace import ::cisco::eem::*
namespace import ::cisco::lib::*


array set arr_einfo [event_reqinfo]


#
#puts "*** DEBUG: \"arr_einfo\" array created by \"event_reqinfo\""
#puts "======================================================="
#foreach { name value } [array get arr_einfo] {
#   puts "*** DEBUG: name = $name  value = $value"
#}
#puts "======================================================="
#
#if {[info exists _entry_status]} {
#   puts "*** DEBUG: _entry_status  = $_entry_status"
#}
#if {[info exists _exit_status]} {
#   puts "*** DEBUG: _exit_status   = $_exit_status"
#}   
#





# ----------------- "main" ----------------------------

# capture point stopped by IOS in this case

set strarg "triggered by syslog message \"BUFCAP-5-BUFFER_FULL\""
event_publish component_id 798 type 217 arg1 "$strarg"




# eeeeeeeeeeeeeeeeeeeeeeeeeeee End of sl_pcap_fullbuffer.tcl eeeeeeeeeeeeeeeeeeeeee 


