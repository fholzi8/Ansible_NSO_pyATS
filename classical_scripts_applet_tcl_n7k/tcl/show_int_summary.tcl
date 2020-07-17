::cisco::eem::event_register_timer cron name show_int_summary.tcl cron_entry "* * * * *" maxrun 55


namespace import ::cisco::eem::*
namespace import ::cisco::lib::*
# Open the CLI
if [catch {cli_open} result] {
   error $result $errorInfo
} else {
    array set cli1 $result
}

# Go into enable mode
if [catch {cli_exec $cli1(fd) "en"} result] {
    error $result $errorInfo
}

if [catch {cli_exec $cli1(fd) "show interface summary" } summary ] {
        error $summary $errorInfo
}

set lines [split $summary "\n"]
# If SUMCTXT exists read it, if not create it.
if { [catch {context_retrieve SUMCTXT counter} result] } {
    array set counter [list]
} else {
    array set counter $result
}
# If  counters do not currently exist in SUMCTXT create the counter with present value. 
foreach line $lines {

    if  [regexp {\*?\s?([a-zA-Z0-9/]+)\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+} $line match interface counterINT] {
          if { ! [info exists counter($interface)] } {
			set OQD $counterINT            
			set counter($interface) $counterINT
        }
    }
}

# Compare current counter to what is currently stored in SUMCTXT .
# Get current OQD counter
if [catch {cli_exec $cli1(fd) "show interface summary" } summary ] {
        error $summary $errorInfo
}

set lines [split $summary "\n"]
foreach line $lines {

    if  [regexp {\*?\s?([a-zA-Z0-9/]+)\s+\d+\s+\d+\s+\d+\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+} $line match interface OQD] {


   set currentOQD $OQD
   set previousOQD $counter($interface)

    if { $OQD != $previousOQD } {
        action_syslog msg "DROP_PKT $interface previous OQD $previousOQD current OQD $currentOQD"
    set counter($interface) $OQD
}}
    #Set pre decrypted count to current decrypted count. 
#    set counter($interface) $OQD
}

if { [catch {context_save SUMCTXT counter} result] } {
    error $result $errorInfo
}
