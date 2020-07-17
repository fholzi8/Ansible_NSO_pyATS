#	revision 1.1 2011-10-14 by user
#	
#	description:	This script is part to capture traffic and exports it to a file named export.pcap
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
#                         application event "sub_system 798 type 217" published 
#

# Application Event registration
::cisco::eem::event_register_appl sub_system 798 type 217 queue_priority normal maxrun 600 nice 0

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


proc ClearCapBuffer { capbuf_name } { 
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
   if {[catch {cli_exec $cli(fd) "monitor capture buffer $capbuf_name clear"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }      
   #---- cli close ----
   cli_close $cli(fd) $cli(tty_id)  
} ; # end proc ClearCapBuffer





proc ExportCapBuffer2 { capbuf_name url } {
	
   set url [string trim $url "/"]
   set ifilename     "tmp.pcap"

   
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
   if {[catch {cli_exec $cli(fd) "monitor capture buffer $capbuf_name export $url/$ifilename"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }      
    
   #---- cli close ----
   cli_close $cli(fd) $cli(tty_id) 
   
} ; # end proc ExportCapBuffer2

	
proc ConcatenatePcap { url } {
	
   set url [string trim $url "/"]
   
   set ifilename     "tmp.pcap"
   set ofilename     "export.pcap"
   set ifile_fd      "NULL"
   set ofile_fd      "NULL"
   set FALSE         0
   set TRUE          1
   
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
   
   if { ![file exists $url/$ofilename] } {
      #puts "*** DEBUG: $ofilename does not exist!"
      set ofile_existed 0
      set ofile_fd [open $url/$ofilename w 0600]
      fconfigure $ofile_fd -translation binary -encoding binary
   } else {
      #puts "*** DEBUG: $ofilename exists!"
      set ofile_existed 1
      set ofile_fd [open $url/$ofilename a 0600]
      fconfigure $ofile_fd -translation binary -encoding binary
   }   
   
   # append the in file to the out file
   if { [ catch {
        # Open the file, and set up to process it in binary mode. 
      if { [catch {set ifile_fd [open flash:/$ifilename r]} result]} {
         puts "*** DEBUG *** ERROR OPENING infile\n\n$result"
         return -code error $errorInfo
      }   
      fconfigure $ifile_fd -translation binary -encoding binary
   
      # eat the pcap header if we are appending to existing outfile
      if { $ofile_existed } {
         #set addr              [tell  $ifile_fd]
         set pcap_magic_num    [read $ifile_fd 4]
         set pcap_version_maj  [read $ifile_fd 2]
         set pcap_version_min  [read $ifile_fd 2]
         set pcap_timezone     [read $ifile_fd 4]
         set pcap_sigfigs      [read $ifile_fd 4]
         set pcap_snaplen      [read $ifile_fd 4]
         set pcap_network      [read $ifile_fd 4]
      }
         
   
      while { ! [ eof $ifile_fd ] } {           
         # Record the seek address. Read 4096 bytes from the file.
         set addr [ tell $ifile_fd ]
         set s    [read $ifile_fd 4096]
         puts -nonewline $ofile_fd $s  
      } 
    } err ] } {
       catch { ::close $ifile_fd } {
          return -code error $err 
       }   
    }      
   
   if {  [string equal $ifile_fd "NULL"] != $TRUE } {
      if { [catch {close $ifile_fd} result] } {
         puts "*** DEBUG error closing infile:  $result"
      }   
   }   
   if { [string equal $ofile_fd "NULL"] != $TRUE } {
      if { [catch {close $ofile_fd} result] } {
         puts "*** DEBUG error closing outfile:  $result"
      }   
   } 
   
   # delete the in file
   if {[catch {cli_exec $cli(fd) "delete /force $url/$ifilename"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }   
   

   
   #---- cli close ----
   cli_close $cli(fd) $cli(tty_id) 


} ; # end proc ConcatenatePcap



proc ExportCapBuffer { capbuf_name url } { 
   set url [string trim $url "/"]
   
   set ifilename     "tmp.pcap"
   set ofilename     "export.pcap"
   set ifile_fd      "NULL"
   set ofile_fd      "NULL"
   set FALSE         0
   set TRUE          1
   
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
   if {[catch {cli_exec $cli(fd) "monitor capture buffer $capbuf_name export $url/$ifilename"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }      
   
   if { ![file exists $url/$ofilename] } {
      #puts "*** DEBUG: $ofilename does not exist!"
      set ofile_existed 0
      set ofile_fd [open $url/$ofilename w 0600]
      fconfigure $ofile_fd -translation binary -encoding binary
   } else {
      #puts "*** DEBUG: $ofilename exists!"
      set ofile_existed 1
      set ofile_fd [open $url/$ofilename a 0600]
      fconfigure $ofile_fd -translation binary -encoding binary
   }   
   
   # append the in file to the out file
   if { [ catch {
        # Open the file, and set up to process it in binary mode. 
      if { [catch {set ifile_fd [open flash:/$ifilename r]} result]} {
         puts "*** DEBUG *** ERROR OPENING infile\n\n$result"
         return -code error $errorInfo
      }   
      fconfigure $ifile_fd -translation binary -encoding binary
   
      # eat the pcap header if we are appending to existing outfile
      if { $ofile_existed } {
         #set addr              [tell  $ifile_fd]
         set pcap_magic_num    [read $ifile_fd 4]
         set pcap_version_maj  [read $ifile_fd 2]
         set pcap_version_min  [read $ifile_fd 2]
         set pcap_timezone     [read $ifile_fd 4]
         set pcap_sigfigs      [read $ifile_fd 4]
         set pcap_snaplen      [read $ifile_fd 4]
         set pcap_network      [read $ifile_fd 4]
      }
         
   
      while { ! [ eof $ifile_fd ] } {           
         # Record the seek address. Read 4096 bytes from the file.
         set addr [ tell $ifile_fd ]
         set s    [read $ifile_fd 4096]
         puts -nonewline $ofile_fd $s  
      } 
    } err ] } {
       catch { ::close $ifile_fd } {
          return -code error $err 
       }   
    }      
   
   if {  [string equal $ifile_fd "NULL"] != $TRUE } {
      if { [catch {close $ifile_fd} result] } {
         puts "*** DEBUG error closing infile:  $result"
      }   
   }   
   if { [string equal $ofile_fd "NULL"] != $TRUE } {
      if { [catch {close $ofile_fd} result] } {
         puts "*** DEBUG error closing outfile:  $result"
      }   
   } 
   
   # delete the in file
   if {[catch {cli_exec $cli(fd) "delete /force $url/$ifilename"} result]} {
      puts  "*** ERROR: $result \n$errorInfo" 
   }   
   

   
   #---- cli close ----
   cli_close $cli(fd) $cli(tty_id) 
   
} ; # end proc ExportCapBuffer




# ----------------- "main" ----------------------------



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




set pcap_timername   "pcap_timer"
set pcap_cleanup      0
set pcap_timer_id    -1
set mytrigger        $arr_einfo(data1)


if { [catch { foreach {var value} [context_retrieve PCAP] {set $var $value; #puts "\n\n*** DEBUG context_retrieve var = $var  value = $value"; } } result]} {
   puts "*** Error: no context PCAP was retrieved!"

} 
   

puts "Exporting capture buffer $pcap_var_capbuf1 to tmp.pcap ..."
if {[catch { ExportCapBuffer2  $pcap_var_capbuf1 $pcap_var_export_url } result]} {
   error $result $errorInfo 
}

puts "Clearing capture buffer $pcap_var_capbuf1..."
if {[catch { ClearCapBuffer  $pcap_var_capbuf1 } result]} {
   error $result $errorInfo
}


if { [expr [expr $pcap_ctr < $pcap_var_max_capnum] && [expr $pcap_cleanup == 0]]} {
   puts "*** Num Capture Buffers Exported = $pcap_ctr"
   if {[catch { StartCapPoint $pcap_var_cappnt1 } result]} {
      error $result $errorInfo 
   }
   incr pcap_ctr 1
   
   if {[catch {context_save PCAP "pcap_*"} result]} {
      error $result $errorInfo
   }
} else {   
   puts "Stopping capture point $pcap_var_cappnt1 ..."
   if {[catch { StopCapPoint $pcap_var_cappnt1 } result]} {
      error $result $errorInfo 
   }
   
   
   set timer_trigger "triggered by expired timer"
   
   if {![string equal $mytrigger $timer_trigger]} {
      puts "Canceling timer $pcap_timername"
      array set time_remaining [timer_cancel event_id $pcap_timer_id]
   } 
    
}

puts "Concatenating tmp.pcap to export.pcap ..."
if {[catch { ConcatenatePcap   $pcap_var_export_url } result]} {
   error $result $errorInfo 
}

puts "Finished concatenating tmp.pcap to export.pcap ..."



# eeeeeeeeeeeeeeeeeeeeeeeeeeee End of ap_pcap_export.tcl eeeeeeeeeeeeeeeeeeeeee 


