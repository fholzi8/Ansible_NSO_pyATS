#	revision 1.1 2011-10-14 by user
#	
#	description:	This script is part to capture traffic
#	ios config:
#			* download the file into flash:.tcl/no_pcap_stop.tcl
#
# Syslog Event registration
::cisco::eem::event_register_none queue_priority low nice 1 maxrun 600



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





proc StopCapPoint { cappnt_name } { 
   #---- cli open ----
   if {[catch {cli_open} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   } else {
      array set cli $result
   }
   
   # --- Enable mode ---
   if {[catch {cli_exec $cli(fd) "enable"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }
   if {[catch {cli_exec $cli(fd) "monitor capture point stop $cappnt_name"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }      
   #---- cli close ----
   cli_close $cli(fd) $cli(tty_id)  
} ; # end proc StopCapPoint




# ----------------- "main" -----------------



# --- check the environment variables are defined --
if {![info exists pcap_var_cappnt1]} {
 set result "Policy cannot be run: variable \"pcap_var_cappnt1\" has not been set"
 error $result $errorInfo
}




# recall PCAP context, set pcap_cleanup == 1 and save context



if { [catch { foreach {var value} [context_retrieve PCAP] {set $var $value; #puts "\n\n*** DEBUG context_retrieve var = $var  value = $value";} } result]} {
   puts "\n\n*** DEBUG:  No context PCAP saved!\n\n"

} 

puts "***  DEBUG no_pcap_stop.tcl ****"
   
set pcap_cleanup     1

if {[catch {context_save PCAP "pcap_*"} result]} {
   error $result $errorInfo
}


puts "Stopping capture point $pcap_var_cappnt1 ..."
if {[catch { StopCapPoint $pcap_var_cappnt1 } result]} {
   puts "$result"
}
   

set strarg "triggered by manual run"
event_publish component_id 798 type 217 arg1 "$strarg"




# eeeeeeeeeeeeeeeeeeeeeeeeeeee End of no_pcap_stop.tcl eeeeeeeeeeeeeeeeeeeeee 


