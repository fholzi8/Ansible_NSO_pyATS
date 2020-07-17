#	revision 1.1 2011-10-14 by user
#	
#	description:	This script is part to capture traffic
#					the purpose of of this script is to setup the variable and start the timer then save 
#                   the context variables 
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
#                         

# Event registration
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




proc StartCapPoint { cappnt_name } { 
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
   if {[catch {cli_exec $cli(fd) "monitor capture point start $cappnt_name"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }      
   #---- cli close ----
   cli_close $cli(fd) $cli(tty_id)  
} ; # end proc StartCapPoint



# ----------------- "main" -----------------


# --- check the environment variables are defined ---
if {![info exists pcap_var_capbuf1]} {
 set result "Policy cannot be run: variable \"pcap_var_capbuf1\" has not been set"
 error $result $errorInfo
}

if {![info exists pcap_var_cappnt1]} {
 set result "Policy cannot be run: variable \"pcap_var_cappnt1\" has not been set"
 error $result $errorInfo
}

if {![info exists pcap_var_export_url]} {
 set result "Policy cannot be run: variable \"pcap_var_export_url\" has not been set"
 error $result $errorInfo
}

if {![info exists pcap_var_intf_name]} {
 set result "Policy cannot be run: variable \"pcap_var_intf_name\" has not been set"
 error $result $errorInfo
}

if {![info exists pcap_var_max_captime]} {
 set result "Policy cannot be run: variable \"pcap_var_max_captime\" has not been set"
 error $result $errorInfo
}

if {![info exists pcap_var_max_capnum]} {
 set result "Policy cannot be run: variable \"pcap_var_max_capnum\" has not been set"
 error $result $errorInfo
}




# set vars and save context

set pcap_timername  "pcap_timer"
set pcap_cleanup     0
set pcap_timer_id    -1
set pcap_ctr 0


puts "Starting capture point \"$pcap_var_cappnt1\" ..."
if {[catch { StartCapPoint $pcap_var_cappnt1 } result]} {
   puts "*** ERROR: $result $errorInfo" 
}



puts "Resetting \"pcap_ctr\"" 
puts "Setting max capture timer \"$pcap_timername\""
array set tmp  [register_timer countdown name $pcap_timername]
set pcap_timer_id $tmp(event_id)
array set time_remaining [timer_arm event_id $pcap_timer_id time $pcap_var_max_captime]
puts "*** DEBUG: setting max capture timer: sec_remain  = $time_remaining(sec_remain)"

puts "*** DEBUG: saving context..."
if {[catch {context_save PCAP "pcap_*"} result]} {
   error $result $errorInfo
}






# eeeeeeeeeeeeeeeeeeeeeeeeeeee End of no_pcap_start.tcl eeeeeeeeeeeeeeeeeeeeee 


