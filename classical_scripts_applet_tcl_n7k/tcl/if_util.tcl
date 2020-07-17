#	revision 0.1 2013-11-18 by fholzapfel 
#	initial revision
#
#	
#event manager applet INTERFACE_TIMER
# event snmp oid 1.3.6.1.2.1.1.3.0 get-type exact entry-op gt entry-val 0 poll-interval 30
# action 1.0 cli command "tclsh bootflash:/.tcl/if_util.tcl"
# 
#   


proc get_envvar { name } {
    set output [string trim [exec "show event manager environment $name"]]
    if { $output != "" && $output != "Environment variable not found" } {
        set val [string trim [lindex [split $output ":"] 1]]
        
        return $val
    }
    
    return ""
}

set val [get_envvar "if_util_intfs"]
if { $val != "" } {
    set iflst [split $val ","]
    set threshold [get_envvar "if_util_threshold"]
    if { $threshold == "" } {
        exit 1
    }
    foreach if $iflst {
        set if [string trim $if]
        set output [exec "show interface $if | inc bits/sec|BW"]
        regexp {input rate (\d+) bits/sec} $output -> ir
        regexp {output rate (\d+) bits/sec} $output -> or
        regexp {BW (\d+) Kbit} $output -> bw
        
        if { ![info exists ir] || ! [info exists or] || ! [info exists bw] } {
            exit 1
        }
                
        set txutil [expr int((${or}.0 / 1000.0) / ${bw}.0 * 100.0)]
        set rxutil [expr int((${ir}.0 / 1000.0) / ${bw}.0 * 100.0)]
        set msg "Interface $if exceeded ${threshold}% utilization threshold: Tx: ${txutil}%, Rx: ${rxutil}%"
        if { $txutil > $threshold || $rxutil > $threshold } {
            #regsub -all {[/\.]} $if "" safe_if
            #cli "config t ; event manager applet ifutil$safe_if ; event counter name ${safe_if}CNT entry-val 0 entry-op gt exit-val 0 exit-op gt ; action 1.0 syslog msg $msg"
            #cli "end"
            #cli "event manager run ifutil$safe_if"
            #cli "config t ; no event manager applet ifutil$safe_if ; end"
            exec "logit $msg"
        }
    }
}