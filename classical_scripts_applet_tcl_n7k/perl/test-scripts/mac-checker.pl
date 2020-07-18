use strict;
use Net::SNMP;
use Getopt::Std;
use DBI();
use Parallel::ForkManager;


sub snmpwalkresult($$);
sub snmpget_ifindex($$$);
sub snmpset_copyconfig($$$);
sub macresult($$$);;
sub vlan_mac_resolution();
sub string_to_hex($);
sub collect_nagios_host($$);
sub insert_into_text($$);


#Variablen

#global variables
#database network
#my $net_host = "syslog";
#my $net_database = "db_user";
#my $net_user = "syslog";
#my $net_password = "syslogpwd";

#snmp variables
#snmp variable f�r interface_status
my $oid_InterfaceShortName = "1.3.6.1.2.1.31.1.1.1.1";
my $oid_TrunkMode = "1.3.6.1.4.1.9.9.46.1.6.1.1.14";
my $oid_VlanId = "1.3.6.1.4.1.9.9.68.1.2.2.1.2";
#my $oid_loclLineProto = "1.3.6.1.4.1.9.2.2.1.1.2";
my $oid_ifAdminStatus = "1.3.6.1.2.1.2.2.1.7";
my $oid_ifOperStatus = "1.3.6.1.2.1.2.2.1.8";
my $oid_PortDescr = "1.3.6.1.4.1.9.2.2.1.1.28";
#my $oid_ifDescr = "1.3.6.1.2.1.2.2.1.2";
my $oid_ifSpeed = "1.3.6.1.2.1.2.2.1.5";

#snmp variable f�r interface_time
#my $oid_LastInTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.1";
#my $oid_LastOutTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.2";
#my $oid_LastOutHangTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.3";

#snmp variable f�r interface_portsecurity
#my $oid_PortSecurityEnable = "1.3.6.1.4.1.9.9.315.1.2.1.1.1";
#my $oid_PortSecurityStatus = "1.3.6.1.4.1.9.9.315.1.2.1.1.2";
#my $oid_MaxSecureMacAddr = "1.3.6.1.4.1.9.9.315.1.2.1.1.3";
#my $oid_SecureLastMacAddress = "1.3.6.1.4.1.9.9.315.1.2.1.1.10";
#my $oid_StickyEnable = "1.3.6.1.4.1.9.9.315.1.2.1.1.15";

#snmp variable f�r interface_dot1x
#my $oid_dot1xAuthControlledPortStatus = "1.0.8802.1.1.1.1.2.1.1.5";
#my $oid_dot1xAuthControlledPortControl = "1.0.8802.1.1.1.1.2.1.1.6";
#my $oid_dot1xAuthReAuthPeriod = "1.0.8802.1.1.1.1.2.1.1.12";
#my $oid_dot1xAuthReAuthEnabled = "1.0.8802.1.1.1.1.2.1.1.13";


#snmp variable f�r interface_errors
#my $oid_ifInDiscards = "1.3.6.1.2.1.2.2.1.13";
#my $oid_ifInErrors = "1.3.6.1.2.1.2.2.1.14";
#my $oid_ifLastChange = "1.3.6.1.2.1.2.2.1.9";
#my $oid_ifOutDiscards = "1.3.6.1.2.1.2.2.1.19";
#my $oid_ifOutErrors = "1.3.6.1.2.1.2.2.1.20";
#my $oid_RuntsError = "1.3.6.1.4.1.9.9.276.1.1.1.1.4";
#my $oid_GiantsError = "1.3.6.1.4.1.9.9.276.1.1.1.1.5";
#my $oid_FramingError = "1.3.6.1.4.1.9.9.276.1.1.1.1.6";
#my $oid_OverrunError = "1.3.6.1.4.1.9.9.276.1.1.1.1.7";
#my $oid_IgnoredError = "1.3.6.1.4.1.9.9.276.1.1.1.1.8";
#my $oid_AbortError = "1.3.6.1.4.1.9.9.276.1.1.1.1.9";
#my $oid_InputQueueDrops = "1.3.6.1.4.1.9.9.276.1.1.1.1.10";
#my $oid_OutputQueueDrops = "1.3.6.1.4.1.9.9.276.1.1.1.1.11";
#my $oid_loclfCollisions = "1.3.6.1.4.1.9.2.2.1.1.25";
#my $oid_InCRC = "1.3.6.1.4.1.9.2.2.1.1.12";
#my $oid_PacketDiscontinuintyTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.12";

#snmp variable f�r interface_stp
#my $oid_stpPortfast = "1.3.6.1.4.1.9.9.82.1.9.3.1.2";
#my $oid_stpBpduGuard = "1.3.6.1.4.1.9.9.82.1.9.3.1.4";
#my $oid_stpLoopGuard = "1.3.6.1.4.1.9.9.82.1.8.1.1.2";

#snmp variable f�r interface_diagnostic
#my $oid_TdrIfResultPairIndex = "1.3.6.1.4.1.9.9.390.1.2.2.1.1";
#my $oid_TdrIfResultPairChannel = "1.3.6.1.4.1.9.9.390.1.2.2.1.2";
#my $oid_TdrIfResultPairLength = "1.3.6.1.4.1.9.9.390.1.2.2.1.3";
#my $oid_TdrIfResultPairLenAccuracy = "1.3.6.1.4.1.9.9.390.1.2.2.1.4";
#my $oid_TdrIfResultPairDistToFault = "1.3.6.1.4.1.9.9.390.1.2.2.1.5";
#my $oid_TdrIfResultPairDistAccuracy = "1.3.6.1.4.1.9.9.390.1.2.2.1.6";
#my $oid_TdrIfResultPairLengthUnit = "1.3.6.1.4.1.9.9.390.1.2.2.1.7";
#my $oid_TdrIfResultPairStatus = "1.3.6.1.4.1.9.9.390.1.2.2.1.8";

#snmp variable f�r mac-address
my $oid_macaddress = "1.3.6.1.2.1.17.4.3.1";
my $oid_getInterfaceIndex = "1.3.6.1.2.1.17.1.4.1.2";

my $temp = "";
my $temp_main = "Interface\tMac-Address\tVLAN\tTrunk\t\tSpeed\t\tDescription\t";
$temp_main .= "Port-Status\tOperation-Status\tDate\n";
$temp_main .= "--------------------------------------------------------------------------------------------------";
$temp_main .= "-----------------------------\n";
insert_into_text($temp_main,"switchdb_main");

print "Starting main program\n";
#Fork of 10 Processes
my $pm = Parallel::ForkManager->new(10);

#snmp-session value
my $session;
my $error;

#Nagios-Daten holen
#Nagios-Gruppe definieren - es wird nur der Gruppenname ben�tigt
my $ndl = "%";
my $switch_group = "Dot1x-Client-Switch";
#my $switch_group = "FW_Check_Switch";
#host_array aus nagios_db abfrage mittels hostgroup
my $parameter = $ARGV[0];
chomp($parameter);
if (defined $ARGV[0]){
	if (length($parameter) != 4 ){
		die "Error wrong parameter - please type perl <program> -<ndl> or only perl <program>\n";
	}
	$parameter = substr($parameter,1,4);
	$ndl = $parameter;
} else {
	$ndl = "%";
}
print "Niederlassung: $ndl\n";
#exit 1;
my @nagios_hosts = collect_nagios_host($switch_group,$ndl);

#erstellen der initial value_variablen
my $hash_ref;
my ($interface, $vlanid, $trunk) = ( "", 0, 0 );
my ( $adminstatus, $operstatus, $ifspeed, $portdesc ) = ( 0, 0, " ", " " );
#my ( $lastintime, $lastouttime , $lastouthangtime, $inputqueuedrops, $outputqueuedrops ) = ( 0, 0, 0, 0, 0 );
#my ( $ifdescr, $lineproto ) = ( " ", " " );
#my ( $runts, $giants, $framing, $overrun, $ignored, $abort, $in_discards ) = ( 0, 0, 0, 0, 0, 0, 0 );
#my ( $in_errors, $lastchange, $out_discards, $out_errors, $collisions, $crc) = ( 0, 0, 0, 0, 0, 0 );
#my ( $dot1x, $dot1x_reauth, $dot1x_status, $dot1x_period ) = ( 0, 0, 0, 0 );
#my ( $portsec_status, $portsec_enable, $maxsecuremacaddr, $lastsecuremacaddr, $stickyenable ) = ( 0, 0, 0, 0, 0 );
#my ( $stpBpduguard, $stpLoopguard, $stpPortfast ) = ( 0, 0, 0 );
#my ( $pairindex, $pairchannel, $pairlength, $pairlenaccuracy, $pairdisttofault ) = ( "", "", "", "", "" );
#my ( $pairdistaccuracy, $pairlengthunit, $pairstatus ) = ( "", "", "" );
my $macaddress = " ";
my $anzahl_check_hosts = 0;

foreach my $hostname (sort @nagios_hosts){
	$pm->start and next;

	my @done;

	if ($hostname =~ /internal-gateway/){
		next;
	} elsif ($hostname =~ /acp/){
		next;
	}
	print "$hostname:\t";
	$hash_ref = {};
	$anzahl_check_hosts++;

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
	$hash_ref = snmpwalkresult($oid_InterfaceShortName,'interfacename');
	$hash_ref = snmpwalkresult($oid_TrunkMode,'trunkmode');
	$hash_ref = snmpwalkresult($oid_VlanId,'vlanid');
	$hash_ref = snmpwalkresult($oid_ifAdminStatus,'ifadminstatus');
	$hash_ref = snmpwalkresult($oid_ifOperStatus,'ifoperstatus');
	$hash_ref = snmpwalkresult($oid_PortDescr,'portdescr');
	#$hash_ref = snmpwalkresult($oid_ifDescr,'ifdescr');
	$hash_ref = snmpwalkresult($oid_ifSpeed,'ifspeed');


	#get mac-address from mac-address-table on switch with vlan-id
	my @vlans = vlan_mac_resolution();

	foreach my $vid (sort @vlans){
			#print "VLAN-ID: $vid\n";
			if (($vid == 661) or ($vid == 662) or ($vid == 664) or ($vid == 665) ){
				next;
			}
			$hash_ref = macresult($oid_macaddress,'macaddress',"vlan-$vid");
			if (!defined $hash_ref){
				print "$hostname kann folgende VLAN-ID: $vid nicht aufloesen!\n";
			}
	}
	#a dumper for values in the hash_reference
	#print Dumper $hash_ref;
	#a simple output - insert into syslog_db or text
	$temp = "Host:\t $hostname\n";
	$temp .= "--------------------------------------------------------------------------------------------------";
	$temp .= "-----------------------------\n";
	insert_into_text($temp,"switchdb_main");

	foreach my $key (sort{$a <=> $b} keys %$hash_ref){

		#werte aus referenz in variablen laden
		#interface-main
		$interface = $hash_ref->{ $key }->{ 'interfacename' };
		$vlanid = $hash_ref->{ $key }->{ 'vlanid' };
		$trunk = $hash_ref->{ $key }->{ 'trunkmode' };
		$macaddress = $hash_ref->{ $key }->{ 'macaddress' };
		#$ifdescr = $hash_ref->{ $key }->{ 'ifdescr' };
		$ifspeed = $hash_ref->{ $key }->{ 'ifspeed' };
		$adminstatus = $hash_ref->{ $key }->{ 'ifadminstatus' };
		$operstatus = $hash_ref->{ $key }->{ 'ifoperstatus' };
		$portdesc = $hash_ref->{ $key }->{ 'portdescr' };

		#entscheidungsbaum
		#wenn interface_name nicht mit Gi oder Fa beginnt -> next
		if (!defined $interface){
			next;
		}else{
			push(@done,"Done!\n");
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
		#BEGIN der Ausgabe
		if ($interface =~ /Gi\d\/0\/\d\d/){
			$temp_main = "$interface\t";
		} else {
			$temp_main = "$interface\t\t";
		}
		if (($macaddress eq "none") or ($macaddress eq "undef")){
			$temp_main .= "$macaddress\t\t";
		} else {
			$temp_main .= "$macaddress\t";
		}
		if ( length($portdesc) < 16 ){
			if ( length($portdesc) < 8 ){
				$temp_main .= "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t\t$adminstatus\t$operstatus\n";
			}else {
				$temp_main .= "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t$adminstatus\t$operstatus\n";
			}
		}else{
			$temp_main .= "$vlanid\t$trunk\t$ifspeed\t$portdesc\t$adminstatus\t$operstatus\n";
		}

		insert_into_text($temp_main,"switchdb_main");
	}
	@done = &del_doubles(@done);
	if (scalar(@done) == 0){
		#print "Empty!\n";
	} else {
		#print @done;
	}
	# Close the snmp-read session
	$session->close();

	$pm->finish;
}
$pm->wait_all_children;

print "End of main program\n";




#Functions
sub snmpwalkresult($$){

		my $oid = shift;
		my $mib = shift;

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