::cisco::eem::event_register_none

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

set cmda [appl_reqinfo key "cmd"]

if { [ lindex $cmda 0 ] == "data" } {
  set cmd [ lindex $cmda 1 ]
  appl_setinfo key "cmd" data $cmd
}

if {[catch {cli_open} result]} {
  puts stderr "%CLICONFIG-3-EXEC: CLI OPEN failed ($result)"
  exit 0
}

array set cfd $result

if {[catch {cli_exec $cfd(fd) "enable"} result]} {
  puts stderr "%CLICONFIG-3-EXEC: Cannot execute 'enable' command ($result)"
  exit 0
}

if {[catch {cli_exec $cfd(fd) $cmd} result]} {
  puts stderr "%CLICONFIG-3-EXEC: Cannot execute $cmd ($result)"
  exit 0
}

puts $result
catch {cli_close $cfd(fd) $cfd(tty_id)}
exit 0 