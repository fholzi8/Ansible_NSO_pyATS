########################################################################################
# 
# ios installation:
#
#     download the file cnc.tcl into flash:cnc.tcl
#     configure a alias:  alias exec cnc tclsh flash:cnc.tcl     
#     or over tftp
#     configure a alias:  alias exec cnc tclsh tftp://IP_of_TFTP_SERVER/tcl/cnc.tcl     
#
#     execute with: cnc -l port 
#                   cnc -x port
#                   cnc -e port
#                   cnc -f port	filename
#                   cnc -s targetIP port	
#
# cnc   cisco net cat 
# 
# 
# cnc.tcl -l port    		listen port 
# cnc.tcl -x port    		execute port 
# cnc.tcl -e port    		echo server 
# cnc.tcl -f port filename	receive form a port and write to filename 
# cnc.tcl -f 0 filename		receive form stdin and write to filename 
# cnc.tcl -s tagetIP port   	send  targetip port 
# cnc.tcl -v     		show version 
# cnc.tcl -h     		show help # 
# only for some demonstrations and proof of concept.
# and i know, very buggy, incompletely 
#
########################################################################################
#
# known bugs
# - ignore EOF in -l option  (better since 0.05 but still buggy)
# - crash router in -s option
# - -e option, some problems with CR/NL 
#
		
proc ShowVersion {} {
puts "cnc.tcl version 0.10"
return;
}
#n)2W3E:wk*8Y
# CncHelp
#
proc CncHelp {} {
puts "cnc.tcl -l port             / listen on port"
puts "cnc.tcl -x port             / listen on port and execute command"
puts "cnc.tcl -e port             / listen on port and echo"
puts "cnc.tcl -f port filename    / listen on port and create a file with filename"
puts "cnc.tcl -f 0    filename    / listen stdin and create a file with filename"
puts "cnc.tcl -s port ipaddress   / send to ipaddress port"
puts "cnc.tcl -v                  / show version"
puts "cnc.tcl -h                  / show help"
return;
}
#
# ShowDummy
#		
proc ShowDummy {} {
puts "comming soon !(maybee)"
return;
}
########################################################################################
# 
# Additional general function 
# maybe not used now, but used for debugging 
#
# ConvertStringToHex
#
proc ConvertStringToHex str {
  binary scan $str H* hex
  return $hex
 }
#
# ConvertHexToString
#
proc ConvertHexToString hex {
  foreach c [split $hex ""] {
   if {![string is xdigit $c]} {
    return "#invalid $hex"
   }
  }
  binary format H* $hex
}
#
# simple ip address test
#
proc isIP {str} {
    set ipnum1 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
    set ipnum2 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
    set ipnum3 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
    set ipnum4 {\d|[1-9]\d|1\d\d|2[0-4]\d|25[0-5]}
    set fullExp {^($ipnum1)\.($ipnum2)\.($ipnum3)\.($ipnum4)$}
    set partialExp {^(($ipnum1)(\.(($ipnum2)(\.(($ipnum3)(\.(($ipnum4)?)?)?)?)?)?)?)?$}
    set fullExp [subst -nocommands -nobackslashes $fullExp]
    set partialExp [subst -nocommands -nobackslashes $partialExp]
       if [regexp -- $fullExp $str] {
          return 1
       } else {
          return 0
       }
}
#
# simple port check ( 1 - 65535 ) 
#
proc isPORT {dport} {
  set isPORT "1"
  if {[string is integer $dport] == 1} then {
     if {$dport > 65535} then {set isPORT "0"}
     if {$dport < 1}   then {set isPORT "0"}
    } else { set isPORT "0" }
  return $isPORT
}

########################################################################################
# 
# CncListen Section
#
# CncListen port
#
proc CncListen {tcpport} {
global events
	set s [socket -server Accept $tcpport]
	vwait events; 						# wait, util event is set to 1
	return;
}
#
# Accept
#
proc Accept {sock addr port} {
global events
#  puts "Accept $sock from $addr port $port" 
#  fconfigure $sock -buffering line
  fileevent $sock readable [list ListHandler $sock]		
}
#
# ListHandler 
#
proc  ListHandler {sock} {
global events
  set l [gets $sock]
  if {[eof  $sock]} {
	set events 1
    } else { 
    puts "$l"
   }
}
########################################################################################
#
# CncSend Section
#
# CncSend   (crash the router !!!)
# 
proc CncSend {tcpport destip} {
	puts "Send on Port: $tcpport IP: $destip"
	set s [socket $destip $tcpport];
	while {1} {
		set trans [gets stdin]
		puts $s $trans
		flush $s
		}
	return	
}
########################################################################################
#
# CncExec Section 
#
# CncExec (Buggy)
#
proc CncExec {destport} {
	set s [socket -server CallBack $destport]
	vwait var
	close $s
	return;
	}
#
# CallBack
#
proc CallBack {sock addr port} {
fconfigure $sock -translation lf -buffering line

set answer [exec "sh ver | inc IOS\n"]
puts $sock $answer
set answer [exec "sh priv\n"]
puts $sock $answer
puts $sock " "
puts $sock "Enter IOS command:"
fileevent $sock readable [list ExecEcho $sock]
}
#
# ExecEcho  
#       Send back Output of exec
#
proc ExecEcho {sock} {
global var
	if {[eof $sock] || [catch {gets $sock line}]} {
	} else {
	set response [exec "$line"]
	puts $sock $response
	}
}

#
#
########################################################################################
#
# Echo Server Section
#
# EchoServer
#
proc CncEcho {port} {
    set s [socket -server EchoAccept $port]
    vwait forever
}
#
# EchoAccept
#
proc EchoAccept {sock addr port} {
    global echotxt

    # Record the client's information

    puts "Accept $sock from $addr port $port"
    set echotxt(addr,$sock) [list $addr $port]

    # Ensure that each "puts" by the server
    # results in a network transmission

    fconfigure $sock -buffering line

    # Set up a callback for when the client sends data

    fileevent $sock readable [list SendEcho $sock]
}
#
# SendEcho 
#
proc SendEcho {sock} {
    global echotxt

    # Check end of file or abnormal connection drop,
    # then echotxt data back to the client.

    if {[eof $sock] || [catch {gets $sock line}]} {
	close $sock
	puts "Close $echotxt(addr,$sock)"
	unset echotxt(addr,$sock)
    } else {
	puts $sock $line
    }
}
#
########################################################################################
# 
# CncFileR Section
#
proc CncFileR {tcpport file} {
global events	
global writefilename 
	set writefilename $file
	puts "Creating:$writefilename"
	set s [socket -server FileAccept $tcpport ]
	vwait events; 						# wait, util event is set to 1
        puts "\nFile $writefilename successfully written"
	return;
}
#
# FileAccept
#
proc FileAccept {sock addr port } {
global events
global writefilename
  puts "Accept $sock from $addr port $port" 
#  fconfigure $sock -buffering line
  puts "Creating File:$writefilename"
  catch {set channel [open "$writefilename" w+]} {puts "File Opener failed"}
  close $channel
#  fconfigure $sock -blocking 1 -buffering full
  fileevent $sock readable [list GetFile $sock]
}
#
# GetFile
#
proc GetFile {sock} {
global events
global writefilename
  puts -nonewline stdout "."
  flush stdout
  set l [gets $sock]
  if {[eof  $sock]} {
	set events 1
    } else { 
    set channel [open "$writefilename" a+]
    puts $channel "$l"
    close $channel
   }
}





########################################################################################
# 
# CncFileRS Section
#
proc CncFileRS {file} {
        set writefilename $file
        puts "Send File (end with CRTL-c)\n"
        set channel [open "$writefilename" w]
        while {1} {
                set l [gets stdin]
                if {[eof stdin]} {
                        puts "File $writefilename successfully written\n";
                        return;
			flush $channel
                        }
                puts $channel "$l"
                }
}



########################################################################################
# 
# main Section
#
#
if { $::argc > 0 } {
	 
	set arg [lindex $argv 0]
	if { ![string compare $arg "-l"] } { 
	      	if { $::argc != 2 } {
		puts "Missing Port ";
		return;
		}
		set port [lindex $argv 1]
		if {! [isPORT $port]}  { puts "cnc: Error: Invalid Port $port"; CncHelp;return  }
		catch { CncListen $port }
	   }
	if { ![string compare $arg "-e"] } { 
	      	if { $::argc != 2 } {
		puts "Missing Port ";
		return;
		}
		set port [lindex $argv 1]
		if {! [isPORT $port]}  { puts "cnc: Error: Invalid Port $port"; CncHelp;return  }
		CncEcho $port 
	   }
	if { ![string compare $arg "-s"] } { 
           	if { $::argc != 3 } {
		puts "Missing Port or IP-address ";
		return;
		}
		set port [lindex $argv 1]
		set ip [lindex $argv 2]
		if {! [isIP $ip]}  { puts "cnc: Error: Invalid IP $ip"; CncHelp;return  }
		if {! [isPORT $port]}  { puts "cnc: Error: Invalid Port $port"; CncHelp;return  }
		CncSend $port $ip
	   }	
	if { ![string compare $arg "-x"] } {  
	      	if { $::argc != 2 } {
		puts "Missing Port ";
		return;
		}
		set port [lindex $argv 1]
		if {! [isPORT $port]}  { puts "cnc: Error: Invalid Port $port"; CncHelp;return  }
		CncExec $port 
	   }
	if { ![string compare $arg "-f"] } { 
           	if { $::argc != 3 } {
		puts "Missing Port or filename ";
		return;
		}
		set port [lindex $argv 1]
		set filename [lindex $argv 2]
		if { $port == 0 } {
			CncFileRS $filename
			} else { 
			if {! [isPORT $port]}  { puts "cnc: Error: Invalid Port $port"; CncHelp;return  }
			CncFileR $port $filename
		        }
	   }
#
# Version and Help Section
#
	if { ![string compare $arg "-v"] } { ShowVersion;return }
	if { ![string compare $arg "-h"] } { CncHelp;return }
        if { [string compare $arg ""]} { break; }
#
# no correct arguments
#
	CncHelp;
        puts "cnc: Error: Wrong command line argument!";
	} else {
	puts "cnc: Error: No command line argument!";
	CncHelp;
	return;
}
