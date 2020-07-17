::cisco::eem::event_register_syslog occurs 1 pattern ".*CTS-6-PORT_UNAUTHORIZED.*" maxrun 200
#	revision 0.1 2013-10-14 by fholzapfel
#	
#	description:	This script reactivate MACSEC port
#	ios config:
#			* download the file into flash:.tcl/macsec_reactivate.tcl
#			* configure event manager environment _syslog_pattern .*CTS-6-PORT_UNAUTHORIZED.* 
#			* configure event manager directory user policy "flash:.tcl/"
#
#
# _syslog_pattern (mandatory)        - A regular expression pattern match string 
#                                      that is used to compare syslog messages
#                                      to determine when policy runs 
# Example: _syslog_pattern             .*CTS-6-PORT_UNAUTHORIZED.* 
#


namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

# 1. query the information of latest triggered eem event
array set arr_einfo [event_reqinfo]

if {$_cerrno != 0} {
 set result [format "component=%s; subsys err=%s; posix err=%s;\n%s" \
	$_cerr_sub_num $_cerr_sub_err $_cerr_posix_err $_cerr_str]
 error $result 
}

set msg $arr_einfo(msg)

if {[regexp {.*\((Gi.*/0/1)\).*} $msg \
	match intf_match]} {
 }

# 2. execute the user-defined config commands

if [catch {cli_open} result] {
 error $result $errorInfo
} else {
 array set cli1 $result
} 

if [catch {cli_exec $cli1(fd) "en"} result] {
 error $result $errorInfo
} 

if [catch {cli_exec $cli1(fd) "conf t"} result] {
 error $result $errorInfo
} 

if [catch {cli_exec $cli1(fd) "interface $intf_match"} result] {
 error $result $errorInfo
}

if [catch {cli_exec $cli1(fd) "shut"} result] {
 error $result $errorInfo
} 
after 5000
if [catch {cli_exec $cli1(fd) "no shut"} result] {
 error $result $errorInfo
} 