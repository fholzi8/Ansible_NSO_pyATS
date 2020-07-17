# Tcl package index file
# the variable $dir must contain the
# full path name of this file's directory.

set dir [file dirname [info script]]
package ifneeded dns 1.3.1 [list source [file join $dir dns.tcl]]
package ifneeded ip 0.6 [list source [file join $dir ip.tcl]]