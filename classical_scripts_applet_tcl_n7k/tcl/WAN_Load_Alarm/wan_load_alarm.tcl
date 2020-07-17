::cisco::eem::event_register_timer watchdog name wan_load_timer time $wan_load_interval queue_priority low nice 1

###############################################################################################################
#
#  Revision #          :  1.5
#  Last Updated        :  March 11, 2008
#  Author/Contributor  :  David Lin, dalin@cisco.com
#
#  Description         :  This EEM Tcl script will send an alarm via syslog & email if the WAN link specified
#                         exceeds a specified load (wan_load_threshold) for more than a specified duration of time
#                         (wan_load_duration). This script takes samples of the txload/rxload in the output of
#                         'show interface' at specified intervals (wan_load_interval) to calculate the
#                         overall average of each over the specified duration (wan_load_duration).
#
#                         An example use case would be to send an alarm when the link load of an wan interface
#                         exceeds 50% for more than 1 hour where the wan_load_interface may be GigabitEthernet0/1,
#                         wan_load_interval = 600 secs, wan_load_duration = 3600 secs and wan_load_threshold
#                         = 128 (128/255 * 100 > 50%).
#
#  Requirements        :  -EEM wan load alarm env variables
#                         event manager environment wan_load_interface <interface>
#                         event manager environment wan_load_interval  <interval>  (in seconds)
#                         event manager environment wan_load_duration  <duration>  (in seconds)
#                         event manager environment wan_load_threshold <threshold> (1-255 out of 255)
#                         event manager environment wan_load_history_outfile <filename & location to store output>
#
#                         Example: event manager environment wan_load_interface GigabitEthernet0/1
#                                  event manager environment wan_load_interval 600
#                                  event manager environment wan_load_duration 3600
#                                  event manager environment wan_load_threshold 128
#                                  event manager environment wan_load_history_outfile flash:wan_load_history_outfile.dat
#
#                         -EEM env variables-    
#                         event manager environment _email_server <your-mailserver-ipaddress or dns-name>
#                         event manager envrionment _email_from <your-email-from-address>
#                         event manager environment _email_to <your-email-to-address>
#
#
#                         Example: event manager environment _email_server 10.10.10.10
#                                  event manager environment _email_from router-123@cisco.com
#                                  event manager environment _email_to noc@cisco.com
#
#                         -EEM trigger-
#                         This script will run every wan_load_interval and generate a syslog/email notification
#                         when either the txload or rxload of specified interface exceeds wan_load_threshold
#                         and the specified wan_load_duration time requirement has been met.
#
#                         -EEM action-
#                         Generates both a syslog and email notification
#
#  Cisco Products tested :   C2821
#
#  Cisco IOS Version tested :   12.4(15)T
#
###############################################################################################################


#
# Namespace imports
#
namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

#--- Check required environment variable(s) has been defined
if {![info exists wan_load_interface]} {
    set result "EEM Policy Error: variable wan_load_interface has not been set"
    error $result $errorInfo
}

if {![info exists wan_load_interval]} {
    set result "EEM Policy Error: variable wan_load_interval has not been set"
    error $result $errorInfo
}

if {![info exists wan_load_duration]} {
    set result "EEM Policy Error: variable wan_load_duration has not been set"
    error $result $errorInfo
}

if {![info exists wan_load_threshold]} {
    set result "EEM Policy Error: variable wan_load_threshold has not been set"
    error $result $errorInfo
}

if {![info exists wan_load_history_outfile]} {
    set result "EEM Policy Error: variable wan_load_history_outfile has not been set"
    error $result $errorInfo
}

if {![info exists _email_server]} {
    set result "EEM Policy Error: variable _email_server has not been set"
    error $result $errorInfo
}

if {![info exists _email_to]} {
    set result "EEM Policy Error: variable _email_to has not been set"
    error $result $errorInfo
}

if {![info exists _email_from]} {
    set result "EEM Policy Error: variable _email_from has not been set"
    error $result $errorInfo
}

#-------------------   hostname      -------------------
set routername [info hostname]


#
#-------------------   " cli open"   -------------------
#
if [catch {cli_open} result] {
  error $result $errorInfo
} else {
  array set cli $result
}

#--------------- end of  "cli open"   -------------------

#
#----------------------- "show commands" ----------------
#
  if [catch {cli_exec $cli(fd) "enable"} result] {
    error $result $errorInfo
  }

  

#---------------------- end of show commands ------------

#---------------- prime counters -------------------
set wan_samples [ expr $wan_load_duration / $wan_load_interval ]
set wan_load_percent [ expr $wan_load_threshold * 100 / 255 ]

#---------------- end of prime counters -------------------

#
#----------------------- "enable" ----------------------
#
  if [catch {cli_exec $cli(fd) "enable"} result] {
    error $result $errorInfo
  }

#-------------- capture txload/rxload output to file  --------------

# Prepare to write line to the history file

#action_syslog msg "Writing WAN load history file to $wan_load_history_outfile"

if [catch {cli_exec $cli(fd) "show int $wan_load_interface | inc txload"} result] {
    error $result $errorInfo
}
set cmd_output $result

# Open file
if [catch {open $wan_load_history_outfile a+} result] {
    error $result
}
set fileD $result


# Write command output

puts $fileD $cmd_output

# Close file
close $fileD

#-------------- end of capture txload/rxload output to file  --------------



#------- fetch txload from wan_load_history_outfile.dat file

#sample output of wan_load_history_outfile.dat file
#
#c2821-1#more wan_load_history_outfile.dat
#     reliability 255/255, txload 1/255, rxload 1/255
#c2821-1#
#     reliability 255/255, txload 1/255, rxload 1/255
#c2821-1#

if [catch {cli_exec $cli(fd) "more $wan_load_history_outfile"} result] {
    error $result $errorInfo
}  
set history_file $result

# Fetch txload
set txload_total 0.0
for { set i 3 } { $i < [expr [llength $history_file] - 1 ] } { incr i 7 } {
   regexp {.+?txload (.+?)\/255} $history_file match txload
   set txload_total [ expr $txload_total + $txload ]
#   puts "txload total is $txload_total"
}  

set txload_avg [ expr $txload_total / $wan_samples ]
#puts "txload average is $txload_avg"


# Fetch rxload

set rxload_total 0.0
for { set i 5 } { $i < [expr [llength $history_file] - 1 ] } { incr i 7 } {
   regexp {.+?rxload (.+?)\/255} $history_file match rxload
   set rxload_total [ expr $rxload_total + $rxload ]
#   puts "rxload total is $rxload_total"
}  

set rxload_avg [ expr $rxload_total / $wan_samples ]
#puts "rxload average is $rxload_avg"


#----------------- define trigger -----------------------

set present_sample [ expr [llength $history_file] / 7]

if { $present_sample >= $wan_samples && ($txload_avg > $wan_load_threshold || $rxload_avg > $wan_load_threshold) } {


# Send mail 
# Create mail form
  set body [format "Mailservername: %s" "$_email_server"]
  set body [format "%s\nFrom: %s" "$body" "$_email_from"]
  set body [format "%s\nTo: %s" "$body" "$_email_to"]
  set _email_cc ""
  set body [format "%s\nCc: %s" "$body" ""]
  set body [format "%s\nSubject: %s\n" "$body" "Router $routername interface $wan_load_interface average load exceeded!"]

  set body [format "%s\n%s" "$body" "Router $routername"]
  set body [format "%s\n%s" "$body" "Interface $wan_load_interface"]
  set body [format "%s\n%s" "$body" "Average load exceeded $wan_load_threshold/255 (>$wan_load_percent percent) over $wan_load_duration seconds."]
  set body [format "%s\n\n%s" "$body" "Average txload = $txload_avg/255"]
  set body [format "%s\n%s" "$body" "Average rxload = $rxload_avg/255"]
  set body [format "%s\n\n%s" "$body" "--- Raw Output ---"]
  set body [format "%s\n\n%s" "$body" "$history_file"]
  
  
  if [catch {smtp_send_email $body} result] {
    action_syslog msg "smtp_send_email: $result"
  }
  
  action_syslog msg "Interface $wan_load_interface average load exceeded $wan_load_percent percent over $wan_load_duration seconds."
  action_syslog msg "WAN load alarm e-mail notification sent!"
#------------------ end of send mail --------------------

# Purge data file
  if [catch {cli_exec $cli(fd) "del /force $wan_load_history_outfile"} result] {
    error $result $errorInfo
  }

# Scenario where txload/rxload do not exceed threshold over specified time.  Reset and purge file for next window. 
} elseif { $present_sample >= $wan_samples } {
  if [catch {cli_exec $cli(fd) "del /force $wan_load_history_outfile"} result] {
    error $result $errorInfo
  }
    
} else {
#  puts "No conditions met; exit gracefully"  
 }


#
#--------------------- cli close ------------------------
#
  cli_close $cli(fd) $cli(tty_id)

# eeeeeeeeeeeeeeeeeeeeeeeeeeee    End of wan_load_alarm.tcl eeeeeeeeeeeeeeeeeeeeee 
