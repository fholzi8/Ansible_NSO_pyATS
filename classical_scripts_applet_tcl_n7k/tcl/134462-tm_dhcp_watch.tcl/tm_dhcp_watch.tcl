::cisco::eem::event_register_timer watchdog time 60 name "dhcp_timer"

if { ![info exists dhcp_file_pattern] } {
    set result "ERROR: Policy cannot be run: variable dhcp_file_pattern has not been set"
    error $result $errorInfo
}

namespace import ::cisco::eem::*
namespace import ::cisco::lib::*

proc run_cli { clist } {
    set rbuf ""

    if {[llength $clist] < 1} {
	return -code ok $rbuf
    }

    if {[catch {cli_open} result]} {
        return -code error $result
    } else {
		array set cliarr $result
    }

    if {[catch {cli_exec $cliarr(fd) "enable"} result]} {
        return -code error $result
    }

    if {[catch {cli_exec $cliarr(fd) "term length 0"} result]} {
        return -code error $result
    }

    foreach cmd $clist {
		if {[catch {cli_exec $cliarr(fd) $cmd} result]} {
            return -code error $result
		}	
		append rbuf $result
    }

    if {[catch {cli_close $cliarr(fd) $cliarr(tty_id)} result]} {
        puts "WARNING: $result"
    }
    return -code ok $rbuf
}

proc run_cli_interactive { clist } {
    set rbuf ""

    if {[llength $clist] < 1} {
	return -code ok $rbuf
    }

    if {[catch {cli_open} result]} {
        return -code error $result
    } else {
	array set cliarr $result
    }

    if {[catch {cli_exec $cliarr(fd) "enable"} result]} {
        return -code error $result
    }

    if {[catch {cli_exec $cliarr(fd) "term length 0"} result]} {
        return -code error $result
    }

    foreach cmd $clist {
        array set sendexp $cmd

	if {[catch {cli_write $cliarr(fd) $sendexp(send)} result]} {
            return -code error $result
	}

	foreach response $sendexp(responses) {
	    array set resp $response

	    if {[catch {cli_read_drain $cliarr(fd)} result]} {
                return -code error $result
	    }

	    if {![regexp $resp(expect) $result]} {
		return -code error $result
	    }

	    if {[catch {cli_write $cliarr(fd) $resp(reply)} result]} {
                return -code error $result
	    }
	}

	if {[catch {cli_read $cliarr(fd)} result]} {
            return -code error $result
	}

	append rbuf $result
    }

    if {[catch {cli_close $cliarr(fd) $cliarr(tty_id)} result]} {
        puts "WARNING: $result"
    }

    return -code ok $rbuf
}

run_cli [list "config t" "file prompt quiet" "end"]

set dhcp_command "show ip dhcp bind | redirect ${dhcp_file_pattern}_tmp"

run_cli [list $dhcp_command]

if { ![file exists $dhcp_file_pattern] } {
    set fd [open "${dhcp_file_pattern}_tmp" "r"]
    set contents [read $fd]
    close $fd
    foreach line [split $contents "\n"] {
	if { ![regexp {^\d} $line] } {
	    continue
	}
	set line [string trimright $line]
	regsub -all {\s\s+} $line {	} line
	set lease [split $line "\t"]
	action_syslog msg "New DHCP lease: IP: [lindex $lease 0], MAC: [lindex $lease 1], Expiration: [lindex $lease 2], Type: [lindex $lease 3]"
    }
} else {
    set cmd "show archive config differences $dhcp_file_pattern ${dhcp_file_pattern}_tmp"
    set output [split [run_cli [list $cmd]] "\n"]
    foreach line $output {
	set line [string trim $line]
	set date "[lindex $line 2] [lindex $line 3] [lindex $line 4] [lindex $line 5] [lindex $line 6]"
	if { [regexp {^\+} $line] } {
	    set line [string trimleft $line "+"]
	    action_syslog msg "New DHCP lease: IP: [lindex $line 0], MAC: [lindex $line 1], Expiration: $date, Type: [lindex $line 7]"
	} elseif { [regexp {^\-} $line] } {
	    set line [string trimleft $line "-"]
	    action_syslog msg "DHCP lease removed: IP: [lindex $line 0], MAC: [lindex $line 1], Expiration: $date, Type: [lindex $line 7]"
	}
    }
}

set cmd0 "del /force $dhcp_file_pattern"
set cmd1 "copy ${dhcp_file_pattern}_tmp $dhcp_file_pattern"
set cmd2 "del /force ${dhcp_file_pattern}_tmp"
run_cli [list $cmd0 $cmd1 $cmd2 "config t" "no file prompt quiet" "end"]
