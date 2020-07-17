	revision 1.1 2011-10-14 by user
#	
#	description:	This script is part to capture traffic and is triggered by a countdown timer "pcap_timer"
#					the purpose of of this script is to stop capturing traffic after a maximum time
#                   so that packet captures on low utilization interfaces are not left running for 
#                   extended periods
#	ios config:
#			* download the file into flash:.tcl/ap_pcap_export.tcl
#  
#   requirements        :  -EEM env variables-
#                         event manager environment pcap_var_capbuf1      capbuf1
#                         event manager environment pcap_var_cappnt1      cappnt1
#                         event manager environment pcap_var_export_url   flash:/
#                         event manager environment pcap_var_intf_name    fastethernet0/0  ! - enter your interface here
#                         event manager environment pcap_var_max_captime  3600
#                         event manager environment pcap_var_max_capnum   60
#
#                         -EEM trigger-
#                         countdown timer "pcap_timer" set when first capture buffer 
#                         fills up and is exported
#                         (see companion file: ap_pcap_export.tcl)
#

# Syslog Event registration
::cisco::eem::event_register_timer_subscriber countdown name pcap_timer queue_priority normal maxrun 300 nice 0




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

puts "***  DEBUG in tm_pcap_stop.tcl ****"
   

if { [catch { foreach {var value} [context_retrieve PCAP] {set $var $value; #puts "\n\n*** DEBUG context_retrieve var = $var  value = $value"; } } result]} {
   puts "*** Error: no context PCAP was retrieved!"

} 
   
   
   
set pcap_cleanup     1

if {[catch {context_save PCAP "pcap_*"} result]} {
   error $result $errorInfo
}



puts "Stopping capture point $pcap_var_cappnt1 ..."
if {[catch { StopCapPoint $pcap_var_cappnt1 } result]} {
   puts "$result"
}


set strarg "triggered by expired timer"
event_publish component_id 798 type 217 arg1 "$strarg"





# eeeeeeeeeeeeeeeeeeeeeeeeeeee End of tm_pcap_stop.tcl eeeeeeeeeeeeeeeeeeeeee 


