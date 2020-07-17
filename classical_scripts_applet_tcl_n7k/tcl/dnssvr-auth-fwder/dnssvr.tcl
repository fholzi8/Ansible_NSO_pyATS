#
# Copyright (c) 2013 Scott Tudor <netc.project@gmail.com>
# All rights reserved.
#
# Limitation of Liability
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY.
#
# IN NO EVENT, REGARDLESS OF CAUSE, SHALL THE AUTHOR OF THIS SCRIPT BE LIABLE
# FOR ANY INDIRECT, SPECIAL, INCIDENTAL, PUNITIVE OR CONSEQUENTIAL DAMAGES OF ANY
# KIND, WHETHER ARISING UNDER BREACH OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
# STRICT LIABILITY OR OTHERWISE, AND WHETHER BASED ON THIS AGREEMENT OR 
# OTHERWISE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.
#
# Based on:
# Tcl DNS Server from Steve Redler IV   steve-tclwiki at sr-tech.com
# dns.tcl - modified by Steve Bennett   steveb at workware.net.au
#
#
# Add to CLI:
# scripting tcl init flash:pkgIndex.tcl
# alias exec dnssvr tclsh flash:dnssvr.tcl

package require udp
package require dns


  proc dbload {} {
    ########################
    set dbfile flash:db.txt
    ########################
    array set ::db {0 ""}
    set f3 [open "$dbfile" r]

    while {[gets $f3 dbline]>=0} {
      set s1 [lindex $dbline 0]
      set s2 [lindex $dbline 1]
      set ::db($s1) $s2
    }
    close $f3
  }


  proc cvtname {dnsname} {
  #convert from binary dns hostname format to readable string
    set result ""
    set chr 0

    while {$chr < [string length $dnsname]} {
       binary scan [string index $dnsname $chr] c* groupcnt
       if {$chr > 0} {set dnsname [string replace $dnsname $chr $chr "."]}
       incr chr +$groupcnt
       incr chr
    }
    return [string range $dnsname 1 end]
  }

  proc cvthostnamedns {hostname} {
  #convert from text hostname format to dns binary format
    set result ""
    set hostname [split $hostname "."]
    foreach part $hostname {
       append result "[format %c [string length $part]]$part"
    }
    return $result
  }


  proc striphostname {hostname} {
  #strip leading name
    set result ""
    set name_len [string length [lindex [split $hostname "."] 0]]
    set result "$name_len [string range $hostname [expr {$name_len + 1}] end]"
    return $result
  }

  proc cvtaddressdns {address} {
  #convert from text dotted address format to dns binary format
    set result ""
    set address [split $address "."]
    foreach octet $address {
      append result "[format %c $octet]"
    }
    return $result
  }


  proc cvtIPv6address { ipv6add } {
    #convert ipv6 address to acceptable hex string
    set result ""
    if {$ipv6add!=""} {set result [string map { : "" } [::ip::normalize $ipv6add]]}
    return $result
  }


  proc process_dns {host port pkt} {
    set resp_answer ""; set recindex 0; set error 0; set usefwder 0
    set rrindex 0; set fwderError 0; set offset 12; set offset_len 0; set firstRecord 0

    #[binary format H* $reply]
    binary scan $pkt H* cvt_data
    #puts $cvt_data
    set transid [string range $cvt_data 0 3]
    set params  [string range $cvt_data 4 7]
    set quests  [string range $cvt_data 8 11]
    set answers [string range $cvt_data 12 15]
    set authors [string range $cvt_data 16 19]
    set addits  [string range $cvt_data 20 23]
    set queryname  [string range $cvt_data 24 end-8]
    set querytype  [string range $cvt_data end-7 end-4]
    set queryclass [string range $cvt_data end-3 end]

    switch $querytype {
      	0001  	{set qtype A}
      	0002  	{set qtype NS}
      	0005  	{set qtype CNAME}
      	0006  	{set qtype SOA}
      	000c  	{set qtype PTR}
      	000d  	{set qtype HINFO}
      	000f  	{set qtype MX}
	001c	{set qtype AAAA}
	0021	{set qtype SRV}
      default {set qtype error}
    }

    set rr [string range [cvtname [string range $pkt 12 end-4]] 0 end-1]
    set qname [split [cvtname [string range $pkt 12 end-4]] "."]
    set llen [llength $qname] 

    #determine host/domain portion for local db lookups
    set qhost ""; set qdomain [string map {" " .} [lrange $qname 0 end-1]]; set dom_count 0
    if {![info exists ::db($qdomain,SOA)]} {
      while {$qdomain!=""} {
        set qhost [string map {" " .} [lrange $qname 0 $dom_count]]
        set qdomain [string map {" " .} [lrange $qname [expr {$dom_count+1}] end-1]] 
        if {![info exists ::db($qdomain,SOA)] && $dom_count < 15} {incr dom_count} else {break}
      } 
    }
  
   puts "Query from $host on port $port for $rr type $qtype"

    set answer "0001"
    set author "0000"
    set params "8580" ; #this indicates a successful query

    set class $queryclass
    set type $querytype

    if {! [info exists ::db($qdomain,SOA)]} {

####FORWARDER BEGIN

    set error 1; set usefwder 1; set rdataColumn 11; set rrtypeColumn 3; set rrnameColumn 1; 
    set params "8180"
    ###############################
    set fwderServer 192.168.1.254
    ###############################

    set fwdercfgopt [dns::configure -nameserver $fwderServer -protocol udp]
    set fwderAnswer [dns::resolve $rr -protocol udp -type $qtype]
    set fwderwaitTi [dns::wait $fwderAnswer]
    set fwderlookupresult [dns::result $fwderAnswer]
    set fwdercleanup [dns::cleanup $fwderAnswer]

    if {$fwderlookupresult==""} {set params "8183"}

    #puts $fwderlookupresult

    #setup c00c compressionPtr
    set offset_len [expr {$offset_len + 12}]
    set rrname [lindex [lindex $fwderlookupresult $rrindex] $rrnameColumn]
    set cPtroffsetTo($rrname) $offset_len

    #calculate offset due to length of searched domain
    set pream [string length $rr]; incr pream +2; incr pream +4; set preamble [expr $pream + 12]
    set offset_len $preamble

    while {!$fwderError} {
       if {[lindex $fwderlookupresult $rrindex] == ""} {array unset cPtroffsetTo; break}
       set fwderquerytype [lindex [lindex $fwderlookupresult $rrindex] $rrtypeColumn]

       switch $fwderquerytype {

           A     {set lookup [cvtaddressdns [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn]] }
 	   AAAA  {set lookup [cvtIPv6address [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn]] }
	   MX    {set mxprefix [lindex [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] 0] 
	          set lookup [cvthostnamedns [lindex [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] 1]]
		 } 
    	   CNAME {set lookup [cvthostnamedns [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn]] }
           PTR   {set lookup [cvthostnamedns [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn]] }
    	   NS    {set lookup [cvthostnamedns [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn]] }
	   SOA   {set lookup [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] }
	   SRV	 {set srvprefix0 [lindex [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] 1] 
		  set srvprefix1 [lindex [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] 3] 
                  set srvprefix2 [lindex [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] 5] 
	          set lookup [cvthostnamedns [lindex [lindex [lindex $fwderlookupresult $rrindex] $rdataColumn] 7]]
		 } 
        }

	#puts $lookup
        set len [string length $lookup]
        binary scan $lookup H* hexlookup

	#find offsets and set compression Pointers
	set offset_len [expr {$offset_len + 12}]
	set rrname [lindex [lindex $fwderlookupresult [expr {$rrindex + 1}]] 1]
	if {![info exists cPtroffsetTo($rrname)]} {set cPtroffsetTo($rrname) $offset_len}
	set compressionPtr [format %02x $cPtroffsetTo([lindex [lindex $fwderlookupresult $rrindex] 1])]
        #puts "c0$compressionPtr"

        switch $fwderquerytype {

           A     {set data $hexlookup; set type 0001; set hdr "c0$compressionPtr"
		      set author_name [lindex [lindex $fwderlookupresult $rrindex] $rrnameColumn]
    	              set dom_name $author_name
          	      set name_len [format %02x [expr {[lindex [striphostname $author_name] 0] + 1}]]
          	      set newCPtr $compressionPtr
		 }
           AAAA  {set data ${lookup}; set type 001c; set hdr "c0$compressionPtr"; set len [expr [string length $data] / 2 ]
		 }
	   MX    {set data "[format %04x $mxprefix]${hexlookup}00"; set hdr "c0$compressionPtr"
                  incr len +3
                 }
	  CNAME  {set data "${hexlookup}00"; incr len; set type 0005; set hdr "c0$compressionPtr"
                 }
	  PTR    {set data "${hexlookup}00"; incr len; set hdr "c0$compressionPtr" }
	  NS	 {set data "${hexlookup}00"; set type 0002; set hdr "c0$compressionPtr"; incr len
                 }
	   SOA   {
		  binary scan [cvthostnamedns [lindex $lookup 1]] H* hexlookup
    	          set data "${hexlookup}00"
		  binary scan [cvthostnamedns [lindex $lookup 3]] H* hexlookup
	          append data "${hexlookup}00"
		  append data [format %08x [lindex $lookup 5]]
		  append data [format %08x [lindex $lookup 7]]
	  	  append data [format %08x [lindex $lookup 9]]
		  append data [format %08x [lindex $lookup 11]]
		  append data [format %08x [lindex $lookup 13]]
   	          set len [expr [string length $data] / 2 ]
		  set hdr "c0$compressionPtr"
		      set author_name [lindex [lindex $fwderlookupresult $rrindex] $rrnameColumn]
    	              set dom_name $author_name
          	      set name_len [format %02x [expr {[lindex [striphostname $author_name] 0] + 1}]]
          	      set newCPtr $compressionPtr

	         }
	  SRV    {set data "[format %04x $srvprefix0][format %04x $srvprefix1][format %04x $srvprefix2]${hexlookup}00"
                  incr len +7; set type 0021; set hdr "c0$compressionPtr"
		      set author_name [lindex [lindex $fwderlookupresult $rrindex] $rrnameColumn]
    	              set dom_name $author_name
          	      set name_len [format %02x [expr {[lindex [striphostname $author_name] 0] + 1}]]
          	      set newCPtr $compressionPtr
		  }

        }
       
        set len [format %04x $len]
        set ttl [format %08x 3600]
        #puts "${type} ${class} ${ttl} $len $data"
        append resp_answer "${hdr}${type}${class}${ttl}${len}${data}"

        set offset_len [expr {$offset_len + [expr {[string length "$data"] / 2}]}]

        incr rrindex
        set answer [format %04x $rrindex]
      }

#-#-#-#-#-#  BEGIN AUTHORITY SECTION  #-#-#-#-#-#
 
### BEGIN "NO SUCH DOMAIN" AUTHORITY SECTION
 
	if {$params == "8183"} {

	set dom1_name $rr; set newCPtr 0c;
        while {$fwderlookupresult=="" && [string length $dom1_name] > 0} { 

	   set strip_result [striphostname $dom1_name]
	   set dom1_name [lindex $strip_result 1]
           set name_len [format %02x [expr {[lindex $strip_result 0] + 1}]]
           set newCPtr [format %02x [expr {[format %d 0x$newCPtr] + [format %d 0x$name_len]}]]

	   set fwderAnswer [dns::resolve $dom1_name -protocol udp -type SOA]
           set fwderwaitTi [dns::wait $fwderAnswer]
           set fwderlookupresult [dns::result $fwderAnswer]
           set fwdercleanup [dns::cleanup $fwderAnswer]

        }
	      set lookup [lindex [lindex $fwderlookupresult 0] $rdataColumn]

	   set len [string length $lookup]
           binary scan $lookup H* hexlookup

	     binary scan [cvthostnamedns [lindex $lookup 1]] H* hexlookup
    	     set data "${hexlookup}00"
	     binary scan [cvthostnamedns [lindex $lookup 3]] H* hexlookup
	     append data "${hexlookup}00"
	     append data [format %08x [lindex $lookup 5]]
	     append data [format %08x [lindex $lookup 7]]
    	     append data [format %08x [lindex $lookup 9]]
             append data [format %08x [lindex $lookup 11]]
	     append data [format %08x [lindex $lookup 13]]
   	     set len [expr [string length $data] / 2 ]
             set hdr "c0$newCPtr"
             set type 0006;


           set len [format %04x $len]
           set ttl [format %08x 3600]
           #puts "${type} ${class} ${ttl} $len $data"
           append resp_answer "${hdr}${type}${class}${ttl}${len}${data}"

           set offset_len [expr {$offset_len + [expr {[string length "$data"] / 2}]}]

           set author [format %04x 1]
           set answer [format %04x 0]

### END "NO SUCH DOMAIN" AUTHORITY SECTION

    } else { 
 
        if {[info exists dom_name]} {
          set rrindex2 0
	  set fwderAnswer [dns::resolve $dom_name -protocol udp -type NS]
          set fwderwaitTi [dns::wait $fwderAnswer]
          set fwderlookupresult [dns::result $fwderAnswer]
          set fwdercleanup [dns::cleanup $fwderAnswer]

	  while {$fwderlookupresult=="" && [string length $dom_name] > 0} {

	    set strip_result [striphostname $dom_name]
	    set dom_name [lindex $strip_result 1]
            set name_len [format %02x [expr {[lindex $strip_result 0] + 1}]]
            set newCPtr [format %02x [expr {[format %d 0x$newCPtr] + [format %d 0x$name_len]}]]

   	    set fwderAnswer [dns::resolve $dom_name -protocol udp -type NS]
            set fwderwaitTi [dns::wait $fwderAnswer]
            set fwderlookupresult [dns::result $fwderAnswer]
            set fwdercleanup [dns::cleanup $fwderAnswer]
          }

          while {!$fwderError} {
            if {[lindex $fwderlookupresult $rrindex2] == ""} {dns::cleanup $fwderAnswer; array unset cPtroffsetTo; break}
           
              set lookup [cvthostnamedns [lindex [lindex $fwderlookupresult $rrindex2] $rdataColumn]]
	
            set len [string length $lookup]
            binary scan $lookup H* hexlookup

              set data "${hexlookup}00"; set type 0002; set hdr "c0$newCPtr"
              incr len
       
            set len [format %04x $len]
            set ttl [format %08x 3600]
            #puts "${type} ${class} ${ttl} $len $data"
            append resp_answer "${hdr}${type}${class}${ttl}${len}${data}"

            set offset_len [expr {$offset_len + [expr {[string length "$data"] / 2}]}]

            incr rrindex2
            set author [format %04x $rrindex2]
          }
       }
     }

#-#-#-#-#-# END AUTHORITY SECTION

    }

#### FORWARDER END 
  
    if {! [info exists ::db($qdomain,$qtype,$qhost)] && $qtype != "NS" && $qtype != "MX" && $qtype != "SOA" && $usefwder != 1} {
    #host doesnt exist, so return an error reply
      set params "8183"; #this indicates an error
      set error 1
      set answer "0000"
    }

####DATABASE LOOKUP BEGIN 
    
    while {! $error && $usefwder=="0"} {

      switch $qtype {
        A     {set lookup [cvtaddressdns  [lindex $::db($qdomain,$qtype,$qhost) $recindex]]}
	AAAA  {set lookup [cvtIPv6address [lindex $::db($qdomain,$qtype,$qhost) $recindex]]}
        MX    {set mxprefix [lindex [lindex $::db($qdomain,$qtype) $recindex] 0]
               set lookup [cvthostnamedns [lindex [lindex $::db($qdomain,$qtype) $recindex] 1]]
              }
        NS    {set lookup [cvthostnamedns [lindex $::db($qdomain,$qtype) $recindex]]}
        CNAME {set lookup [cvthostnamedns [lindex $::db($qdomain,$qtype,$qhost) $recindex]]}
        HINFO {set lookup [lindex $::db($qdomain,$qtype,$qhost) $recindex]}
        PTR   {set lookup [cvthostnamedns [lindex $::db($qdomain,$qtype,$qhost) $recindex]]
	      }
	SOA   {set lookup [lindex $::db($qdomain,$qtype) $recindex]}
	SRV   {set srvprefix0 [lindex [lindex $::db($qdomain,$qtype,$qhost) $recindex] 0] 
	       set srvprefix1 [lindex [lindex $::db($qdomain,$qtype,$qhost) $recindex] 1] 
               set srvprefix2 [lindex [lindex $::db($qdomain,$qtype,$qhost) $recindex] 2] 
	       set lookup [cvthostnamedns [lindex [lindex $::db($qdomain,$qtype,$qhost) $recindex] 3]]
              } 
      }
     

      #puts $lookup
      if {$lookup == "" || $recindex > 20} {break}
      set len [string length $lookup]
      binary scan $lookup H* hexlookup

      switch $qtype {
       A     {set data $hexlookup}
       AAAA  {set data ${lookup}; set type 001c; set len [expr [string length $data] / 2 ] }
       NS    {set data "${hexlookup}00"; incr len}
       CNAME {set data "${hexlookup}00"; incr len
             }
       MX    {set data "[format %04x $mxprefix]${hexlookup}00"
              incr len +3
             }
       HINFO {incr recindex
              set data "[format %02x $len]${hexlookup}"
              set lookup [lindex $::db($qdomain,$qtype,$qhost) $recindex]
              set len [string length $lookup]
              binary scan $lookup H* hexlookup
              append data "[format %02x $len]${hexlookup}00"
              set len [expr [string length $data] / 2 -1]
             }
	PTR  {set data "${hexlookup}00"
              incr len
	     }
	SOA  {
	      binary scan [cvthostnamedns [lindex $lookup 0]] H* hexlookup
    	      set data "${hexlookup}00"
	      binary scan [cvthostnamedns [lindex $lookup 1]] H* hexlookup
	      append data "${hexlookup}00"
	      append data [format %08x [lindex $lookup 2]]
	      append data [format %08x [lindex $lookup 3]]
	      append data [format %08x [lindex $lookup 4]]
	      append data [format %08x [lindex $lookup 5]]
	      append data [format %08x [lindex $lookup 6]]
   	      set len [expr [string length $data] / 2 ]
	      set hdr c00c
	     }
      SRV    {set data "[format %04x $srvprefix0][format %04x $srvprefix1][format %04x $srvprefix2]${hexlookup}00"
              incr len +7; set type 0021; set hdr c00c;
     	      #set author_name [lindex [lindex $fwderlookupresult $rrindex] $rrnameColumn]
	      #set author_compressionPtr $compressionPtr
		  }
      }

      set len [format %04x $len]
      set ttl [format %08x [lindex [lindex $::db($qdomain,SOA) $firstRecord] 6]]
      #puts "${type} ${class} ${ttl} $len $data"
      append resp_answer "C00C${type}${class}${ttl}${len}${data}"
      incr recindex
      set answer [format %04x $recindex]
    }

####DATABASE LOOKUP END 

    set resp_author ""
    set resp_addit  ""
    set response "[string range $cvt_data 0 3]${params}[string range $cvt_data 8 11]${answer}${author}[string range $cvt_data 20 end]"
    #puts $response$resp_answer
    udp_puts $host $port [binary format H* ${response}${resp_answer}${resp_author}${resp_addit}]

  }


  proc udp_puts {host port data} {
    fconfigure $::sock -blocking 0 -buffering none -translation binary -remote [list $host $port]
     puts -nonewline $::sock $data
  }


  proc udpEventHandler {sock} {
      set pkt [read $sock]
      set peer [fconfigure $sock -peername]
      process_dns [lindex $peer 0] [lindex $peer 1] $pkt
      return
  }


   proc callback {sock addr port} {
    fconfigure $sock -translation lf -buffering line
    fileevent $sock readable [list tcpEventHandler $sock]
  }

   
   proc tcpEventHandler {sock} {
     global forever
     ####################
     set accesspw cisco
     ####################
     if {[eof $sock] || [catch {gets $sock line}]} {} {
        if {[string equal $line "$accesspw\r"] || [string equal $line "$accesspw\n"]} {
	   if {[eof $sock] || [catch {gets $sock line}]} {} {   
	      switch $line {
		"stop\r"   { puts "DNS Service Stopped"
        		     set forever 1
			     close $sock
    			   }
               "reload\r" {
        		     array unset ::db; dbload
			     puts "DNS Service Restarted"
		             close $sock
    			   }
		"stop\n"   { puts "DNS Service Stopped"
        		     set forever 1
			     close $sock
    			   }
               "reload\n" {
        		     array unset ::db; dbload
			     puts "DNS Service Reloaded"
		             close $sock
    			   }
    		default {}
              }
          }
        }
     }
   }


  proc udp_listen {port} {
      set srv [udp_open $port]
      fconfigure $srv -buffering none -translation binary
      fileevent $srv readable [list ::udpEventHandler $srv]
      puts "DNS Service Started"
      return $srv
  }



###
# Main


  dbload
  set tport 40000
  set tcpsock [socket -server callback $tport]

  set ::sock [udp_listen 53]
  vwait forever
  close $::sock
  close $tcpsock