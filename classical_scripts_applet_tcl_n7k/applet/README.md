Applets or also known as EEM


event manager environment _email_server 10.11.12.16
event manager environment _email_to noc@company.com
event manager environment _email_from device@company.com
event manager environment if_util_intfs "gi1/3,po1,po3,po5,po10,po14,po20,po24,po28,po30,po34,po41,po43,po60"
event manager environment if_util_threshold "90"
event manager directory user policy "bootflash:/.tcl/"

event manager applet 8021AE_RZ1_Reinit
 event syslog pattern "Port unauthorized for int(gi1/3)"
 action 0.1 cli command "enable"
 action 0.2 cli command "int gi1/3"
 action 0.3 cli command "shut"
 action 0.4 cli command "no shut"
 action 0.5 cli command "exit"
 action 0.6 syslog msg "Authorization for RZ1-Port started"
 action 1.0 cli command "exit"
 
 
 
 
event manager applet RIB_MONITOR
 event routing network 0.0.0.0/0 type modify
 action 1.0 set MSG "Route changed: Type $_routing_type, Network: $_routing_network, Mask/Prefix: $_routing_mask, Protocol: $_routing_protocol, GW: $_routing_lastgateway, Interface: $_routing_lastinterface"
 action 2.0 syslog priority alerts msg "$MSG"
 action 3.0 snmp-trap strdata "$MSG"
 action 4.0 info type routername
 action 5.0 mail server "$_email_server" to "$_email_to" from "$_email_from" subject "Routing Table Change" body "$MSG"
 
 
event manager applet auto-update-cdp-port-description authorization bypass
description "Auto-update port-description based on CDP neighbors info"
action 0.0 comment "Event line regexp: Deside which interface to auto-update description on"
event neighbor-discovery interface regexp .*Ethernet.*$ cdp add
action 1.0 comment "Verify CDP neighbor to be Switch or Router"
action 1.1 regexp "(Switch|Router)" $_nd_cdp_capabilities_string
action 1.2 if $_regexp_result eq 1
action 2.0 comment "Trim domain name"
action 2.1 regexp "^([^\.]+)\." $_nd_cdp_entry_name match host
action 3.0 comment "Convert long interface name to short"
!action 3.1 string range $_nd_port_id 0 1
action 3.1 string first "Ethernet" "$_nd_port_id"
action 3.2 if "$_string_result" eq 7
action 3.21 string replace "$_nd_port_id" 0 14 "Gi"
action 3.3 elseif "$_string_result" eq 10
action 3.31 string replace "$_nd_port_id" 0 17 "Te"
action 3.4 elseif "$_string_result" eq 4
action 3.41 string replace "$_nd_port_id" 0 11 "Fa"
action 3.5 end
action 3.6 set int "$_string_result"
action 4.0 comment "Check old description if any, and do no change if same host:int"
action 4.1 cli command "enable"
action 4.11 cli command "config t"
action 4.2 cli command "do show interface $_nd_local_intf_name | incl Description:"
action 4.21 set olddesc "<none>"
action 4.22 set olddesc_sub1 "<none>"
action 4.23 regexp "Description: ([a-zA-Z0-9:/\-]*)([a-zA-Z0-9:/\-\ ]*)" "$_cli_result" olddesc olddesc_sub1
action 4.24 if "$olddesc_sub1" eq "$host [$int]"
action 4.25 syslog msg "EEM script did NOT change desciption on $_nd_local_intf_name, since remote host and interface is unchanged"
action 4.26 exit 10
action 4.27 end
action 4.3 cli command "interface $_nd_local_intf_name"
action 4.4 cli command "description $host [$int]"
action 4.5 cli command "do write"
action 4.6 syslog msg "EEM script updated description on $_nd_local_intf_name from $olddesc to Description: $host [$int] and saved config"
action 5.0 end
action 6.0 exit 1


event manager applet auto-update-lldp-port-description authorization bypass
description "Auto-update port-description based on LLDP neighbors info"
action 0.0 comment "Event line regexp: Decide which interface to auto-update description on"
event neighbor-discovery interface regexp .*Ethernet.*$ lldp add
action 1.0 comment "Get Systemname have to be trimmed"
action 1.1 regexp "^([^\.]+)\." $_nd_lldp_system_name match host
action 2.0 comment "Get interface name and chassis data and system description"
action 2.1 set int "$_nd_port_id"
action 3.0 comment "Get long remote interface description by enabled capabilities: B,R ignore it"
action 3.1 regexp "(T|S)" $_nd_lldp_enabled_capabilities_string
action 3.2 if $_regexp_result eq 1
action 3.3 set int "$_nd_lldp_port_description"
action 3.4 end
action 4.0 comment "Check old description if any"
action 4.1 cli command "enable"
action 4.11 cli command "config t"
action 4.2 cli command "do show interface $_nd_local_intf_name | incl Description:"
action 4.21 set olddesc "<none>"
action 4.22 regexp "Description: (.*)" "$_cli_result" olddesc 
action 5.0 cli command "interface $_nd_local_intf_name"
action 5.1 cli command "description $host [$int] "
action 5.2 cli command "do write"
action 5.3 syslog msg "EEM script updated description on $_nd_local_intf_name from $olddesc to Description: $host [$int] and saved config"
action 6.0 exit 1
end



event manager applet ConfigureAsk
event cli pattern "^conf" sync yes
action 1.0 puts "You are going to configure the router"
action 1.1 puts nonewline "Do you really want to configure [Y/N]"
action 1.2 gets ans
action 1.3 string tolower "$ans"
action 1.4 string match "$_string_result" "y"
action 2.0 if $_string_result eq "1"
action 2.1  puts "Have fun"
action 2.2  set _exit_status "1"
action 2.3 else
action 2.4  set _exit_status "0"
action 2.5 end


event manager applet LARGECONFIG
event cli pattern "show running-config" sync yes
action 1.0 puts "Warning! You are going to configure the router"
action 1.1 puts nonewline "Do you really want to configure [Y/N]"
action 1.2 gets ans
action 1.3 string toupper "$ans"
action 1.4 string match "$_string_result" "Y"
action 2.0 if $_string_result eq "1"
action 2.1 cli command "enable"
action 2.2 cli command "show running-config"
action 2.3 puts $_cli_result
action 2.4 cli command "exit"
action 2.5 end
