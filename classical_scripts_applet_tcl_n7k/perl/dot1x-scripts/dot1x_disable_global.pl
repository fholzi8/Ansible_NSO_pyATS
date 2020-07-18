use strict;
#use warning;
use Net::SNMP;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use DBI();
use Switch;

sub mailalert($$);
sub help();
sub collect_nagios_host($$);

my $hostname;
my $anz_host = 0;
my $anz_int = 0;
my $atime = time;
my $send = 0;
my $mailsend = 0;
my @workers = '';
my $ndl = "%";
my $script = "dot1x_disable_global.pl";


# -----------------------------------------------------------------------
# read config file
# -----------------------------------------------------------------------
my $msgbuf='';
$msgbuf .= "<html>\n<head>\n<title>DOT1X DISABLED</title>\n";
$msgbuf .= "<style>body {font-family: 'Verdana';\n";
$msgbuf .= "font-size: 8pt;\n";
$msgbuf .= "}\n";
$msgbuf .= "table {\n";
$msgbuf .= "border-collapse:collapse;\n";
$msgbuf .= "}\n";
$msgbuf .= "td {\n";
$msgbuf .= "border:\n";
$msgbuf .= "1px solid #DDDDDD;\n";
$msgbuf .= "font-family: 'Courier New';\n";
$msgbuf .= "font-size: 8pt;\n";
$msgbuf .= "color: #000000;\n";
$msgbuf .= "width:600px;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.center {\n";
$msgbuf .= "text-align:center;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.good {";
$msgbuf .= "text-align:center;\n";
$msgbuf .= "background-color: #7cfc00;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.middle {";
$msgbuf .= "text-align:center;\n";
$msgbuf .= "background-color: #FFA500;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.bad {text-align:center;\n";
$msgbuf .= "background-color: #ffa07a;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.client {text-align:center;\n";
$msgbuf .= "background-color: #FFFFFF;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.server {text-align:center;\n";
$msgbuf .= "background-color: #48D1CC;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.ilo {text-align:center;\n";
$msgbuf .= "background-color: #2E8B57;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.subheader {text-align:center;\n";
$msgbuf .= "background-color: #f5f5f5;\n";
$msgbuf .= "}\n";
$msgbuf .= "th {border:1px solid #DDDDDD;\n";
$msgbuf .= "font-family: 'Verdana';\n";
$msgbuf .= "font-size: 8pt;\n";
$msgbuf .= "font-weight: bold;\n";
$msgbuf .= "color: #000000;\n";
$msgbuf .= "background-color: #DDDDDD;\n";
$msgbuf .= "text-align:center;\n";
$msgbuf .= "}\n";
$msgbuf .= "th.tablehead {\n";
$msgbuf .= "color: #000000;\n";
$msgbuf .= "background-color: #FFFFFF;\n";
$msgbuf .= "}\n";
$msgbuf .= "</style>\n";
$msgbuf .= "</head>\n<body><center>\n";
$msgbuf .= "<h3>Disabled 802.1X Switchports</h3><br>\n";
$msgbuf .= "<table><tr><th style=\"text-align:center\"><center>Following Ports were disabled with the 802.1X Security Feature</th></tr>\n";

my $dot1x_group = "Dot1x-Client-Switch";
#host_array aus nagios_db abfrage mittels hostgroup
my $parameter = $ARGV[0];
chomp($parameter);
if (defined $ARGV[0]){
	if (length($parameter) != 4 ){
		die "Error wrong parameter\n";
	}
	$parameter = substr($parameter,1,4);
	$ndl = $parameter;
} else {
	$ndl = "%";
}
#print "Niederlassung: $ndl\n"; 
#exit 1;
my @nagios_hosts = collect_nagios_host($dot1x_group,$ndl);
#@nagios_hosts = "";
#push(@nagios_hosts,"demuc-swt08");
foreach my $host ( sort @nagios_hosts ) 
{	
	my $reference;
	my $buffer='';
	my $worker = '';
	my( $interface,  $desc ) = ( "", "" );
	my ( $dot1x, $vlanid, $trunk ) = ( 0, 0, 0 );
	
	$hostname = $host;
	$hostname =~ s/(.*)\.company\.local/$1/g;
	#Ausnahme von den Dot1x-MUC-Switchen die naechsten 3 zeilen einfach auskommentieren
	if ($host =~ /demuc/i){
		next;
	}
	$anz_host++;
	my $buf = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.2.1.31.1.1.1.1`;
	my @listbuf = "";
	@listbuf = split( /[\n\r]+/, $buf );
	foreach my $line (@listbuf) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'interface' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}
			
	my $bufdot1x = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.0.8802.1.1.1.1.2.1.1.6`;
	my @listbufdot1x = "";
	@listbufdot1x = split( /[\n\r]+/, $bufdot1x );
	foreach my $line (@listbufdot1x) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'dot1x' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}
	
	my $bufdesc = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.2.1.31.1.1.1.18`;
	my @listbufdesc = "";
	@listbufdesc = split( /[\n\r]+/, $bufdesc );
	foreach my $line (@listbufdesc) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'description' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}
	
	my $buftrunk = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.46.1.6.1.1.14`;
	my @listbuftrunk = "";
	@listbuftrunk = split( /[\n\r]+/, $buftrunk );
	foreach my $line (@listbuftrunk) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'trunk' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}		
	
	my $bufvlan = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.68.1.2.2.1.2`;
	my @listbufvlan = "";
	@listbufvlan = split( /[\n\r]+/, $bufvlan );
	foreach my $line (@listbufvlan) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'vlanid' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}						
	print "Switch: $host\n";			
	foreach my $key (sort{$a <=> $b} keys %$reference)
	{
		$interface = $reference->{ $key }->{ 'interface' };
		$dot1x = $reference->{ $key }->{ 'dot1x' };
		$desc = $reference->{ $key }->{ 'description' };
		$vlanid = $reference->{ $key }->{ 'vlanid' };
		$trunk = $reference->{ $key }->{ 'trunk' };

		$anz_int++;
		if ( $desc =~ /uplink/i){
			next;
		}elsif ( $desc =~ /srv/i){
			next;
		}elsif ( $desc =~ /farbkopierer/i){
			next;
		}elsif ( $desc =~ /ilo/i){
			next;
		}elsif ( $desc =~ /vpn/i){
			next;
		}elsif ( $desc =~ /asa/i){
			next;
		}elsif ( $desc =~ /HiPath/i){
			next;
		}elsif ( $desc =~ /usv/i){
			next;
		}elsif ( $desc =~ /server/i){
			next;
		}elsif ( $desc =~ /webcam/i){
			next;
		}elsif ( $desc =~ /h-wetter/i){
			next;
		}
		if (($vlanid < 115 ) or ($vlanid > 590)){
			next;
		}
		if ($trunk == 1){
			$trunk = "trunk mode";
			next;
		}else{
			$trunk = "access mode";
		}
		if ($dot1x != 2){
			next;
		}else {
			$dot1x = "enabled";
		}
			
		my $oid = "1.0.8802.1.1.1.1.2.1.1.6.$key";
		#my $vlan_oid = "1.3.6.1.4.1.9.9.68.1.2.2.1.2.$key";
		#my $prompt = "$hostname with interface-id $key\n";
		my $prompt = `/usr/bin/snmpset -v 3 -u WatcherChecker -l authpriv -A FaqSNMP4Watcher! -X FaqWatcher2008! $hostname $oid i 3`;
		#my $vlanprompt = `/usr/bin/snmpset -v 3 -u WatcherChecker -l authpriv -A FaqSNMP4Watcher! -X FaqWatcher2008! $hostname $vlanoid i $vlanid`;
		print "interface-id $key is successful disabled\n";
		if ($prompt =~ /.* = .*: 3/i ){
			$buffer .= "<tr><td style=\"text-align:center\">On $hostname port $interface dot1x was disabled</td></tr>\n";
			$buffer .= "<tr><td style=\"text-align:center\">Reason: $desc</td></tr>\n";
		}
		$send = 1;
	}
	if ($send == 0)	{
		$buffer = "";
		next;
	}else{
		$msgbuf .= $buffer;
		$buffer = "";
		$mailsend = 1;
		$send = 0;
	}
}

my $etime = time;
my $time = $etime - $atime;	
my $mailing_list;
$mailing_list = "_IT_Operations\@company.com";	
#$mailing_list = "user\@company.com";		
$msgbuf .= "</table><br>\n";
$msgbuf .= "<p class=MsoNormal><font size=1 face=Verdana><span style='font-size:8.0pt; font-family:Verdana'>\n";
$msgbuf .= "<center>Es wurden $anz_host Switche und $anz_int Interfaces in einer Zeit von $time Sekunden �berpr�ft!<br>\n";
$msgbuf .= "The script is located on watcher in the following path: /opt/scripts/dot1x_check/$script <br>\n";
$msgbuf .= "<o:p></o:p></span></font></p>\n";
$msgbuf .= "</body>\n</html>\n";

if ($mailsend == 1){
	mailalert($mailing_list, $msgbuf);
}

sub mailalert($$)
{
	my $receiver = shift;
	my $content = shift;
	
	my $email = MIME::Lite->new(
		Subject	=>	'DOT1X DISABLED',
		From	=>	'syslog-ng@company.com',
		To		=>	$receiver,
		Type	=>	'text/html',
		Data	=>	$content
	);
	$email->send();
}

sub del_doubles
{ 
	my %all;
	grep {$all{$_}=0} @_;
	return (keys %all);
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
