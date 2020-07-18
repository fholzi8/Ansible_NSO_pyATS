

our $logbase = "snmp_copyconfig";
do "/opt/scripts/generic-log.pl";

#loading modules
use strict;
use Net::SNMP;
use Net::Ping;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use DBI();
use Switch;


sub mailalert($$$);
sub snmpset_copyconfig($$$);
sub collect_nagios_host($);
sub string_to_hex($);
sub check_date();


#global variables
#snmp variable to set copy_config
my $oid_ConfigCopyProtocol = "1.3.6.1.4.1.9.9.96.1.1.1.1.2.111";
my $oid_SourceFileType = "1.3.6.1.4.1.9.9.96.1.1.1.1.3.111";
my $oid_DestinationFileType = "1.3.6.1.4.1.9.9.96.1.1.1.1.4.111";
my $oid_ServerAddress = "1.3.6.1.4.1.9.9.96.1.1.1.1.5.111";
my $oid_CopyFilename = "1.3.6.1.4.1.9.9.96.1.1.1.1.6.111";
my $oid_CopyStatus = "1.3.6.1.4.1.9.9.96.1.1.1.1.14.111";
my $oid_CopyStatus_DeleteInfo = "1.3.6.1.4.1.9.9.96.1.1.1.1.14.111";

my $session;
my $error;
our $hostname;
#my $mail_getter = "mailbox\@company.com";
my $mail_getter = "user\@company.com";#, user2\@company.com";
my $no_mail = 1;
my $script = "copyconfig";
my $source = '10.11.14.221';
#my $tftp_server = '10.11.14.215';
my $tftp_server = $source;

#sammeln der nagios_hosts
my $network_group = "Network_Devices";

#host_array aus nagios_db abfrage mittels hostgroup
my @network_hosts = collect_nagios_host($network_group);

#Fehler beim Sammeln der Configs
my @unreachable_hosts = "";
my @error_hosts = "";

my $count_host = 0;
#ping aufbauen
my $ping = Net::Ping->new("icmp");
#print $source;

$ping->bind($source);

foreach $hostname (sort @network_hosts){

	if (($hostname =~ /.*-internal-.*/) or ($hostname =~ /RZ-Accesspoint/) or ($hostname =~ /de.*acp.*/) ){
		next;
	}
  unless ($ping->ping($hostname, 2)){
  	print "Not reachable $hostname\n";
	push (@unreachable_hosts, $hostname);
  	next;
  }
  $count_host++;
	chomp($hostname);
	#print "Hostname: $hostname\n";
# Create the SNMP session - with Write Permission
	($session, $error) = Net::SNMP->session(
		   -hostname => $hostname,
		   -authprotocol =>  'md5',
		   -authpassword =>  'FaqSNMP4Watcher!',
		   -username     =>  'WatcherChecker',
		   -version      =>  '3',
		   -privprotocol =>  'des',
		   -privpassword =>  'FaqWatcher2008!'
	);
	#TFTP Sicherung mittels SNMP
	my $ref_date = check_date();
	my $dest_config = "backup/$hostname$ref_date.conf";
	#my $dest_config = "$hostname$ref_date.conf";
	my $snmp_result7 = snmpset_copyconfig($oid_CopyStatus_DeleteInfo, 'i', 6 );
	#print "Line7: $snmp_result7\n";
	my $snmp_result1 = snmpset_copyconfig($oid_ConfigCopyProtocol, 'i', 1 );
	#print "Line1: $snmp_result1\n";
	my $snmp_result2 = snmpset_copyconfig($oid_SourceFileType, 'i', 4 );
	#print "Line2: $snmp_result2\n";
	my $snmp_result3 = snmpset_copyconfig($oid_DestinationFileType, 'i', 1 );
	#print "Line3: $snmp_result3\n";
	my $snmp_result4 = snmpset_copyconfig($oid_ServerAddress, 'a', $tftp_server);
	#print "Line4: $snmp_result4\n";
	my $snmp_result5 = snmpset_copyconfig($oid_CopyFilename, 's', $dest_config);
	#print "Line5: $snmp_result5\n";
	my $snmp_result6 = snmpset_copyconfig($oid_CopyStatus, 'i', 1 );
	#print "Line6: $snmp_result6\n";

	# Close the snmp-read session
	$session->close();
	$dest_config = "";

}
$ping->close();
my $mail_content = "<body>\n";
my $mail_body = $mail_content;
foreach my $host (sort @unreachable_hosts) {
	if ($host eq ""){
		next;
	} else {
		$mail_body .= "Host: $host ist nicht erreichbar gewesen. Bitte Route prüfen.<br>\n";
		$no_mail = 0;
	}
}
$mail_body .= "<br></body>";
if ($no_mail == 0){
	mailalert($mail_getter, $mail_body, "Unreachable Hosts beim Config-Backup");
}
$mail_body = $mail_content;
foreach my $host (sort @error_hosts) {
	if ($host eq ""){
		next;
	} else {
		$mail_body .= "Host: $host ist nicht gesichert. Bitte Device prüfen.<br>\n";
		$no_mail = 0;
	}
}
$mail_body .= "<br></body>";
if ($no_mail == 0) {
	mailalert($mail_getter, $mail_body, "Error bei Hosts beim Config-Backup");
}
#print "Config saved for $count_host hosts\n";


sub snmpset_copyconfig($$$){
	my $oid = shift;
	my $datatype = shift;
	my $parameter = shift;
	chomp($parameter);
	#my $context = shift;
	print "oid $oid , Para: $parameter\n";
	my $result = '';
    if ($datatype eq 'i'){
	    $result = eval { $session->set_request($oid,INTEGER,$parameter); };
  	} elsif ($datatype eq 'a'){
	    $result = eval { $session->set_request($oid,IPADDRESS,$parameter);};
  	} elsif ($datatype eq 's'){
	    $result = eval { $session->set_request($oid,OCTET_STRING,$parameter); };
	}

    if (!defined $result){
    	#printf "ERROR_Set by: %s\n",$@;
    	#$session->close();
    	push(@error_hosts, $hostname);
		next;
    }
	my $val = $result->{$oid};
	#printf "Result: %s\n", $val;
	return $val;
}

sub mailalert($$$){
	my $receiver = shift;
	my $content = shift;
	my $subject = shift;
	#print "Mail is build 4 $receiver with\n$content\n$subject\n";
	my $email = MIME::Lite->new(
		Subject	=>	$subject,
		From	=>	'qradar@company.com',
		To		=>	$receiver,
		Type	=>	'text/html',
		Data	=>	$content
	);
	$email->send();
	#print "Mail is sent\n";
}

sub collect_nagios_host($){

	my $hostgroup = shift;
	#database nagios
	my $nagioshost = "dbserver.company.local";
	my $nagiosdatabase = "nagios";
	my $nagiosuser = "db_user";
	my $nagiospassword = "secret_dbpasswd";
	#connect to nagios_db
	my $db = DBI->connect("DBI:mysql:database=$nagiosdatabase;host=$nagioshost;port=3310",$nagiosuser, $nagiospassword);
	#$db->selectdb($nagiosdatabase);
	#select statement (get all host from $hostgroup
	my $querystring = "select h.alias from nagios_hostgroups g, nagios_hostgroup_members m, nagios_hosts h where g.alias = '$hostgroup' and m.host_object_id = h.host_object_id and g.hostgroup_id = m.hostgroup_id order by h.alias";
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

sub check_date(){
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$ydat,$isdst)=localtime();
  my $jahr=$year;
  my $monat=$mon+1;
  my $tag=$mday;

	$jahr=$year +1900;

	if (length($monat) == 1)
	{
	    $monat="0$monat";
	}
	if(length($tag) == 1)
	{
	   $tag="0$tag";
	}

	#my $ref_date = "$Xdatum $Xzeit";
	my $ref_date = "_$jahr$monat$tag";
	return $ref_date ;
}
