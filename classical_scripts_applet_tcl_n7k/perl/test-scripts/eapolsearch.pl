use strict;
use warnings;
use Net::SNMP;
use Net::Ping;
use Getopt::Std;
use Data::Dumper;
use DBI();
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use IO::Socket::SSL;

sub snmpwalkresult($$);
sub snmpget_ifindex($$$);
sub macresult($$$);;
sub vlan_mac_resolution();
sub string_to_hex($);
sub collect_nagios_host($$);
sub help();


#Variablen
#url variable
my $url = "https://adtools.company.local/sccm/add2db/switchports.aspx";
my %inputdata;

#snmp variables
#snmp variable f�r interface_status
my $oid_InterfaceShortName = "1.3.6.1.2.1.31.1.1.1.1";
my $oid_VlanId = "1.3.6.1.4.1.9.9.68.1.2.2.1.2";
my $oid_ifAdminStatus = "1.3.6.1.2.1.2.2.1.7";
my $oid_ifOperStatus = "1.3.6.1.2.1.2.2.1.8";
my $oid_ifSpeed = "1.3.6.1.2.1.2.2.1.5";
my $oid_eapolmac = "1.0.8802.1.1.1.1.2.2.1.12";
my $oid_eapolstatus = "1.0.8802.1.1.1.1.2.1.1.1";

#snmp variable f�r mac-address
my $oid_macaddress = "1.3.6.1.2.1.17.4.3.1";
my $oid_getInterfaceIndex = "1.3.6.1.2.1.17.1.4.1.2";

#snmp-session value
my $session;
my $error;

#Nagios-Daten holen
#Nagios-Gruppe definieren - es wird nur der Gruppenname ben�tigt

#my $switch_group = "Dot1x-Client-Switch";
my $switch_group = "FW_Check_Switch";
#host_array aus nagios_db abfrage mittels hostgroup


use vars qw / $opt_h $opt_b /;
$opt_h=0;
$opt_b='';

getopts( 'hb:' ) || 
        die "$0: valid options: [-h] [-b <ndl>] \n";

if ($opt_h != 0){
        help();
}
my $ndl = "%";

if ($opt_b eq ""){
        $ndl = "%";
} elsif ($opt_b eq "all"){
        $ndl = "%";
} else {
        chomp($opt_b);
        if (length($opt_b) != 3 ){
                die "Error wrong parameter - please type perl <program> -<ndl> or only perl <program>\n";
        }
        $ndl = $opt_b;
} 

my $mac_search = "";

# if ($opt_m =~ /([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2})/){
#               if ($opt_m =~ m/([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9])/){
#                       my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9, $v10, $v11, $v12) = (lc($1),lc($2),lc($3),lc($4),lc($5),lc($6),lc($7),lc($8),lc($9),lc($10),lc($11),lc($12));
#                       $opt_m = "$v1$v2$v3$v4.$v5$v6$v7$v8.$v9$v10$v11$v12";
#exit 0;

my @nagios_hosts = collect_nagios_host($switch_group,$ndl);
my $hosts = @nagios_hosts;
#print "Es werden $hosts Switche nach den MAC-Adressen durchsucht:\n";
#erstellen der initial value_variablen
my $hash_ref;
my ($interface, $vlanid, $trunk) = ( "", 0, 0 );
my ( $adminstatus, $operstatus, $ifspeed, $portdesc, $eapolmac, $eapolstatus ) = ( 0, 0, "", "", "", 0 );
my $macaddress = " ";

my @hosts;

foreach my $host (@nagios_hosts){
	if ($host =~ /internal-gateway/){
                next;
        } elsif ($host =~ /acp/){
                next;
        } elsif ($host =~ /core/){
                next;
        } elsif ($host =~ /asp/){
                next;
        } elsif ($host =~ /de.*/){
                push(@hosts, $host);
        }
}
#my @child_process;
my $index = 0;
my $hash_json = {};
#print "Switch\t\tSwitchport\tMAC-Adresse\tVLAN\tSpeed\t\tADMIN-UP\tOPER-UP\t802.1x-Status\n";
#print "---------------------------------------------------------------------------------------------------------\n"; 
foreach my $hostname (@hosts){
        
        #print "$hostname:\t";
        $hash_ref = {};
        
        # Create the SNMP session - only Read Permission not for Write
        ($session, $error) = Net::SNMP->session(
                   -hostname => $hostname,
                   -authprotocol =>  'md5',
                   -authpassword =>  'SNMP_Passwd!',
                   -username     =>  'SNMPUser',
                   -version      =>  '3',
                   -privprotocol =>  'des',
                   -privpassword =>  'SNMP_Secret'
        );
        
        #sammeln der daten mittels snmpwalk �ber den host
        #Interface-Main
        #print "Host: $hostname\n";
        $hash_ref = snmpwalkresult($oid_InterfaceShortName,'interfacename');
        $hash_ref = snmpwalkresult($oid_VlanId,'vlanid');
        $hash_ref = snmpwalkresult($oid_ifAdminStatus,'ifadminstatus');
        $hash_ref = snmpwalkresult($oid_ifOperStatus,'ifoperstatus');
        $hash_ref = snmpwalkresult($oid_ifSpeed,'ifspeed');
        $hash_ref = snmpwalkresult($oid_eapolmac,'eapolmac');
        $hash_ref = snmpwalkresult($oid_eapolstatus,'eapolstatus');
        
        
        #get mac-address from mac-address-table on switch with vlan-id
        my @vlans = vlan_mac_resolution();
        
        foreach my $vid (sort @vlans){
                        #print "VLAN-ID: $vid\n";
                        if (($vid == 661) or ($vid == 662) or ($vid == 664) or ($vid == 665) ){
                                next;
                        }
                        $hash_ref = macresult($oid_macaddress,'macaddress',"vlan-$vid");
                        if (!defined $hash_ref){
                                #print "$hostname kann folgende VLAN-ID: $vid nicht aufloesen!\n";
                        }
        }
        
        
        foreach my $key (sort{$a <=> $b} keys %$hash_ref){
                
                #werte aus referenz in variablen laden
                #interface-main
                $interface = $hash_ref->{ $key }->{ 'interfacename' };
                $vlanid = $hash_ref->{ $key }->{ 'vlanid' };
                $trunk = $hash_ref->{ $key }->{ 'trunkmode' };
                $macaddress = $hash_ref->{ $key }->{ 'macaddress' };
                $ifspeed = $hash_ref->{ $key }->{ 'ifspeed' };
                $adminstatus = $hash_ref->{ $key }->{ 'ifadminstatus' };
                $operstatus = $hash_ref->{ $key }->{ 'ifoperstatus' };
                $portdesc = $hash_ref->{ $key }->{ 'portdescr' };
                $eapolmac = $hash_ref->{ $key }->{ 'eapolmac' };
				$eapolstatus = $hash_ref->{ $key }->{ 'eapolstatus' };
                
				if (!defined $eapolmac){
					next;
				}
                if ($eapolmac =~ m/([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9])/){
                        my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9, $v10, $v11, $v12) = (lc($1),lc($2),lc($3),lc($4),lc($5),lc($6),lc($7),lc($8),lc($9),lc($10),lc($11),lc($12));
                        $eapolmac = "$v1$v2$v3$v4$v5$v6$v7$v8$v9$v10$v11$v12";
                }
                
                #entscheidungsbaum
                #wenn interface_name nicht mit Gi oder Fa beginnt -> next
                if (!defined $interface){
                        next;
                }
                unless ($interface =~ /Gi/ ) { 
                    unless ($interface =~ /Fa/ ) { 
                        next; 
					} 
                }
                
                # hier kann man dien Anzahl der Interfaces z�hlen
                #Fallunterscheidung f�r Access Mode (Wert: 2) oder Trunk Mode (Wert: 1)
                #Port Activity Status
                if (!defined $adminstatus) {
                        $adminstatus = "undef";
                }else{
                        if ($adminstatus == 1){
                                $adminstatus = "up";
                        }elsif ($adminstatus == 2){
                                $adminstatus = "down";
                        }elsif ($adminstatus == 3){
                                $adminstatus = "testing";
                        }
                }
                if (!defined $operstatus) {
                        $operstatus = "undef";
                }else{
                        if ($operstatus == 1){
                                $operstatus = "up";
                        }elsif ($operstatus == 2){
                                $operstatus = "down";
								next;
                        }elsif ($operstatus == 3){
                                $operstatus = "testing";
                        }elsif ($operstatus == 4){
                                $operstatus = "unknown";
                        }elsif ($operstatus == 5){
                                $operstatus = "dormant";
                        }elsif ($operstatus == 6){
                                $operstatus = "notPresent";
                        }elsif ($operstatus == 7){
                                $operstatus = "lowerLayerDown";
                        }
                }
                #VLAN ID anzeigen
                if (!defined $vlanid) {
                        next;
                        #$vlanid = "undef";
                }
                #Anzeige der Mac-Address
                if (!defined $macaddress) {
                        $macaddress = "undef";
                }
                #Anzeige der Mac-Address
                if ($eapolmac =~ /0x(.*)/) {
                        $eapolmac = $1;
                }
                if ($macaddress eq "undef"){
                        $macaddress = $eapolmac;
						#next;
                }
				#if (length($macaddress) == 0){
				#		next;
				#}
                #Speed und Duplex des Ports
                if (!defined $ifspeed) {
                        $ifspeed = "undef";
                }else{
                        if ($ifspeed =~ /(\d)(\d)\d{8}/){
                                $ifspeed = "$1.$2 Gbit/s";
                        }elsif ($ifspeed =~ /(\d)(\d)(\d)\d{6}/){
                                $ifspeed = "$1$2$3 Mbit/s";
                        }elsif ($ifspeed =~ /(\d)(\d)\d{6}/){
                                $ifspeed = "$1$2 Mbit/s";
                        }
                }
                if (!defined $eapolstatus) {
                        $eapolstatus = "undef";
                }else{
                        if ($eapolstatus == 1){
                                $eapolstatus = "initialize";
                        }elsif ($eapolstatus == 2){
                                $eapolstatus = "disconnected";
								next;
                        }elsif ($eapolstatus == 3){
                                $eapolstatus = "connecting";
                        }elsif ($eapolstatus == 4){
                                $eapolstatus = "authenticating";
								next;
                        }elsif ($eapolstatus == 5){
                                $eapolstatus = "authenticated";
                        }elsif ($eapolstatus == 6){
                                $eapolstatus = "aborting";
                        }elsif ($eapolstatus == 7){
                                $eapolstatus = "held";
                        }elsif ($eapolstatus == 8){
                                $eapolstatus = "forceAuth";
                        }elsif ($eapolstatus == 9){
                                $eapolstatus = "forceUnauth";
                        }
                }
                #print "Begin der Ausgabe\n";
				#if (length($interface) < 8) {
				#	print "$hostname\t$interface\t\t\t$macaddress\t$vlanid\t$ifspeed\t$adminstatus\t\t$operstatus\t$eapolstatus\n";
				#} else {
				#	print "$hostname\t$interface\t$macaddress\t$vlanid\t$ifspeed\t$adminstatus\t\t$operstatus\t$eapolstatus\n";
				#}
				%inputdata = (
					-switch =>	$hostname,
					-interface => $interface,
					-macaddress => $macaddress,
					-vid => $vlanid,
					-speed => $ifspeed,
					-dot1x => $eapolstatus );
				my $json = encode_json \%inputdata;
				$hash_json->{ $index } = $json;
				$index += 1;
        }
        
        # Close the snmp-read session
        $session->close();
}

#$ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

my $ua = LWP::UserAgent->new();
$ua->ssl_opts ( SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE, SSL_hostname => '', verify_hostname => 0 );
my $req = POST $url;
$req->header( 'Content-Type' => 'application/json' );
my $res = $ua->request($req);
while ( my ($key, $value) = each(%$hash_json) ) {
        print "$key => $value\n";
		my $encoded = encode_json($value);
		if ($res->is_success){
			print $req->content($encoded);
			#print $res->decoded_content;
		} else {
			print $res->status_line . "\n";
		}
}





#Functions
sub snmpwalkresult($$){
        
                my $oid = shift;
                my $mib = shift;
                
                #printf "Err: %s\n", $session->error();
                
    my $result = $session->get_table(
        -baseoid                =>      $oid,           
    );
    
    if (!defined $result){
        #printf "ERROR11: %s\n", $session->error();
        $session->close();
        exit 1;
    }
                
                my $list = $session->var_bind_list();
                
                if (!defined $list){
                        #printf "ERROR21: %s\n", $session->error();
                        return;
                }
                
                my @names = $session->var_bind_names();
                my $index = undef;
                
                while (@names){
                        $index = shift @names;
                        my $value = $list->{$index};
                        $index =~ s/$oid\.(.*)/$1/g;
                        #print "DEBUG: $mib := $index -> $value\n";
                        $hash_ref->{$index}->{$mib} = $value;
                }
                #foreach my $key (sort{$a <=> $b} keys %$hash_ref){
                #       my $value = $hash_ref->{ $key }->{ $mib };
                #       print "VALUE: $value\n";
                #}
                return $hash_ref;
}


sub snmpget_ifindex($$$){       
                my $oid = shift;
                my $ifindex = shift;
                my $context = shift;
                my $if_oid = "$oid.$ifindex";
                
                #printf "OID: %s, Context: %s\n",$if_oid,$context;
                chomp($context);
    chomp($if_oid);
    
    my $result = $session->get_request(
      -contextname => $context,
        -varbindlist            =>      [ $if_oid ],            
    );
    
    if (!defined $result){
        #printf "ERROR_Get1: %s\n", $session->error();
        return undef;
        #$session->close();
        #exit 1;
    }
                my $val = $result->{$if_oid};
                #printf "Result: %s\n", $val;           
                return $val;
}


#helper function 4 snmp mac transform from string to hex
sub string_to_hex($){ 
        my $string = shift;
        my $hex_value = "";
        for my $char (split //, $string) {
                if (ord($char) =~ /../){
                        $hex_value .= sprintf "%x", ord($char);
                } else {
                        $hex_value .= sprintf "0%x", ord($char);
                }
        }
        $hex_value = "0x".$hex_value;
        if ($hex_value =~ /0x[a-f0-9]{11}/){
                $hex_value = $hex_value."0";
        }       
        return $hex_value;
}

sub vlan_mac_resolution(){
        #BEGIN: VLAN's zusammenbauen und MAC-Address-Table abfragen
        my @vlans = ();
        foreach my $key (sort{$a <=> $b} keys %$hash_ref){
                
                #werte aus referenz in variablen laden
                $interface = $hash_ref->{ $key }->{ 'interfacename' };
                $vlanid = $hash_ref->{ $key }->{ 'vlanid' };
                $trunk = $hash_ref->{ $key }->{ 'trunkmode' };
                
                #entscheidungsbaum
                #wenn interface_name nicht mit Gi oder Fa beginnt -> next
                if (!defined $interface){
                        next;
                }
                unless (($interface =~ /Gi/ ) or ($interface =~ /Fa/ )) { 
                        next; 
                }
                # hier kann man dien Anzahl der Interfaces z�hlen
                #Fallunterscheidung f�r Access Mode (Wert: 2) oder Trunk Mode (Wert: 1)
                #if ($trunk == 1){
                if (( !defined $trunk ) or ( $trunk == 1 )){
                                next;
                }
                #undefined ports sind trunkports (zur sicherheit) und 666 shutdown_vlan
                if ((!defined $vlanid) or ( $vlanid == 666) or ( $vlanid == 1)) {
                        next;
                }
                push(@vlans, $vlanid);
                #print "$interface -> $vlanid \n";
        }
        @vlans = &del_doubles(@vlans);
        return @vlans;
        #END: VLAN's zusammenbauen und MAC-Address-Table abfragen
}
sub macresult($$$){
        
                my $oid = shift;
                my $mib = shift;
                my $context = shift;
                chomp($context);
    
    #Teil 1 MACs aufl�sen
    my $result_mac = $session->get_table(
      -contextname => $context,
        -baseoid                =>      "$oid.1",       
    );
    
    if (!defined $result_mac){
        #printf "ERROR_MAC_Result: %s\n", $session->error();
        return undef;
        #$session->close();
        #exit 1;
    }
                my $list_mac = $session->var_bind_list();
                if (!defined $list_mac){
                        #printf "ERROR22: %s\n", $session->error();
                        return;
                }
                my @names_mac = $session->var_bind_names();
                my $index_mac = undef;
                
                #Teil 2 Interface aufl�sen
                my $result_ifindex = $session->get_table(
      -contextname => $context,
        -baseoid                =>      "$oid.2",       
    );
    
    if (!defined $result_ifindex){
        #printf "ERROR13: %s\n", $session->error();
        $session->close();
        exit 1;
    }
                my $list_ifindex = $session->var_bind_list();
                if (!defined $list_ifindex){
                        #printf "ERROR23: %s\n", $session->error();
                        return;
                }
                my @names_ifindex = $session->var_bind_names();
                my $index_ifindex = undef;
                my %reference_mac = ();
                my %reference_ifindex = ();
                my %reference = ();
                while (@names_mac){
                        $index_mac = shift @names_mac;
                        my $value_mac = $list_mac->{$index_mac};
                        $index_mac =~ s/$oid\.1\.(.*)/$1/g;
                        #print "DEBUG: $index_mac -> $value_mac\n";
                        if ($value_mac !~ /^0x/){
                                $value_mac = string_to_hex($value_mac);
                                #print "$value_mac\n";
                        }
                        $value_mac =~ s/0x([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{4}).*/$1\.$2\.$3/g;
                        $reference_mac{$index_mac} = $value_mac;
                }
                
                while (@names_ifindex){
                        $index_ifindex = shift @names_ifindex;
                        my $value_ifindex = $list_ifindex->{$index_ifindex};
                        $index_ifindex =~ s/$oid\.2\.(.*)/$1/g;
                        #print "DEBUG: $index_ifindex -> $value_ifindex\n";
                        $reference_ifindex{$index_ifindex} = $value_ifindex;
                        #$hash_ref->{$index}->{$mib} = $value;
                }
                foreach my $key (keys %reference_mac){
                        my $id = snmpget_ifindex($oid_getInterfaceIndex,$reference_ifindex{$key},$context);
                        $reference{$id} = $reference_mac{$key};
                }
                foreach my $key (keys %reference){
                        #print "$key => $reference{$key}\n";
                        $hash_ref->{$key}->{$mib} = $reference{$key};
                }
                return $hash_ref;
}



sub del_doubles
{ 
        my %all;
        grep {$all{$_}=0} @_;
        return (keys %all);
}

#file functions
sub insert_into_text($$){
        my $statement = shift;
        my $file = shift;
        
        my $filename = "/opt/scripts/test-scripts/$file.txt";
        
        open(FILE,">>$filename") or die("Fehler bei open $filename $!");
        print FILE $statement;
        close(FILE);
}

sub collect_nagios_host($$){
        
        my $hostgroup = shift;
        my $ndl = shift;
        #database nagios
        my $nagioshost = "dbserver.company.local";
        my $nagiosdatabase = "nagios";
        my $nagiosuser = "nagiosread";
        my $nagiospassword = "xm!Es6c=nYE54ppbz8KX";
        #connect to nagios_db
        my $db = DBI->connect("DBI:mysql:database=$nagiosdatabase;host=$nagioshost;port=3310",$nagiosuser, $nagiospassword); 
        #$db->selectdb($nagiosdatabase);        
        #select statement (get all host from $hostgroup
        my $querystring = "select h.alias from nagios_hostgroups g, nagios_hostgroup_members m, nagios_hosts h where g.alias = '$hostgroup' and h.alias like 'de$ndl-%' and m.host_object_id = h.host_object_id and g.hostgroup_id = m.hostgroup_id order by h.alias";
        my $query = $db->prepare($querystring);
        $query->execute();
        #my @host_elements;
        #my $i = 0;
        my @array;
        #while ($host_elements[$i] = $query->fetchrow_hashref()){
        #       push(@array,$host_elements[$i]);
        #       $i++;
        #}
        while (my $ref = $query->fetchrow_hashref()){
                #print "Object $ref->{'alias'}\n";
                push(@array,$ref->{'alias'});
        }
        #return array with "selected" hosts
        $query->finish();
        $db->disconnect();
        
        return @array;
        
}

sub help()
{
        print "\neapolsearch.pl is a little tool to polute the adtools with mac addresses descovered on the switches";
        print "\nSyntax:\t eapolsearch.pl -b ndl \n";
        exit 1;
}


