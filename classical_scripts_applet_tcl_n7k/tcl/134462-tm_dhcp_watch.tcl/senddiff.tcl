######################################################################################################
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
  if [catch {cli_exec $cli(fd) "enable"} result] {
    error $result $errorInfo
  }

  if [catch {cli_exec $cli(fd) "show archive config differences nvram:/startup-config system:/running-config"} result] {
    error $result $errorInfo
  }
  set show_archive $result
  

#---------------------- end of show commands ------------

	set show_diff [string map {\n <br>} "$show_archive"]
#
#----------------------- "enable" ----------------------
#
  if [catch {cli_exec $cli(fd) "enable"} result] {
    error $result $errorInfo
  }


#
#----------------------- send mail ----------------------
#
# create mail form
  action_syslog msg "Creating mail header..."
  set body [format "Mailservername: %s" "$_email_server"]
  set body [format "%s\nFrom: %s" "$body" "$_email_from"]
  set body [format "%s\nTo: %s" "$body" "$_email_to"]
  set _email_cc ""
  set body [format "%s\nCc: %s" "$body" ""]
  set body [format "%s\n%s" "$body" "MIME-Version: 1.0"]
  set body [format "%s\n%s" "$body" "Content-type: text/html; charset=iso-8859-1"]
  set body [format "%s\nSubject: %s\n" "$body" "Configuration Diff Alert from $routername"]

  set body [format "%s\n%s" "$body" "<html>\n<head>\n<title>Router Change</title>\n</head>"]
  set body [format "%s\n%s" "$body" "<body style=\"font-family: verdana; font-size: 11px; color: black;\"><center><h3>Router-Change</h3>"]
	set body [format "%s\n%s" "$body" "<table>"]
	set body [format "%s\n%s" "$body" "$show_diff"]
	set body [format "%s\n%s" "$body" "</table><br>"]
  set body [format "%s\n%s" "$body" "<br><br>Verknuepfen mit Config-Item: $routername\n"]
	
	
	
	if [string match "*!No changes were found*" $show_archive] {
		action_syslog msg "No Config Change"
	} else {
	  if [catch {smtp_send_email $body} result] {
  	  action_syslog msg "smtp_send_email: $result"
  	}
  }

action_syslog msg "E-mail sent!"
#------------------ end of send mail --------------------



#
#--------------------- cli close ------------------------
#
  cli_close $cli(fd) $cli(tty_id)

# eeeeeeeeeeeeeeeeeeeeeeeeeeee    End of senddiff.tcl eeeeeeeeeeeeeeeeeeeeee 
