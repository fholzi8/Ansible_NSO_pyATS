#	revision 1.1 2011-09-20 by user
#	initial revision
#
#	description:	The script displays top CPU processes every 5 seconds
#
#
#
#ios config:
#
#           * download the file into flash:top.tcl
#           * configure alias exec top tclsh flash:top.tcl
#
#           
#
#Usage: 
#
#						top [ 5sec | 1min | 5min ] 
#


set IOS [string equal $tcl_platform(os) "Cisco IOS"];

if { $IOS } { 
  exec "terminal international"; 
  exec "terminal escape 3";
}

set arg [lindex $argv 0];
if { [string length $arg] == 0 } { set arg "5sec" } ;
if { [lsearch -exact { 5sec 1min 5min } $arg] < 0 } {
  puts {Usage: top [5sec|1min|5min]};
  return 0;
}

fconfigure stdout -buffering none;

while {1} {
  set lines [split [exec "show process cpu sorted $arg | exclude 0.00% +0.00% +0.00%"] "\n"];

  puts -nonewline "\033\[2J\033\[H";
  for { set lc 1 } { $lc < 23 } { incr lc } {
    set curline [lindex $lines $lc];
    if { [string length $curline] > 0 } { puts "$curline"; }
  }
  puts -nonewline "\nBreak with Ctrl/C --> ";
  after 5000;
}
