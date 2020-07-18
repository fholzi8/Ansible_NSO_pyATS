use strict;
use Net::SNMP;
use Net::Ping;
use Getopt::Std;
use Data::Dumper;
use DBI();
#use Parallel::ForkManager;


sub snmpwalkresult($$);
sub snmpget_ifindex($$$);
sub macresult($$$);;
sub vlan_mac_resolution();
sub string_to_hex($);
sub collect_nagios_host($$);
sub help();


#Variablen

#snmp variables
#snmp variable f�r interface_status
my $oid_InterfaceShortName = "1.3.6.1.2.1.31.1.1.1.1";
my $oid_TrunkMode = "1.3.6.1.4.1.9.9.46.1.6.1.1.14";
my $oid_VlanId = "1.3.6.1.4.1.9.9.68.1.2.2.1.2";
my $oid_ifAdminStatus = "1.3.6.1.2.1.2.2.1.7";
my $oid_ifOperStatus = "1.3.6.1.2.1.2.2.1.8";
my $oid_PortDescr = "1.3.6.1.4.1.9.2.2.1.1.28";
my $oid_ifSpeed = "1.3.6.1.2.1.2.2.1.5";
my $oid_eapolmac = "1.0.8802.1.1.1.1.2.2.1.12";

#snmp variable f�r mac-address
my $oid_macaddress = "1.3.6.1.2.1.17.4.3.1";
my $oid_getInterfaceIndex = "1.3.6.1.2.1.17.1.4.1.2";

#print "Starting main program\n";
#Fork of 50 Child-Processes
#my $pm = Parallel::ForkManager->new(20);

#snmp-session value
my $session;
my $error;

#Nagios-Daten holen
#Nagios-Gruppe definieren - es wird nur der Gruppenname ben�tigt

#my $switch_group = "Dot1x-Client-Switch";
my $switch_group = "FW_Check_Switch";
#host_array aus nagios_db abfrage mittels hostgroup


use vars qw / $opt_h $opt_b $opt_m /;
$opt_h=0;
$opt_m='';
$opt_b='';

getopts( 'hb:m:' ) ||
	die "$0: valid options: [-h] [-b <ndl>] [-m <mac>](000c.1234.affe)\n";

if ($opt_h != 0){
	help();
}
my $ndl = "%";
my $more_mac = 0;
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

if ($opt_m eq "") {
	die "No Search Parameter\n";
} else {
	chomp($opt_m);

	if ($opt_m =~ /([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2}).([A-Fa-f0-9]{2})/){
		if ($opt_m =~ m/([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9]).([A-Fa-f0-9])([A-Fa-f0-9])/){
			my ($v1, $v2, $v3, $v4, $v5, $v6, $v7, $v8, $v9, $v10, $v11, $v12) = (lc($1),lc($2),lc($3),lc($4),lc($5),lc($6),lc($7),lc($8),lc($9),lc($10),lc($11),lc($12));
			$opt_m = "$v1$v2$v3$v4.$v5$v6$v7$v8.$v9$v10$v11$v12";
		}
	}
	if (length($opt_m) < 14){
		$more_mac = 1;
	} elsif ($opt_m !~ /([a-f0-9]{4})\.([a-f0-9]{4})\.([a-f0-9]{4})/) {
		die "Please use Cisco-Format for Mac-Address\n";
	}
	$mac_search = $opt_m;
	#print "MAC-Search:\t $mac_search\n";
	#$mac_search = "4061.86e7.acab";
}
#exit 0;

my $start = time();
my @nagios_hosts = collect_nagios_host($switch_group,$ndl);
my $hosts = @nagios_hosts;
print "Es werden $hosts Switche nach der MAC-Adresse durchsucht\n";
#erstellen der initial value_variablen
my $hash_ref;
my ($interface, $vlanid, $trunk) = ( "", 0, 0 );
my ( $adminstatus, $operstatus, $ifspeed, $portdesc, $eapolmac ) = ( 0, 0, " ", " " );
my $macaddress = " ";
my $source = "10.11.14.221";

my $ping = Net::Ping->new("icmp");
#print $source;

$ping->bind($source);
my @hosts;

foreach my $host (@nagios_hosts){
	unless ($ping->ping($host, 2)){
  	next;
  }
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

foreach my $hostname (@hosts){
	#my $pid = $pm->start and next;
	#push(@child_process, $pid);


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
	#print "Host1: $hostname\n";
	$hash_ref = snmpwalkresult($oid_InterfaceShortName,'interfacename');
	$hash_ref = snmpwalkresult($oid_TrunkMode,'trunkmode');
	$hash_ref = snmpwalkresult($oid_VlanId,'vlanid');
	$hash_ref = snmpwalkresult($oid_ifAdminStatus,'ifadminstatus');
	$hash_ref = snmpwalkresult($oid_ifOperStatus,'ifoperstatus');
	$hash_ref = snmpwalkresult($oid_PortDescr,'portdescr');
	$hash_ref = snmpwalkresult($oid_ifSpeed,'ifspeed');
	$hash_ref = snmpwalkresult($oid_eapolmac,'eapolmac');


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


		#entscheidungsbaum
		#wenn interface_name nicht mit Gi oder Fa beginnt -> next
		if (!defined $interface){
			next;
		}
		unless ($interface =~ /Gi/ ) {
			next;
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
		#Trunk oder Access Mode
		if (!defined $trunk){
			$trunk = "undef";
		}else{
			if ($trunk == 1){
				$trunk = "trunk mode";
			}elsif ($trunk == 2){
				$trunk = "access mode";
			}
		}
		#VLAN ID anzeigen
		if (!defined $vlanid) {
			next;
			#$vlanid = "undef";
		}
		#Anzeige der Mac-Address
		if (!defined $macaddress) {
			if ($operstatus ne "up"){
				$macaddress = "none";
			} else {
			$macaddress = "undef";
			}
		}
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
		if (!defined $portdesc) {
			$portdesc = "undef";
		}else{
			$portdesc = substr($portdesc,0,20);
		}
		if (!defined $eapolmac) {
			$eapolmac = "undef";
		}elsif ($eapolmac =~ /.*00-00-00.*/ ){
			$eapolmac = "undef";
		}
		if ($more_mac == 1){
			my $search_length = length($mac_search);
			#my $last_macaddress = $macaddress;
			my $last_macaddress = substr($macaddress,14-$search_length,14);
			#print "$mac_search  = $search_length ::  $last_macaddress\n";
			#BEGIN der Ausgabe
			if ($mac_search eq $last_macaddress){
				print "Host:\t $hostname\n";
				print "--------------------------------------------------------------------------------------------------";
				print "-----------------------------\n";
				if ($interface =~ /Gi\d\/0\/\d\d/){
					print "$interface\t";
				} else {
					print "$interface\t\t";
				}
				print "$macaddress\t\t";
				if ( length($portdesc) < 16 ){
					if ( length($portdesc) < 8 ){
						print "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t\t$adminstatus\t$operstatus\n";
					}else {
						print "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t$adminstatus\t$operstatus\n";
					}
				}else{
					print "$vlanid\t$trunk\t$ifspeed\t$portdesc\t$adminstatus\t$operstatus\n";
				}
				#foreach my $ppid (@child_process){
				#	kill TERM => $ppid;
				#}
			}
		}
		else {
			#BEGIN der Ausgabe
			if ($mac_search eq $macaddress){
				print "Host:\t $hostname\n";
				print "--------------------------------------------------------------------------------------------------";
				print "-----------------------------\n";
				if ($interface =~ /Gi\d\/0\/\d\d/){
					print "$interface\t";
				} else {
					print "$interface\t\t";
				}
				print "$macaddress\t\t";
				if ( length($portdesc) < 16 ){
					if ( length($portdesc) < 8 ){
						print "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t\t$adminstatus\t$operstatus\n";
					}else {
						print "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t$adminstatus\t$operstatus\n";
					}
				}else{
					print "$vlanid\t$trunk\t$ifspeed\t$portdesc\t$adminstatus\t$operstatus\n";
				}
				my $end = time();
				printf("Dauer: %.1f Sekunden\n", $end - $start);
				#foreach my $ppid (@child_process){
				#	kill TERM => $ppid;
				#}
			}
		}
	}

	# Close the snmp-read session
	$session->close();

	#$pm->finish;
}
#$pm->wait_all_children;

my $end = time();
printf("Dauer: %.1f Sekunden\n", $end - $start);
print "End of main program\n";




#Functions
sub snmpwalkresult($$){

		my $oid = shift;
		my $mib = shift;

		#printf "Err: %s\n", $session->error();

    my $result = $session->get_table(
    	-baseoid		=>	$oid,
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
		#	my $value = $hash_ref->{ $key }->{ $mib };
		#	print "VALUE: $value\n";
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
    	-varbindlist		=>	[ $if_oid ],
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
    	-baseoid		=>	"$oid.1",
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
    	-baseoid		=>	"$oid.2",
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
	my $nagiosuser = "db_user";
	my $nagiospassword = "secret_dbpasswd";
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
	#	push(@array,$host_elements[$i]);
	#	$i++;
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
	print "\nhalfduplexwalk is a little tool to check status of Half-Duplex status and description on switchports";
	print "\nSyntax:\t macsearch.pl -b ndl -m <mac>\n";
	exit 1;
}
