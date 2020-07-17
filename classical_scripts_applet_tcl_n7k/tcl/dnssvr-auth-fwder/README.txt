

This script functions as a basic authoritative and forwarding DNS server and is able to 
resolve Internet and authoritative (local db) queries. This is based on http://wiki.tcl.tk/9302.
This script uses a modified version of dns.tcl from tcllib to perform the Internet queries.

*** NOTE ***
=============
this script quickly crashes with the error "state(reply)": no such element in array" apparently due to the 
older version of UDP package (pre-1.04) included with IOS Tcl.

This script is for demonstration purposes only and not intended for production use.




Step 1 
=====
Unzip dnssvr.zip
edit dnssvr.tcl   (search for: "set fwderServer 192.168.1.254" <- enter your dns server IP)
copy all files to router flash


Step 2
======== 
 config t   
    alias exec dnssvr tclsh flash:dnssvr.tcl 
    scripting tcl init flash:pkgIndex.tcl


Step 3  - Start the Daemon
=======
from CLI run:  dnssvr



Step 4 - Send Queries
======
nslookup
 server <ip of router>
 www.google.com.



Step 4  - Stop the daemon
=======
telnet <ip of router> 40000
cisco
stop