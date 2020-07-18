#!/bin/bash

scriptpath=/opt/scripts/switch-scripts

#for script in $scriptpath/check_*.pl; do
#	$script -C scriptpath/host_config
#done

$scriptpath/check_crc_error.pl -C $scriptpath/host_config 
$scriptpath/check_collision_error.pl -C $scriptpath/host_config 
$scriptpath/check_frame_error.pl -C $scriptpath/host_config 
$scriptpath/check_giants_error.pl -C $scriptpath/host_config 
$scriptpath/check_runts_error.pl -C $scriptpath/host_config 
$scriptpath/check_overrun_error.pl -C $scriptpath/host_config 
$scriptpath/check_ignored_error.pl -C $scriptpath/host_config 
