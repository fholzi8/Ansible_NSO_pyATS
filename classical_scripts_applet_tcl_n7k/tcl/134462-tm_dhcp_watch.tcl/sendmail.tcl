###############################################################################################################
#
#  Revision #          :  2.8
#  Last Updated        :  February 6, 2008
#  Author/Contributor  :  David Lin, dalin@cisco.com
#
#  Description         :  This EEM Tcl script serves as a template that can be used when
#                         sending an email notification is needed
#
#
#  Requirements        :  -EEM env variables-    
#                         event manager environment _email_server <your-mailserver-ipaddress or dns-name>
#                         event manager envrionment _email_from <your-email-from-address>
#                         event manager environment _email_to <your-email-to-address>
#
#                         Example: event manager environment _email_server 10.10.10.10
#                                  event manager environment _email_from router-123@cisco.com
#                                  event manager environment _email_to noc@cisco.com
#
#                         -IOS CLI commands-
#                         none
#
#
#                         -EEM trigger-
#                         Manual using "event manager run sendmail.tcl" command line. 
#                         An alias may also be used for ease of use: 
#                         alias exec sendmail event manager run sendmail.tcl
#
#                         -EEM action-
#                         Sends an email message to specified server defined in variable _email_server above
#
#  Cisco Products tested :   1800, 2800, 3800
#
#  Cisco IOS Version tested :   12.4(9)T4
#
###############################################################################################################

# Useful event registration tcl command extensions
# None
#::cisco::eem::event_register_none queue_priority low nice 1 maxrun 600
# Watchdog Timer
#::cisco::eem::event_register_timer watchdog name errimt time $errim_period queue_priority low nice 1
# Syslog
::cisco::eem::event_register_syslog occurs 1 pattern "\%SYS-5-CONFIG_I: Configured" maxrun_sec 90
#::cisco::eem::event_register_syslog occurs 1  pattern .*STANDBY.*STATECHANGE.* maxrun 90 queue_priority low nice 1
# Object Tracking
#::cisco::eem::event_register_track 1 state up queue_priority low nice 1
# Interface
#::cisco::eem::event_register_interface name $intf parameter txload entry_op ge entry_val 192 entry_val_is_increment FALSE queue_priority low nice 1
# Cron Job
#::cisco::eem::event_register_timer cron name test cron_entry "0 * * * *" queue_priority low nice 1 maxrun 20

#
# Namespace imports
#
namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

#--- Check required environment variable(s) has been defined

if {![info exists _email_server]} {
    set result "EEM Policy Error: variable $_email_server has not been set"
    error $result $errorInfo
}

if {![info exists _email_to]} {
    set result "EEM Policy Error: variable $_email_to has not been set"
    error $result $errorInfo
}

if {![info exists _email_from]} {
    set result "EEM Policy Error: variable $_email_from has not been set"
    error $result $errorInfo
}

if {![info exists _email_cc]} {
    set result "EEM Policy Error: variable $_email_cc has not been set"
    error $result $errorInfo
}

#------------------  hostname        -------------------
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
  if [catch {cli_exec $cli(fd) "show archive config differences nvram:/startup-config system:/running-config"} result] {
    error $result $errorInfo
  }
  set show_diff $result
  
#---------------------- end of show commands ------------
#
#----------------------- send mail ----------------------
#
# create mail form
  action_syslog msg "Creating mail header..."
  set body [format "Mailservername: %s" "$_email_server"]
  set body [format "%s\nFrom: %s" "$body" "$_email_from"]
  set body [format "%s\nTo: %s" "$body" "$_email_to"]
  set body [format "%s\nCc: %s" "$body" "$_email_cc"]
  set body [format "%s\nSubject: %s\n" "$body" "Config-Differences from $routername..."]
  set body [format "%s\n\n%s" "$body" "------- Show Diff-Config -------"]
  set body [format "%s\n\n%s" "$body" "$show_diff"]

  if [catch {smtp_send_email $body} result] {
    action_syslog msg "smtp_send_email: $result"
  }

action_syslog msg "E-mail sent!"
#------------------ end of send mail --------------------
#
#--------------------- cli close ------------------------
#
  cli_close $cli(fd) $cli(tty_id)

