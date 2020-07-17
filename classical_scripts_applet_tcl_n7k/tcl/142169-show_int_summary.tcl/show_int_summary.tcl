::cisco::eem::event_register_timer cron name show_int_summary.tcl cron_entry "* * * * *" maxrun 55


# =====================================================================
# =====================================================================
##-
# Copyright (c) 2010 Dan Frey <dafrey@cisco.com>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY

# Date     : Jan 28, 2013
# Version  : 1.0 - EEM
#
# Installation Steps
# Place this file on the router media, typically the flash drive.
# Execute these two CLI commands in global config mode:
#       event manager directory user policy "flash:/"
#       event manager policy <filename>  type user

######################################################################
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
