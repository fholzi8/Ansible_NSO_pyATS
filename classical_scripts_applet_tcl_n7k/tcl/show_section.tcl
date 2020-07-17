# show_section.tcl
#
# syntax s_i "<regexp>"
#
# Returns: all headers of included lines with <regexp> in the line
# Author: Wyatt Sullivan
# Shameless Plug: http://www.bgp4.us
#
# Revision: 1.1 
#
# Revision History:
#           1.1 - Fixed bug in using | in regexp
#           1.0 - Initial
 
proc s_i {reg_exp} {
 
 set sh_run [exec "sh run"]
 set header "" 
 set final_out ""
 set line ""
 set header ""
 set printed_header 0
 set reg_exp "$reg_exp"
 
 foreach line [regexp -all -line -inline ".*" $sh_run] {
    if {[regexp "(^\[^ ])" $line]} {
       set header $line
       set printed_header 0
    }
    set cur_line [regexp -inline $reg_exp $line]
    set is_not_cur_line [regexp $cur_line ""]
    if { $is_not_cur_line == 0 } {
       if {![string equal $cur_line $header] && $printed_header == 0} {
          #puts $header
          append final_out $header
          set printed_header 1
       }  
       if {![string equal $cur_line $header]} { 
 
          #puts $cur_line
          append final_out $line
       }
    } 
  }
 
set hits [regsub -all "{|}" $final_out "" final_out] 
 
return  $final_out
}