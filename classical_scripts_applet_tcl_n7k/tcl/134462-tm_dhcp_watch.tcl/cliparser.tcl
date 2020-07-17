::cisco::eem::event_register_cli sync yes occurs 1 pattern "^interface (.*)$|^router (.*)$"

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

array set evtData [event_reqinfo]
set _cli_msg $evtData(msg)

#
# INTERFACE CONFIGURATION COMMAND
# remember interface which is being configured
#
if { [ regexp -nocase {^interface (\S+)} $_cli_msg ignore intf] } {
  appl_reqinfo key "cmd"
  appl_setinfo key "cmd" data "show running interface $intf"
  exit 1
}

#
# ROUTER CONFIGURATION COMMAND
# remember routing protocol being configured
#
if { [ regexp -nocase {^router (.*)$} $_cli_msg ignore rtr] } {
  appl_reqinfo key "cmd"
  set rtr [string trim $rtr]
  appl_setinfo key "cmd" data "show running | section router $rtr"
  exit 1
} 