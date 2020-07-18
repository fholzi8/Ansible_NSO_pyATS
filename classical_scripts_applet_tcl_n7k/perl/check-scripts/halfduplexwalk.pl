use strict;
use Net::SNMP;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use DBI();
use Switch;


sub mailalert($$);
sub help();
sub collect_nagios_host($);

my $hostname;
my $anz_host = 0;
my $anz_int = 0;
my $atime = time;
my $send = 0;
my $mailsend = 0;
my @workers = '';
my $script = "halfduplexwalk";

use vars qw / $opt_h $opt_d $opt_m /;
$opt_h=0;
$opt_m='';
$opt_d=0;

getopts( 'hdm:' ) ||
	die "$0: valid options: [-h] [-d] [-m <mailto>]\n";

if ($opt_h != 0){
	help();
}

my $msgbuf='';
$msgbuf .= "<html>\n<head>\n<title>DUPLEX ALERT</title>\n";
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
$msgbuf .= "width:1100px;\n";
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
$msgbuf .= "<h1>Aktuelle Half-Duplex Switchports</h1><br>\n";

my $dot1x_group = "Dot1x-Client-Switch";
my $switch_group = "FW_Check_Switch";
#host_array aus nagios_db abfrage mittels hostgroup
my @nagios_hosts = collect_nagios_host($switch_group);

#foreach my $host ( sort ( keys %cf ) )
foreach my $host ( sort @nagios_hosts )
{
  next if $host eq '_default';	# skip default config

	my $reference;
	my $buffer='';
	my $type = '';
	my $worker = '';
	my( $interface, $duplexstat, $admin, $oper, $desc, $duplexoper, $trunk, $vlanid );
	$type = "client";
	#print "$host -> \n";
	$hostname = $host;
	$hostname =~ s/(.*)\.company\.local/$1/g;
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

	my $bufduplexstat = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.2.1.10.7.2.1.19`;
	my @listbufduplexstat = "";
	@listbufduplexstat = split( /[\n\r]+/, $bufduplexstat );
	foreach my $line (@listbufduplexstat)
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ )
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'duplexstat' } = $2;
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

	my $bufint = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.2.1.2.2.1.7`;
	my @listbufint = "";
	@listbufint = split( /[\n\r]+/, $bufint );
	foreach my $line (@listbufint)
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ )
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'adminstatus' } = $2;
			}
			else
			{
				next;
			}
		}
	}

	my $bufoper = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.2.1.2.2.1.8`;
	my @listbufoper = "";
	@listbufoper = split( /[\n\r]+/, $bufoper );
	foreach my $line (@listbufoper)
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ )
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'operstatus' } = $2;
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

	if ($hostname =~ /vpn01/)
	{
		$buffer .= "<table><tr><th colspan=\"5\" style=\"text-align:center\"><center>$hostname - agency-router</th></tr>\n";
	}
	else
	{
		$buffer .= "<table><tr><th colspan=\"5\" style=\"text-align:center\"><center>$hostname - $type-switch</th></tr>\n";
		}
	$buffer .= "<tr><td style=\"width:60px\" class='subheader'>Switchport</td>";
	$buffer .= "<td style=\"width:60px\" class='subheader'>Mode</td>";
	$buffer .= "<td style=\"width:230px\" class='subheader'>Description</td>";
	$buffer .= "<td style=\"width:40px\" class='subheader'>Vlan</td>";
	$buffer .= "<td style=\"width:60px\" class='subheader'>Duplex</td>";

		foreach my $key (sort{$a <=> $b} keys %$reference)
		{

			$interface = $reference->{ $key }->{ 'interface' };
			$duplexstat = $reference->{ $key }->{ 'duplexstat' };
			$desc = $reference->{ $key }->{ 'description' };
			$admin = $reference->{ $key }->{ 'adminstatus' };
			$oper = $reference->{ $key }->{ 'operstatus' };
			$trunk = $reference->{ $key }->{ 'trunk' };
			$vlanid = $reference->{ $key }->{ 'vlanid' };

			unless ($interface =~ /Gi/ )
			{
				next;
			}
			$anz_int++;
			# description �berpr�fen
			if (($desc =~ /steckdose/i) or ($desc =~ /usv/i) or ($desc =~ /power/i)){
				next;
			}
			#operation staus �berpr�fen
			if ($oper == 1){
				$oper = "up";
			}	else{
				$oper = "down";
				next;
			}
			# adminstatus �berpr�fen
			if ($admin == 1){
				$admin = "up";
			}	else {
				$admin = "admin down";
				next;
			}
			#duplex status
			if ($duplexstat == 3){
				$duplexstat = "full";
				next;
			}elsif ($duplexstat == 2){
				$duplexstat = "half";
			}else {
				$duplexstat = "unknown";
			}
			#wnn vlan VID kleiner 101 oder gr��er 660
			if (($vlanid < 101 ) or ($vlanid > 600)){
				next;
			}
			#wenn trunk port keine �berpr�fung
			if ($trunk == 1){
				$trunk = "trunk mode";
				next;
			}	else{
				$trunk = "access";
			}

			$buffer .= "<tr><td style=\"width:60px\" class='$type'>$interface</td>";
			$buffer .= "<td style=\"width:60px\" class='$type'>$trunk</td>";
			$buffer .= "<td style=\"width:230px\" class='$type'>$desc</td>";
			$buffer .= "<td style=\"width:40px\" class='$type'>$vlanid</td>";
			$buffer .= "<td style=\"width:60px\" class='bad'>$duplexstat</td>";

			$send = 1;
		}
	if ($send == 0)
	{
		$buffer = "";
		next;
	}
	else
	{
		$buffer .= "</table><br>\n";
		$msgbuf .= $buffer;
		$buffer = "";
		$mailsend = 1;
		$send = 0;
	}
}

my $etime = time;
my $time = $etime - $atime;

@workers = &del_doubles(@workers);
my $mailing_list = "";
foreach my $mailer (@workers)
{
	$mailing_list .= "$mailer,";
}
#$mailing_list =~ s/^,(.*),$/$1/g;
$mailing_list = "security_team\@company.com";
#$mailing_list = "user\@company.com";

#printf "Mailing to %s",$mailing_list;
my $TIME = sek2min($time);
$msgbuf .= "<tr><td>Diese Mail wird st�ndlich bei \"half-duplex\" Ports generiert!</td></tr></table>\n";
$msgbuf .= "<center><br><br>Es wurden $anz_host Switche (NagiosGroup $switch_group) und $anz_int Interfaces in einer Zeit von $TIME �berpr�ft!<br>\n";
$msgbuf .= "<h6>The script is located on watcher in the following path: /opt/scripts/check-scripts/".$script.".pl</h6>";
$msgbuf .= "</body>\n</html>\n";

if ($mailsend == 1)
{
	mailalert($mailing_list, $msgbuf);
}

sub mailalert($$)
{
	my $receiver = shift;
	my $content = shift;

	my $email = MIME::Lite->new(
		Subject	=>	'Half-Duplex ALERT',
		From	=>	'dot1x@company.com',
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
sub sek2min($)
{
	my $sekunden = shift;
	my ($min,$sek) = (0,0);
	$sek = $sekunden % 60;
	$sekunden = ($sekunden - $sek) / 60;
	$min = $sekunden % 60;
	my $time = "$min min $sek sec";
	return $time;
}
sub help()
{
	print "\nhalfduplexwalk is a little tool to check status of Half-Duplex status and description on switchports";
	print "\nSyntax:\t halfduplexwalk.pl \n";
	print "\t-m\t\tMail-Receiver (i.e.: -m \"_syslog\@company.com, msonne\@company.com\")\n";
	print "\n\nHave fun with this little tool\n";
	exit 1;
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