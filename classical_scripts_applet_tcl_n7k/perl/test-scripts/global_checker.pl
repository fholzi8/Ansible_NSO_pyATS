

#loading modules
use strict;
use Net::SNMP;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use Mysql;
use DateTime;

sub mailalert($$);
sub snmpwalkresult($$);
sub snmpwalkstp($$);
sub snmpwalktdr($$);
sub snmpget_ifindex($$$);
sub snmpset_copyconfig($$$);
sub macresult($$$);
sub collect_nagios_host($);
sub vlan_mac_resolution();
sub string_to_hex($);
sub insert_into_text($$);
sub insert_snmp_data_switchdb_main($$$$$$$$$$);
sub insert_snmp_data_dot1x($$$$$$$);
sub insert_snmp_data_portsec ($$$$$$$);
sub	insert_snmp_data_spanningtree ($$$$$$);
sub	insert_snmp_data_diagnostic ($$$$$$$$$);
sub	insert_snmp_data_error ($$$$$$$$$$$$$$$$$);

#global variables
#database network
my $net_host = "syslog";
my $net_database = "db_user";
my $net_user = "syslog";
my $net_password = "syslogpwd";

#snmp variables
#snmp variable f�r interface_status
my $oid_InterfaceShortName = "1.3.6.1.2.1.31.1.1.1.1";
my $oid_TrunkMode = "1.3.6.1.4.1.9.9.46.1.6.1.1.14";
my $oid_VlanId = "1.3.6.1.4.1.9.9.68.1.2.2.1.2";
my $oid_loclLineProto = "1.3.6.1.4.1.9.2.2.1.1.2";
my $oid_ifAdminStatus = "1.3.6.1.2.1.2.2.1.7";
my $oid_ifOperStatus = "1.3.6.1.2.1.2.2.1.8";
my $oid_PortDescr = "1.3.6.1.4.1.9.2.2.1.1.28";
my $oid_ifDescr = "1.3.6.1.2.1.2.2.1.2";
my $oid_ifSpeed = "1.3.6.1.2.1.2.2.1.5";

#snmp variable f�r interface_time
my $oid_LastInTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.1";
my $oid_LastOutTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.2";
my $oid_LastOutHangTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.3";

#snmp variable f�r interface_portsecurity
my $oid_PortSecurityEnable = "1.3.6.1.4.1.9.9.315.1.2.1.1.1";
my $oid_PortSecurityStatus = "1.3.6.1.4.1.9.9.315.1.2.1.1.2";
my $oid_MaxSecureMacAddr = "1.3.6.1.4.1.9.9.315.1.2.1.1.3";
my $oid_SecureLastMacAddress = "1.3.6.1.4.1.9.9.315.1.2.1.1.10";
my $oid_StickyEnable = "1.3.6.1.4.1.9.9.315.1.2.1.1.15";

#snmp variable f�r interface_dot1x
my $oid_dot1xAuthControlledPortStatus = "1.0.8802.1.1.1.1.2.1.1.5";
my $oid_dot1xAuthControlledPortControl = "1.0.8802.1.1.1.1.2.1.1.6";
my $oid_dot1xAuthReAuthPeriod = "1.0.8802.1.1.1.1.2.1.1.12";
my $oid_dot1xAuthReAuthEnabled = "1.0.8802.1.1.1.1.2.1.1.13";


#snmp variable f�r interface_errors
my $oid_ifInDiscards = "1.3.6.1.2.1.2.2.1.13";
my $oid_ifInErrors = "1.3.6.1.2.1.2.2.1.14";
my $oid_ifLastChange = "1.3.6.1.2.1.2.2.1.9";
my $oid_ifOutDiscards = "1.3.6.1.2.1.2.2.1.19";
my $oid_ifOutErrors = "1.3.6.1.2.1.2.2.1.20";
my $oid_RuntsError = "1.3.6.1.4.1.9.9.276.1.1.1.1.4";
my $oid_GiantsError = "1.3.6.1.4.1.9.9.276.1.1.1.1.5";
my $oid_FramingError = "1.3.6.1.4.1.9.9.276.1.1.1.1.6";
my $oid_OverrunError = "1.3.6.1.4.1.9.9.276.1.1.1.1.7";
my $oid_IgnoredError = "1.3.6.1.4.1.9.9.276.1.1.1.1.8";
my $oid_AbortError = "1.3.6.1.4.1.9.9.276.1.1.1.1.9";
my $oid_InputQueueDrops = "1.3.6.1.4.1.9.9.276.1.1.1.1.10";
my $oid_OutputQueueDrops = "1.3.6.1.4.1.9.9.276.1.1.1.1.11";
my $oid_loclfCollisions = "1.3.6.1.4.1.9.2.2.1.1.25";
my $oid_InCRC = "1.3.6.1.4.1.9.2.2.1.1.12";
my $oid_PacketDiscontinuintyTime = "1.3.6.1.4.1.9.9.276.1.1.1.1.12";

#snmp variable f�r interface_stp
my $oid_stpPortfast = "1.3.6.1.4.1.9.9.82.1.9.3.1.2";
my $oid_stpBpduGuard = "1.3.6.1.4.1.9.9.82.1.9.3.1.4";
my $oid_stpLoopGuard = "1.3.6.1.4.1.9.9.82.1.8.1.1.2";

#snmp variable f�r interface_diagnostic
#my $oid_TdrIfResultPairIndex = "1.3.6.1.4.1.9.9.390.1.2.2.1.1";
my $oid_TdrIfResultPairChannel = "1.3.6.1.4.1.9.9.390.1.2.2.1.2";
my $oid_TdrIfResultPairLength = "1.3.6.1.4.1.9.9.390.1.2.2.1.3";
my $oid_TdrIfResultPairLenAccuracy = "1.3.6.1.4.1.9.9.390.1.2.2.1.4";
my $oid_TdrIfResultPairDistToFault = "1.3.6.1.4.1.9.9.390.1.2.2.1.5";
my $oid_TdrIfResultPairDistAccuracy = "1.3.6.1.4.1.9.9.390.1.2.2.1.6";
my $oid_TdrIfResultPairLengthUnit = "1.3.6.1.4.1.9.9.390.1.2.2.1.7";
my $oid_TdrIfResultPairStatus = "1.3.6.1.4.1.9.9.390.1.2.2.1.8";

#snmp variable f�r mac-address
my $oid_macaddress = "1.3.6.1.2.1.17.4.3.1";
my $oid_getInterfaceIndex = "1.3.6.1.2.1.17.1.4.1.2";


#erstellen der value_variablen
my $hash_ref;
my ($interface, $vlanid, $trunk) = ( "", 0, 0 );
my ( $adminstatus, $operstatus, $ifspeed, $ifdescr ) = ( 0, 0, " ", " " );
my ( $lastintime, $lastouttime , $lastouthangtime, $inputqueuedrops, $outputqueuedrops ) = ( 0, 0, 0, 0, 0 );
my ( $portdesc, $lineproto ) = ( " ", " " );
my ( $runts, $giants, $framing, $overrun, $ignored, $abort, $in_discards ) = ( 0, 0, 0, 0, 0, 0, 0 );
my ( $in_errors, $lastchange, $out_discards, $out_errors, $collisions, $crc) = ( 0, 0, 0, 0, 0, 0 );
my ( $dot1x, $dot1x_reauth, $dot1x_status, $dot1x_period ) = ( 0, 0, 0, 0 );
my ( $portsec_status, $portsec_enable, $maxsecuremacaddr, $lastsecuremacaddr, $stickyenable ) = ( 0, 0, 0, 0, 0 );
my ( $stpBpduguard, $stpLoopguard, $stpPortfast ) = ( 0, 0, 0 );
my ( $pairindex, $pairchannel, $pairlength, $pairlenaccuracy, $pairdisttofault ) = ( "", "", "", "", "" );
my ( $pairdistaccuracy, $pairlengthunit, $pairstatus ) = ( "", "", "" );

#my $hostname = "";


my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

my $macaddress = " ";
my $anzahl_check_hosts = 0;

my $session;
my $error;

#sammeln der nagios_hosts
my $dot1x_group = "Dot1x-Client-Switch";
my $network_group = "Network_Devices";
#host_array aus nagios_db abfrage mittels hostgroup
my @hosts = collect_nagios_host($network_group);

my $temp = "";
my $temp_main = "Interface\tMac-Address\tVLAN\tTrunk\t\tSpeed\t\tDescription\t";
$temp_main .= "Port-Status\tOperation-Status\tDate\n";
$temp_main .= "--------------------------------------------------------------------------------------------------";
$temp_main .= "-----------------------------\n";
my $temp_dot1x = "Interface\tDot1x-Enable\tDot1x-Status\tReauthentication\tRe-Period\tMust_not\n";
$temp_dot1x .= "--------------------------------------------------------------------------------------------------";
$temp_dot1x .= "-----------------------------\n";
my $temp_portsec = "Interface\tPortsec-Enable\tPortsec-Status\tMax-Mac-Address\tSticky-Enable\n";
$temp_portsec .= "--------------------------------------------------------------------------------------------------";
$temp_portsec .= "-----------------------------\n";
my $temp_stp = "Interface\tPortfast\tBpduGuard\tLoopguard\n";
$temp_stp .= "--------------------------------------------------------------------------------------------------";
$temp_stp .= "-----------------------------\n";
my $temp_error = "Interface\tRunts\tGiants\tFraming\tOverrun\tIgnored\tAbort\tInDrops\tOutDrops\t";
$temp_error .= "InDis\tInErr\tOurDis\tOutErr\tCollisions\tCRC\n";
$temp_error .= "--------------------------------------------------------------------------------------------------";
$temp_error .= "-----------------------------\n";
my $temp_dia = "Interface\tPairChannel\tPairLength\tLengthAccurancy\t";
$temp_dia .= "Disttofault\tDisttoaccuracy\tLengthUnit\n";
$temp_dia .= "--------------------------------------------------------------------------------------------------";
$temp_dia .= "-----------------------------\n";
insert_into_text($temp_main,"switchdb_main");
insert_into_text($temp_dot1x,"dot1x");
insert_into_text($temp_portsec,"portsec");
insert_into_text($temp_stp,"spanningtree");
insert_into_text($temp_error,"switchport_error");
insert_into_text($temp_dia,"switchport_diagnostic");

foreach my $hostname (sort @hosts){
	
	
	
	my @done;

	if ($hostname =~ /internal-gateway/){
		next;
	} elsif ($hostname =~ /acp/){
		next;
	} elsif ($hostname =~ /polycom/i){
		next;
	} elsif ($hostname =~ /vpn/){
		next;
	#} elsif ($hostname =~ /blade/){
	#	next;
	} elsif ($hostname =~ /mls/){
		next;
	} elsif ($hostname =~ /rt/){
		next;
	}	elsif ($hostname =~ /swt109/){
		next;
	} elsif ($hostname =~ /swt110/){
		next;
	} elsif ($hostname =~ /swt4\d/){
		next;
	}	elsif ($hostname =~ /swt5\d/){
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
	
	#Port-Security
	$hash_ref = snmpwalkresult($oid_PortSecurityEnable,'portsecurityenable');
	$hash_ref = snmpwalkresult($oid_PortSecurityStatus,'portsecuritystatus');
	$hash_ref = snmpwalkresult($oid_MaxSecureMacAddr,'maxsecuremacaddr');
	#$hash_ref = snmpwalkresult($oid_SecureLastMacAddress,'securelastmacaddress');
	$hash_ref = snmpwalkresult($oid_StickyEnable,'stickyenable');
	
	#Errors
	#$hash_ref = snmpwalkresult($oid_LastInTime,'lastintime');
	#$hash_ref = snmpwalkresult($oid_LastOutTime,'lastouttime');
	#$hash_ref = snmpwalkresult($oid_LastOutHangTime,'lastouthangtime');
	$hash_ref = snmpwalkresult($oid_RuntsError,'runtserror');
	$hash_ref = snmpwalkresult($oid_GiantsError,'giantserror');
	$hash_ref = snmpwalkresult($oid_FramingError,'framingerror');
	$hash_ref = snmpwalkresult($oid_OverrunError,'overrunerror');
	$hash_ref = snmpwalkresult($oid_IgnoredError,'ignorederror');
	$hash_ref = snmpwalkresult($oid_AbortError,'aborterror');
	$hash_ref = snmpwalkresult($oid_InputQueueDrops,'inputqueuedrops');
	$hash_ref = snmpwalkresult($oid_OutputQueueDrops,'outputqueuedrops');
	#$hash_ref = snmpwalkresult($oid_PacketDiscontinuintyTime,'packetdiscontinuintytime');
	$hash_ref = snmpwalkresult($oid_ifInDiscards,'ifindiscards');
	$hash_ref = snmpwalkresult($oid_ifInErrors,'ifinerrors');
	#$hash_ref = snmpwalkresult($oid_ifLastChange,'iflastchange');
	$hash_ref = snmpwalkresult($oid_ifOutDiscards,'ifoutdiscards');
	$hash_ref = snmpwalkresult($oid_ifOutErrors,'ifouterrors');
	#$hash_ref = snmpwalkresult($oid_loclLineProto,'locllineproto');
	$hash_ref = snmpwalkresult($oid_loclfCollisions,'loclfcollisions');
	$hash_ref = snmpwalkresult($oid_InCRC,'incrc');
	
	#Spanning-Tree
	$hash_ref = snmpwalkstp($oid_stpPortfast,'stpportfast');
	$hash_ref = snmpwalkstp($oid_stpBpduGuard,'stpbpduguard');
	$hash_ref = snmpwalkstp($oid_stpLoopGuard,'stploopguard');
	
	#Diagnostic
	if ($hostname !~ /muc/ ){
		#Dot1x
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortControl,'dot1xauthcontrolledportcontrol');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthEnabled,'dot1xauthreauthenabled');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthPeriod,'dot1xperiod');
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortStatus,'dot1xstatus');
		
		#Diagnostic
		#$hash_ref = snmpwalkresult($oid_TdrIfResultPairIndex,'tdrpairindex');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairChannel,'tdrpairchannel');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLength,'tdrpairlength');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLenAccuracy,'tdrpairlenaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistToFault,'tdrpairdisttofault');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistAccuracy,'tdrpairdistaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLengthUnit,'tdrpairlengthunit');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairStatus,'tdrpairstatus');
	}
	if ($hostname =~ /muc-1\d/){
		#Dot1x
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortControl,'dot1xauthcontrolledportcontrol');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthEnabled,'dot1xauthreauthenabled');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthPeriod,'dot1xperiod');
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortStatus,'dot1xstatus');
		
		#Diagnostic
		#$hash_ref = snmpwalkresult($oid_TdrIfResultPairIndex,'tdrpairindex');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairChannel,'tdrpairchannel');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLength,'tdrpairlength');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLenAccuracy,'tdrpairlenaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistToFault,'tdrpairdisttofault');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistAccuracy,'tdrpairdistaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLengthUnit,'tdrpairlengthunit');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairStatus,'tdrpairstatus');
	}
	if ($hostname =~ /muc-2\d/){
		#Dot1x
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortControl,'dot1xauthcontrolledportcontrol');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthEnabled,'dot1xauthreauthenabled');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthPeriod,'dot1xperiod');
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortStatus,'dot1xstatus');
		
		#Diagnostic
		#$hash_ref = snmpwalkresult($oid_TdrIfResultPairIndex,'tdrpairindex');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairChannel,'tdrpairchannel');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLength,'tdrpairlength');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLenAccuracy,'tdrpairlenaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistToFault,'tdrpairdisttofault');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistAccuracy,'tdrpairdistaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLengthUnit,'tdrpairlengthunit');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairStatus,'tdrpairstatus');
	}
	if ($hostname =~ /muc-3\d/){
		#Dot1x
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortControl,'dot1xauthcontrolledportcontrol');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthEnabled,'dot1xauthreauthenabled');
		$hash_ref = snmpwalkresult($oid_dot1xAuthReAuthPeriod,'dot1xperiod');
		$hash_ref = snmpwalkresult($oid_dot1xAuthControlledPortStatus,'dot1xstatus');
		
		#Diagnostic
		#$hash_ref = snmpwalkresult($oid_TdrIfResultPairIndex,'tdrpairindex');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairChannel,'tdrpairchannel');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLength,'tdrpairlength');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLenAccuracy,'tdrpairlenaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistToFault,'tdrpairdisttofault');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairDistAccuracy,'tdrpairdistaccuracy');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairLengthUnit,'tdrpairlengthunit');
		$hash_ref = snmpwalktdr($oid_TdrIfResultPairStatus,'tdrpairstatus');
	}
	
	
	
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
	insert_into_text($temp,"dot1x");
	insert_into_text($temp,"portsec");
	insert_into_text($temp,"spanningtree");
	insert_into_text($temp,"switchport_error");
	insert_into_text($temp,"switchport_diagnostic");
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
		
		#errors
		#$lastintime = $hash_ref->{ $key }->{ 'lastintime' };
		#$lastouttime = $hash_ref->{ $key }->{ 'lastouttime' };
		#$lastouthangtime = $hash_ref->{ $key }->{ 'lastouthangtime' };
		$runts = $hash_ref->{ $key }->{ 'runtserror' };
		$giants = $hash_ref->{ $key }->{ 'giantserror' };
		$framing = $hash_ref->{ $key }->{ 'framingerror' };
		$overrun = $hash_ref->{ $key }->{ 'overrunerror' };
		$ignored = $hash_ref->{ $key }->{ 'ignorederror' };
		$abort = $hash_ref->{ $key }->{ 'aborterror' };
		$inputqueuedrops = $hash_ref->{ $key }->{ 'inputqueuedrops' };
		$outputqueuedrops = $hash_ref->{ $key }->{ 'outputqueuedrops' };
		#$packetdiscontinuintytime = $hash_ref->{ $key }->{ 'packetdiscontinuintytime' };
		$in_discards = $hash_ref->{ $key }->{ 'ifindiscards' };
		$in_errors = $hash_ref->{ $key }->{ 'ifinerrors' };
		#$lastchange = $hash_ref->{ $key }->{ 'iflastchange' };
		$out_discards = $hash_ref->{ $key }->{ 'ifoutdiscards' };
		$out_errors = $hash_ref->{ $key }->{ 'ifouterrors' };
		#$lineproto = $hash_ref->{ $key }->{ 'locllineproto' };
		$collisions = $hash_ref->{ $key }->{ 'loclfcollisions' };
		$crc = $hash_ref->{ $key }->{ 'incrc' };
		
		#port-security
		$portsec_enable = $hash_ref->{ $key }->{ 'portsecurityenable' };
		$portsec_status = $hash_ref->{ $key }->{ 'portsecuritystatus' };
		$maxsecuremacaddr = $hash_ref->{ $key }->{ 'maxsecuremacaddr' };
		#$lastsecuremacaddr = $hash_ref->{ $key }->{ 'securelastmacaddress' };
		$stickyenable = $hash_ref->{ $key }->{ 'stickyenable' };
		
		#dot1x
		$dot1x = $hash_ref->{ $key }->{ 'dot1xauthcontrolledportcontrol' };
		$dot1x_reauth = $hash_ref->{ $key }->{ 'dot1xauthreauthenabled' };
		$dot1x_period = $hash_ref->{ $key }->{ 'dot1xperiod' };
		$dot1x_status = $hash_ref->{ $key }->{ 'dot1xstatus' };
		
		#spanning-tree
		$stpPortfast = $hash_ref->{ $key }->{ 'stpportfast' };
		$stpBpduguard = $hash_ref->{ $key }->{ 'stpbpduguard' };
		$stpLoopguard = $hash_ref->{ $key }->{ 'stploopguard' };
	
		#diagnostic
		#$pairindex = $hash_ref->{ $key }->{ 'tdrpairindex'};
	  $pairchannel = $hash_ref->{ $key }->{ 'tdrpairchannel'};
	  $pairlength = $hash_ref->{ $key }->{ 'tdrpairlength'};
	  $pairlenaccuracy = $hash_ref->{ $key }->{ 'tdrpairlenaccuracy'};
	  $pairdisttofault = $hash_ref->{ $key }->{ 'tdrpairdisttofault'};
	  $pairdistaccuracy = $hash_ref->{ $key }->{ 'tdrpairdistaccuracy'};
	  $pairlengthunit = $hash_ref->{ $key }->{ 'tdrpairlengthunit'};
	  $pairstatus = $hash_ref->{ $key }->{ 'tdrpairstatus'};
	  
		
		#print "FIRST-$hostname: $dot1x##$dot1x_status##$pairchannel##\n";
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
			$vlanid = "undef";
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
		if (!defined $ifdescr) {
			$ifdescr = "undef";
		}
		if (!defined $portdesc) {
			$portdesc = "undef";
		}else{
			$portdesc = substr($portdesc,0,20);
		}
		
		#Port-Security Section
		if (!defined $portsec_enable) {
			$portsec_enable = "undef";
		}else{
			if ($portsec_enable == 1){
				$portsec_enable = "true";
			}elsif ($portsec_enable == 2){
				$portsec_enable = "false";
			}
		}
		if (!defined $portsec_status) {
			$portsec_status = "undef";
		}else{
			if ($portsec_status == 1){
				$portsec_status = "secureup";
			}elsif ($portsec_status == 2){
				$portsec_status = "securedown";
			}elsif ($portsec_status == 3){
				$portsec_status = "shutdown";
			}
		}
		if (!defined $stickyenable) {
			$stickyenable = "undef";
		}else{
			if ($stickyenable == 1){
				$stickyenable = "true";
			}elsif ($stickyenable == 2){
				$stickyenable = "false";
			}
		}
		if (!defined $maxsecuremacaddr) {
			$maxsecuremacaddr = "undef";
		}
		
		#STP Section
		if (!defined $stpPortfast) {
			$stpPortfast = "undef";
		}else{
			if ($stpPortfast == 1){
				$stpPortfast = "true";
			}elsif ($stpPortfast == 2){
				$stpPortfast = "false";
			}
		} 
		if (!defined $stpBpduguard) {
			$stpBpduguard = "undef";
		}else{
			if ($stpBpduguard == 1){
				$stpBpduguard = "enable";
			}elsif ($stpBpduguard == 2){
				$stpBpduguard = "disable";
			}elsif ($stpBpduguard == 3){
				$stpBpduguard = "default";
			}
		}
		if (!defined $stpLoopguard) {
			$stpLoopguard = "undef";
		}else{
			if ($stpLoopguard == 1){
				$stpLoopguard = "true";
			}elsif ($stpLoopguard == 2){
				$stpLoopguard = "false";
			}
		}
		
		#Dot1x Section
		if (!defined $dot1x) {
			$dot1x = "undef";
		}else{
			if ($dot1x == 1){
				$dot1x = "forceUnauthorized";
			}elsif ($dot1x == 2){
				$dot1x = "auto";
			}elsif ($dot1x == 3){
				$dot1x = "forceAuthorized";
			}
		}if (!defined $dot1x_reauth) {
			$dot1x_reauth = "undef";
		}else{
			if ($dot1x_reauth == 1){
				$dot1x_reauth = "true";
			}elsif ($dot1x_reauth == 2){
				$dot1x_reauth = "false";
			}
		}
		if (!defined $dot1x_period) {
			$dot1x_period = "undef";
		}else {
			$dot1x_period = (int($dot1x_period) / 60);
		}
		if (!defined $dot1x_status) {
			$dot1x_status = "undef";
		}else{
			if ($dot1x_status == 1){
				$dot1x_status = "true";
			}elsif ($dot1x_status == 2){
				$dot1x_status = "false";
			}
		}
		#print "dot1x: $dot1x#$dot1x_reauth#$dot1x_period#$dot1x_status\n";
		#Error Section
		if (!defined $runts){
			$runts = "undef";
		}
		if (!defined $giants){
			$giants = "undef";
		}
		if (!defined $framing){
			$framing = "undef";
		}
		if (!defined $overrun){
			$overrun = "undef";
		}
		if (!defined $ignored){
			$ignored = "undef";
		}
		if (!defined $abort){
			$abort = "undef";
		}
		if (!defined $inputqueuedrops){
			$inputqueuedrops = "undef";
		}
		if (!defined $outputqueuedrops){
			$outputqueuedrops = "undef";
		}
		if (!defined $in_discards){
			$in_discards = "undef";
		}
		if (!defined $in_errors){
			$in_errors = "undef";
		}
		if (!defined $lastchange){
			$lastchange = "undef";
		}
		if (!defined $out_discards){
			$out_discards = "undef";
		}
		if (!defined $out_errors){
			$out_errors = "undef";
		}
		if (!defined $collisions){
			$collisions = "undef";
		}
		if (!defined $crc){
			$crc = "undef";
		}

		#Diagnostic  -  ben�tigt kronjob der 
		if (($portsec_enable eq "false") or ($adminstatus eq "down")) { next; }
		
		if (!defined $pairchannel){
			$pairchannel = "undef";
			next;
			#print "TDR-Tabelle nicht verfuegbar\n";
		}#else{
		#	my @array = split(/#/,$pairchannel);
		#	$pairchannel = "";
		#	foreach my $element (@array){
		#		if ($element == 1){
		#			$pairchannel .= "other\t";
		#		}elsif ($element == 2){
		#			$pairchannel .= "channelA\t";
		#		}elsif ($element == 3){
		#			$pairchannel .= "channelB\t";
		#		}elsif ($element == 4){
		#			$pairchannel .= "channelC\t";
		#		}elsif ($element == 5){
		#			$pairchannel .= "channelD\t";
		#		}
		#	}
		#}
		if (!defined $pairlengthunit){
			$pairlengthunit = "undef";
		}#else{
		#	my @array = split(/#/,$pairlengthunit);
		#	$pairlengthunit = "";
		#	foreach my $element (@array){
		#		if ($element == 1){
		#			$pairlengthunit .= "unknown\t";
		#		}elsif ($element == 2){
		#			$pairlengthunit .= "m\t";
		#		}elsif ($element == 3){
		#			$pairlengthunit .= "cm\t";
		#		}elsif ($element == 4){
		#			$pairlengthunit .= "km\t";
		#		}
		#	}
		#}
		if (!defined $pairlength){
			$pairlength = "undef";
		}#else{
		#	my @array = split(/#/,$pairlength);
		#	$pairlength = "";
		#	my $meter = $pairlengthunit;
		#	$meter =~ s/.*(\w)\s+\w.*/$1/g;
		#	foreach my $element (@array){
		#		if ($element eq -1){
		#			$pairlength .= "invalid\t";
		#		}else{
		#			$pairlength .= "$element $meter\t";
		#		}
		#	}
		#}
		if (!defined $pairlenaccuracy){
			$pairlenaccuracy = "undef";
		}#else{
		#	my @array = split(/#/,$pairlenaccuracy);
		#	$pairlenaccuracy = "";
		#	my $meter = $pairlengthunit;
		#	$meter =~ s/.*(\w)\s+\w.*/$1/g;
		#	foreach my $element (@array){
		#		if ($element eq -1){
		#			$pairlenaccuracy .= "invalid\t";
		#		}else{
		#			$pairlenaccuracy .= "+/-$element $meter\t";
		#		}
		#	}
		#}
		if (!defined $pairdisttofault){
			$pairdisttofault = "undef";
		}#else{
		#	my @array = split(/#/,$pairdisttofault);
		#	$pairdisttofault = "";
		#	my $meter = $pairlengthunit;
		#	$meter =~ s/.*(\w)\s+\w.*/$1/g;
		#	foreach my $element (@array){
		#		if ($element eq -1){
		#			$pairdisttofault .= "invalid\t";
		#		}else{
		#			$pairdisttofault .= "$element $meter\t";
		#		}
		#	}
		#}
			
		if (!defined $pairdistaccuracy){
			$pairdistaccuracy = "undef";
		}#else{
		#	my @array = split(/#/,$pairdistaccuracy);
		#	$pairdistaccuracy = "";
		#	my $meter = $pairlengthunit;
		#	$meter =~ s/.*(\w)\s+\w.*/$1/g;
		#	foreach my $element (@array){
		#		if ($element eq -1){
		#			$pairdistaccuracy .= "invalid\t";
		#		}else{
		#			$pairdistaccuracy .= "+/-$element $meter\t";
		#		}
		#	}
		#}
		
		if (!defined $pairstatus){
			$pairstatus = "undef";
		}#else{
		#	my @array = split(/#/,$pairstatus);
		#	$pairstatus = "";
		#	foreach my $element (@array){
		#		if ($element == 1){
		#			$pairstatus .= "unknown\t";
		#		}elsif ($element == 2){
		#			$pairstatus .= "terminated\t";
		#		}elsif ($element == 3){
		#			$pairstatus .= "notCompleted\t";
		#		}elsif ($element == 4){
		#			$pairstatus .= "notSupported\t";
		#		}elsif ($element == 5){
		#			$pairstatus .= "open\t";
		#		}elsif ($element == 6){
		#			$pairstatus .= "shorted\t";
		#		}elsif ($element == 7){
		#			$pairstatus .= "impedanceMismatch\t";
		#		}elsif ($element == 8){
		#			$pairstatus .= "broken\t";
		#		}
		#	}
		#}
		#print "DIAG: $pairchannel\t$pairstatus\t$pairlength\n";
		my $dt = DateTime->now;
		my $ymd = $dt->ymd;
		my $hms = $dt->hms;
		my $date = "$ymd $hms";
		
		#BEGIN des MYSQL INPUTs
		insert_snmp_data_switchdb_main( $hostname, $interface, $macaddress, $vlanid, $trunk, $ifspeed, $portdesc, $adminstatus, $operstatus, $date);
		insert_snmp_data_dot1x ( $hostname, $interface, $date, $dot1x, $dot1x_status, $dot1x_reauth, $dot1x_period);
		insert_snmp_data_portsec ( $hostname, $interface, $date, $portsec_enable, $portsec_status, $maxsecuremacaddr, $stickyenable);
		insert_snmp_data_spanningtree ( $hostname, $interface, $date, $stpPortfast, $stpBpduguard, $stpLoopguard);
		insert_snmp_data_error ( $hostname, $interface, $date, $runts, $giants, $framing, $overrun, $ignored, $abort, $inputqueuedrops, $outputqueuedrops, $in_discards, $in_errors, $out_discards, $out_errors, $collisions, $crc);
		#keine abfrage f�r server-switche
		if ( ($hostname =~ /demuc-swt0\d/) or ($hostname =~ /demuc-swt1\d\d/) ){
			print "Server-Switch\n";
		} else {
			insert_snmp_data_diagnostic ( $hostname, $interface, $date, $pairchannel, $pairlength, $pairlenaccuracy, $pairdisttofault, $pairdistaccuracy, $pairstatus);
		}
		
		
		#BEGIN der Ausgabe
		if ($interface =~ /Gi\d\/0\/\d\d/){
			$temp_main = "$interface\t";
			$temp_portsec = $temp_main;
			$temp_dot1x = $temp_main;
			$temp_stp = $temp_main;
			$temp_error = $temp_main;
			$temp_dia = $temp_main;
		} else {
			$temp_main = "$interface\t\t";
			$temp_portsec = $temp_main;
			$temp_dot1x = $temp_main;
			$temp_stp = $temp_main;
			$temp_error = $temp_main;
			$temp_dia = $temp_main;
		}
		if (($macaddress eq "none") or ($macaddress eq "undef")){
			$temp_main .= "$macaddress\t\t";
		} else {
			$temp_main .= "$macaddress\t";
		}
		
		
		
		if ( length($portdesc) < 16 ){
			if ( length($portdesc) < 8 ){
				$temp_main .= "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t\t$adminstatus\t$operstatus\t\t$date\n";
			}else {
				$temp_main .= "$vlanid\t$trunk\t$ifspeed\t$portdesc\t\t$adminstatus\t$operstatus\t\t$date\n";
			}
		}else{
			$temp_main .= "$vlanid\t$trunk\t$ifspeed\t$portdesc\t$adminstatus\t$operstatus\t\t$date\n";
		}
		$temp_portsec .= "$portsec_enable\t\t$portsec_status\t\t$maxsecuremacaddr\t$stickyenable\n";
		$temp_dot1x .= "$dot1x\t$dot1x_status\t$dot1x_reauth\t$dot1x_period\t0\n";
		$temp_stp .= "$stpPortfast\t$stpBpduguard\t$stpLoopguard\n";
		$temp_error .= "$runts\t$giants\t$framing\t$overrun\t$ignored\t$abort\t$inputqueuedrops\t";
		$temp_error .= "$outputqueuedrops\t$in_discards\t$in_errors\t$out_discards\t\t$out_errors\t";
		$temp_error .= "$collisions\t\t$crc\n";
		$temp_dia .= "$pairchannel\t$pairlength\t$pairlenaccuracy\t$pairdisttofault\t$pairdistaccuracy\t";
		$temp_dia .= "$pairstatus\n";
		
		insert_into_text($temp_main,"switchdb_main");
		insert_into_text($temp_dot1x,"dot1x");
		insert_into_text($temp_portsec,"portsec");
		insert_into_text($temp_stp,"spanningtree");
		insert_into_text($temp_error,"switchport_error");
		insert_into_text($temp_dia,"switchport_diagnostic");
		
		
		
		#clearen der variablen
		#( $pairindex, $pairchannel, $pairlength, $pairlenaccuracy, $pairdisttofault ) = ( "", "", "", "", "" );
		#( $pairdistaccuracy, $pairlengthunit, $pairstatus ) = ( "", "", "" );
	}
	@done = &del_doubles(@done);
	if (scalar(@done) == 0){
		print "Empty!\n";
	} else {
		print @done;
	}
	# Close the snmp-read session
	$session->close();
}

print "Anzahl der checked hosts:\t $anzahl_check_hosts\n";



#
#function sections
#

#snmp-functions
sub snmpwalkresult($$){
	
		my $oid = shift;
		my $mib = shift;
		
     my $result = $session->get_table(
    	-baseoid		=>	$oid,    	
    );
    
    if (!defined $result){
    	printf "ERROR11: %s\n", $session->error();
    	$session->close();
    	exit 1;
    }
		
		my $list = $session->var_bind_list();
		
		if (!defined $list){
			printf "ERROR21: %s\n", $session->error();
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

sub snmpwalktdr($$){
	
		my $oid = shift;
		my $mib = shift;
		
     my $result = $session->get_table(
    	-baseoid		=>	$oid,    	
    );
    
    if (!defined $result){
    	#printf "ERROR111: %s\n", $session->error();
    	return undef;
    	#hier ein return-bauen undef;
    	#$session->close();
    	#exit 1;
    }
		
		my $list = $session->var_bind_list();
		
		if (!defined $list){
			printf "ERROR211: %s\n", $session->error();
			return;
		}
		
		my @names = $session->var_bind_names();
		my $index = undef;
		my $old_val = "";
		
		
		while (@names){
			$index = shift @names;
			my $value = $list->{$index};
			#print "DEBUG: $mib := $index -> $value\n";
			my ($ifindex, $id) = ( "", 0 );
			if ($index =~ /$oid\.(.*)\.(\d)/){
				$ifindex = $1;
				$id = $2;
			}
			#print "ID: $id\n";
			$old_val = "$old_val#$value";
			if ($id == 4){
				$old_val=substr($old_val,1,length($old_val));
				$hash_ref->{$ifindex}->{$mib} = $old_val;
				#print "Jetzt folgendes writeln $ifindex und $hash_ref->{$ifindex}->{$mib}\n";
				$old_val = "";
			}
			
			
		}
		return $hash_ref;
}

sub snmpwalkstp($$){
	
		my $oid = shift;
		my $mib = shift;
		
     my $result = $session->get_table(
    	-baseoid		=>	$oid,    	
    );
    
    if (!defined $result){
    	printf "ERROR11: %s\n", $session->error();
    	$session->close();
    	exit 1;
    }
		
		my $list = $session->var_bind_list();
		
		if (!defined $list){
			printf "ERROR21: %s\n", $session->error();
			return;
		}
		
		my @names = $session->var_bind_names();
		my $index = undef;
		
		while (@names){
			$index = shift @names;
			my $value = $list->{$index};
			$index =~ s/$oid\.(.*)/$1/g;
			if ($index < 10){
				$index = "1010".$index;
			}else{
				$index = "101".$index;
			}
			#print "DEBUG: $mib := $index -> $value\n";
			$hash_ref->{$index}->{$mib} = $value;
		}
		return $hash_ref;
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
			printf "ERROR22: %s\n", $session->error();
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
    	printf "ERROR13: %s\n", $session->error();
    	$session->close();
    	exit 1;
    }
		my $list_ifindex = $session->var_bind_list();
		if (!defined $list_ifindex){
			printf "ERROR23: %s\n", $session->error();
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
    	printf "ERROR_Get1: %s\n", $session->error();
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

#mail functions
sub mailalert($$){
	my $receiver = shift;
	my $content = shift;
	
	my $email = MIME::Lite->new(
		Subject	=>	'DOT1X ALERT',
		From	=>	'dot1x@company.com',
		To		=>	$receiver,
		Type	=>	'text/html',
		Data	=>	$content
	);
	$email->send();
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
	
#database functions
sub collect_nagios_host($){
	
	my $hostgroup = shift;
	#database nagios
	my $nagioshost = "db_server.company.local:3310";
	my $nagiosdatabase = "nagios";
	my $nagiosuser = "db_user";
	my $nagiospassword = "secret_dbpasswd";
	#connect to nagios_db
	my $db = Mysql->connect($nagioshost, $nagiosdatabase, $nagiosuser, $nagiospassword); 
	$db->selectdb($nagiosdatabase);	
	#select statement (get all host from $hostgroup
	my $querystring = "select h.alias from nagios_hostgroups g, nagios_hostgroup_members m, nagios_hosts h where g.alias = '$hostgroup' and m.host_object_id = h.host_object_id and g.hostgroup_id = m.hostgroup_id order by h.alias";
	my $query = $db->query($querystring);
	my @host_elements;
	my $i = 0;
	my @array;
	while ($host_elements[$i] = $query->fetchrow()){
		push(@array,$host_elements[$i]);
		$i++;
	}
	#return array with "selected" hosts
	return @array;
}
# inserts into tables
sub insert_snmp_data_switchdb_main($$$$$$$$$$){
	
	my $var1 = shift;
	my $var2 = shift;
	my $var3 = shift;
	my $var4 = shift;
	my $var5 = shift;
	my $var6 = shift;
	my $var7 = shift;
	my $var8 = shift;
	my $var9 = shift;
	my $var10 = shift;
			
	#database syslog.config_logger
	my $host = "172.16.2.3";
	my $database = "switchdb";
	my $user = "db_user";
	my $password = "Faqlogsys4u2009!";
	
	#connect to syslog_db
	my $db = Mysql->connect($host, $database, $user, $password); 
	$db->selectdb($database);	
	#insert into switchdb_main values ("demuc-swt10","Gi1/0/1","6c62.6dc2.2400","123","access mode","1.0 Gbit/s","Dot1X Client","up","up",2011-06-16 07:10:31);
	my $querystring = "insert into switchdb_main(hostname,interfaceshortname,macaddress,vlan_id,trunk_mode,ifspped,duplex,interface_description,admin_status,operation_status,date) values ( '$var1','$var2','$var3',$var4,'$var5','$var6', 'not-set','$var7','$var8','$var9', '$var10' )";
	my $query = $db->query($querystring);

}

sub insert_snmp_data_dot1x($$$$$$$){
	
	my $h = shift;
	my $i = shift;
	my $d = shift;
	my $var1 = shift;
	my $var2 = shift;
	my $var3 = shift;
	my $var4 = shift;
	
	#database syslog.config_logger
	my $host = "172.16.2.3";
	my $database = "switchdb";
	my $user = "db_user";
	my $password = "Faqlogsys4u2009!";
	
	#connect to syslog_db
	my $db = Mysql->connect($host, $database, $user, $password); 
	$db->selectdb($database);
	my $querystr = "select main_id from switchdb_main where hostname = '$h' and interfaceshortname = '$i' and date = '$d'";
	#print "query:\t $querystr\n";
	my $mainid = $db->query($querystr);
	my $res = $mainid->fetchrow_hashref();
	my $id = $res->{main_id};
	#my $id = $mainid->numrows();
	#print "MAIN_ID:\t $id\n";
	my $querystring = "insert into dot1x(main_id,dot1x_enable,dot1x_status,dot1x_reauth,dot1x_period,dot1x_must_not) values ( $id,'$var1','$var2','$var3',$var4,0 )";
	my $query = $db->query($querystring);

}

#$portsec_enable, $portsec_status, $maxsecuremacaddr, $stickyenable, portsec_must_not


sub insert_snmp_data_portsec ($$$$$$$){
		
	my $h = shift;
	my $i = shift;
	my $d = shift;
	my $var1 = shift;
	my $var2 = shift;
	my $var3 = shift;
	my $var4 = shift;
	
	#database syslog.config_logger
	my $host = "172.16.2.3";
	my $database = "switchdb";
	my $user = "db_user";
	my $password = "Faqlogsys4u2009!";
	
	#connect to syslog_db
	my $db = Mysql->connect($host, $database, $user, $password); 
	$db->selectdb($database);
	my $querystr = "select main_id from switchdb_main where hostname = '$h' and interfaceshortname = '$i' and date = '$d'";
	#print "query:\t $querystr\n";
	my $mainid = $db->query($querystr);
	my $res = $mainid->fetchrow_hashref();
	my $id = $res->{main_id};
	#my $id = $mainid->numrows();
	#print "MAIN_ID:\t $id\n";
	my $querystring = "insert into portsec(main_id,portsec_enable,portsec_status,portsec_maxmac,portsec_sticky,portsec_must_not) values ( $id,'$var1','$var2',$var3,'$var4',0 )";
	my $query = $db->query($querystring);
}

#$stpPortfast, $stpBpduguard, $stpLoopguard

sub	insert_snmp_data_spanningtree ($$$$$$){
		
	my $h = shift;
	my $i = shift;
	my $d = shift;
	my $var1 = shift;
	my $var2 = shift;
	my $var3 = shift;
	
	#database syslog.config_logger
	my $host = "172.16.2.3";
	my $database = "switchdb";
	my $user = "db_user";
	my $password = "Faqlogsys4u2009!";
	
	#connect to syslog_db
	my $db = Mysql->connect($host, $database, $user, $password); 
	$db->selectdb($database);
	my $querystr = "select main_id from switchdb_main where hostname = '$h' and interfaceshortname = '$i' and date = '$d'";
	#print "query:\t $querystr\n";
	my $mainid = $db->query($querystr);
	my $res = $mainid->fetchrow_hashref();
	my $id = $res->{main_id};
	#my $id = $mainid->numrows();
	#print "MAIN_ID:\t $id\n";
	my $querystring = "insert into spanningtree(main_id,stp_portfast,stp_bdpuguard,stp_loopguard) values ( $id,'$var1','$var2','$var3')";
	my $query = $db->query($querystring);
}

#$pairchannel, $pairlength, $pairlenaccuracy, $pairdisttofault, $pairdistaccuracy, $pairstatus

sub	insert_snmp_data_diagnostic ($$$$$$$$$){
		
	my $h = shift;
	my $i = shift;
	my $d = shift;
	my $var1 = shift;
	my $var2 = shift;
	my $var3 = shift;
	my $var4 = shift;
	my $var5 = shift;
	my $var6 = shift;
	
	#database syslog.config_logger
	my $host = "172.16.2.3";
	my $database = "switchdb";
	my $user = "db_user";
	my $password = "Faqlogsys4u2009!";
	
	#connect to syslog_db
	my $db = Mysql->connect($host, $database, $user, $password); 
	$db->selectdb($database);
	my $querystr = "select main_id from switchdb_main where hostname = '$h' and interfaceshortname = '$i' and date = '$d'";
	#print "query:\t $querystr\n";
	my $mainid = $db->query($querystr);
	my $res = $mainid->fetchrow_hashref();
	my $id = $res->{main_id};
	#my $id = $mainid->numrows();
	#print "MAIN_ID:\t $id\n";
	my $querystring = "insert into switchport_diagnostic(main_id,pairchannel,pairlength,lengthaccuracy,disttofault,disttoaccuracy,pairstatus) values ( $id,'$var1','$var2','$var3','$var4','$var5','$var6')";
	my $query = $db->query($querystring);
}

#$runts, $giants, $framing, $overrun, $ignored, $abort, $inputqueuedrops, 
#$outputqueuedrops, $in_discards, $in_errors, $out_discards, $out_errors, $collisions, $crc

sub	insert_snmp_data_error ($$$$$$$$$$$$$$$$$){
		
	my $h = shift;
	my $i = shift;
	my $d = shift;
	my $var1 = shift;
	my $var2 = shift;
	my $var3 = shift;
	my $var4 = shift;
	my $var5 = shift;
	my $var6 = shift;
	my $var7 = shift;
	my $var8 = shift;
	my $var9 = shift;
	my $var10 = shift;
	my $var11 = shift;
	my $var12 = shift;
	my $var13 = shift;
	my $var14 = shift;
	
	#database syslog.config_logger
	my $host = "172.16.2.3";
	my $database = "switchdb";
	my $user = "db_user";
	my $password = "Faqlogsys4u2009!";
	
	#connect to syslog_db
	my $db = Mysql->connect($host, $database, $user, $password); 
	$db->selectdb($database);
	my $querystr = "select main_id from switchdb_main where hostname = '$h' and interfaceshortname = '$i' and date = '$d'";
	#print "query:\t $querystr\n";
	my $mainid = $db->query($querystr);
	my $res = $mainid->fetchrow_hashref();
	my $id = $res->{main_id};
	#my $id = $mainid->numrows();
	#print "MAIN_ID:\t $id\n";
	my $querystring = "insert into switchport_error(main_id,runts,gaints,framing,overrun,ignored,abort,inputqueuedrops,outputqueuedrops,indiscards,inerrors,outdiscards,outerrors,collisions,crc) values ( $id,'$var1','$var2','$var3','$var4','$var5','$var6','$var7','$var8','$var9','$var10','$var11','$var12','$var13',$var14)";
	my $query = $db->query($querystring);
}


#helper functions
sub del_doubles{ 
	my %all;
	grep {$all{$_}=0} @_;
	return (keys %all);
}