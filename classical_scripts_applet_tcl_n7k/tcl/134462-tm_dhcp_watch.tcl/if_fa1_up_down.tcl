#	revision 0.9 2011-09-26 by user
#	initial revision
#
#	description:	This script disable an interface and reenable it after an one hour
#
#	ios config:
#			* download the file into flash:.tcl/if_fa1_up_down.tcl
#		  * configure alias exec if_fa1_up_down tclsh flash:.tcl/if_fa1_up_down.tcl for example
#
#			**invoke with if_fa1_up_down
#
# Syslog
::cisco::eem::event_register_syslog occurs 1 pattern "\%LINEPROTO-5-UPDOWN: Line protocol on Interface FastEthernet1, changed state to down" maxrun_sec 90

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

  if [catch {cli_exec $cli(fd) "interface FastEthernet1"} result] {
    error $result $errorInfo
  }
  set show_fa1 $result
  
  if [catch {cli_exec $cli(fd) "shutdown"} result] {
    error $result $errorInfo
  }
  set show_shutdown $result
  
  
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
  set body [format "%s\nSubject: %s\n" "$body" "Shutdown HiPath-Switchport on  $routername"]

  set body [format "%s\n%s" "$body" "<html>\n<head>\n<title>Shutdown HiPath-Switchport</title>\n</head>"]
  set body [format "%s\n%s" "$body" "<body style=\"font-family: verdana; font-size: 11px; color: black;\"><center><h3>Shutdown HiPath-Switchport</h3>"]
	set body [format "%s\n%s" "$body" "<table>"]
	set body [format "%s\n%s" "$body" "On $routername the HiPath-Switchport was shut down"]
	set body [format "%s\n%s" "$body" "$show_fa1"]
	set body [format "%s\n%s" "$body" "$show_shutdown"]
	set body [format "%s\n%s" "$body" "</table><br>"]
	
	
	if [catch {smtp_send_email $body} result] {
  	  action_syslog msg "smtp_send_email: $result"
  }

 after 15000
 
action_syslog msg "E-mail sent!"
#------------------ end of send mail --------------------

  after 15000

#
#--------------------- cli close ------------------------
#
  cli_close $cli(fd) $cli(tty_id)
  

