#	revision 1.1 2011-09-20 by user
#	initial revision
#
#	description:	Workaround for displaying syntax errors with do command in exec mode
#
#
#
#ios config:
#
#           * download the file into flash:do.tcl
#           * configure alias exec do tclsh flash:do.tcl
#
#


puts [exec $argv]