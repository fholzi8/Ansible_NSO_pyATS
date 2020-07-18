use strict;
use Net::SNMP;
use Getopt::Std;
use MIME::Lite;
#use Net::Ping;
use Data::Dumper;
use DBI();
use Switch;
#use Parallel::ForkManager;

sub mailalert($$);
sub help();
sub collect_nagios_host($);


my $TO =  'mailbox@company.com';
#my $TO = '_syslog@company.com';
#my $TO = 'user@company.com, rkirsch@company.com';


my $hostname;
my $anz_host = 0;
my $anz_int = 0;
my $atime = time;
my $send = 0;
my $mailsend = 0;
my @workers = '';
my $script = "switchsecuritywalk.pl";
#my $pm = Parallel::ForkManager->new(20);


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
$msgbuf .= "<html>\n<head>\n<title>DOT1X ALERT</title>\n";
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
if ($opt_d == 0)
{
	$msgbuf .= "<h1>Aktuelle offene 802.1X Switchports</h1><br>\n";
}
else
{
	$msgbuf .= "<h1>Aktuelle Statusanzeige aller Switchports</h1><br>\n";
}

if ($opt_m eq "")
{
	push(@workers,$TO);
}
else
{
	push(@workers,$opt_m);
}
my $dot1x_group = "Dot1x-Client-Switch";
#host_array aus nagios_db abfrage mittels hostgroup
my @nagios_hosts = collect_nagios_host($dot1x_group);


#my $source = "10.11.14.221";
#my $ping = Net::Ping->new("icmp");
#print $source;

#$ping->bind($source);
#my @hosts;

#foreach my $hostname (@nagios_hosts){
#	unless ($ping->ping($hostname, 2)){
#  	next;
#  }
#  if ($hostname =~ /internal-gateway/){
#		next;
#	} elsif ($hostname =~ /acp/){
#		next;
#	} elsif ($hostname =~ /core/){
#		next;
#	} elsif ($hostname =~ /asp/){
#		next;
#	} elsif ($hostname =~ /de.*/){
#		push(@hosts, $hostname);
#	}
#}
#my @child_process;
 
foreach my $host (@nagios_hosts){
#	my $pid = $pm->start and next;
#	push(@child_process, $pid);
#foreach my $host ( sort ( keys %cf ) )
	
	my $reference;
	my $buffer='';
	my $type = '';
	my $worker = '';
	my( $interface, $dot1x, $admin, $oper, $desc, $portsec, $trunk, $vlanid, $max_mac, $stpfast, $stpguard);
	#$type = "client";
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
	
	my $bufportsec = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.315.1.2.1.1.1`;
	my @listbufportsec = "";
	@listbufportsec = split( /[\n\r]+/, $bufportsec );
	foreach my $line (@listbufportsec) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'portsec' } = $2;
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
				
	my $bufmaxmac = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.315.1.2.1.1.3`;
	my @listbufmaxmac = "";
	@listbufmaxmac = split( /[\n\r]+/, $bufmaxmac );
	foreach my $line (@listbufmaxmac) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'max_mac' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}		
	
	my $bufstpfast = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.46.1.6.1.1.13`;
	my @listbufstpfast = "";
	@listbufstpfast = split( /[\n\r]+/, $bufstpfast );
	foreach my $line (@listbufstpfast) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'portfast' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}						
	
	my $bufstpguard = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.46.1.6.1.1.14`;
	my @listbufstpguard = "";
	@listbufstpguard = split( /[\n\r]+/, $bufstpguard );
	foreach my $line (@listbufstpguard) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'spanning-tree guard' } = $2;
			}
			else
			{	
				next; 
			}
		}
	}
	$buffer .= "<table><tr><th colspan=\"10\" style=\"text-align:center\"><center>$hostname</th></tr>\n";
	$buffer .= "<tr><td style=\"width:60px\" class='subheader'>Switchport</td>";
	$buffer .= "<td style=\"width:60px\" class='subheader'>Mode</td>";
	$buffer .= "<td style=\"width:230px\" class='subheader'>Description</td>";
	$buffer .= "<td style=\"width:40px\" class='subheader'>Vlan</td>";
	$buffer .= "<td style=\"width:60px\" class='subheader'>802.1X</td>";
	$buffer .= "<td style=\"width:60px\" class='subheader'>Status</td>";
	$buffer .= "<td style=\"width:100px\" class='subheader'>Port-Security</td>";
	$buffer .= "<td style=\"width:100px\" class='subheader'>Portfast</td>";
	$buffer .= "<td style=\"width:100px\" class='subheader'>STP Guard</td>";
	$buffer .= "<td style=\"width:30\" class='subheader'>MAC Count</td></tr>\n";									

		foreach my $key (sort{$a <=> $b} keys %$reference)
		{
			
			$interface = $reference->{ $key }->{ 'interface' };
			$dot1x = $reference->{ $key }->{ 'dot1x' };
			$desc = $reference->{ $key }->{ 'description' };
			$admin = $reference->{ $key }->{ 'adminstatus' };
			$oper = $reference->{ $key }->{ 'operstatus' };
			$portsec = $reference->{ $key }->{ 'portsec' };
			$trunk = $reference->{ $key }->{ 'trunk' };
			$vlanid = $reference->{ $key }->{ 'vlanid' };
			$max_mac = $reference->{ $key }->{ 'max_mac' };
			$stpfast = $reference->{ $key }->{ 'portfast' };
			$stpguard = $reference->{ $key }->{ 'spanning-tree guard' };
			
			unless (($interface =~ /Gi/ ) or ($interface =~ /Fa/ )) 
			{ 
				next; 
			}
			$anz_int++;
			#port mit ausnahmen definieren und von �berpr�fung ausnehmen
			if (($desc =~ /dot1xausnahme/i) or ($desc =~ /vpn/i) or ($desc =~ /caf/i) or ($desc =~ /acp/i) or ($desc =~ /wan/i)){
				next;
			} elsif (($desc =~ /srv/i) or ($desc =~ /tk/i) or ($desc =~ /hipath/i)or ($desc =~ /ilo/i) or ($desc =~ /server/i)){
				next;
			} elsif (($desc =~ /steckdose/i) or ($desc =~ /asa/i) or ($desc =~ /uplink/i)or ($desc =~ /downlink/i)){
				next;
			} elsif (($desc =~ /usv/i) or ($desc =~ /accesspoint/i) or ($desc =~ /test-setup/i)){
				next;
			} elsif (!defined $desc ){
				next;
			} elsif ( $desc eq "" ){
				next;
			}
			if (( $desc =~ /Kopierer/i) or ( $desc =~ /Aficio/i) or ( $desc =~ /drucker/i))
			{
				push(@workers,"_IT_ISS\@company.com");
			}
			#wenn trunk port keine �berpr�fung
			if ($trunk == 1){
				$trunk = "trunk mode";
				next;
			}	else{
				$trunk = "access";
			}
			#dot1x �berpr�fung
			if ($dot1x == 2){
				if (($portsec == 1) or ($opt_d == 0))	{
					next;
				}	else {
					$dot1x = "enabled";
				} 
			}	elsif ($dot1x == 3)	{
				$dot1x = "disabled";
			}	else {
				$dot1x = "unknown";
			}
			#operation staus �berpr�fen
			if ($oper == 1){
				$oper = "up";
			}	else{
				$oper = "down";
			}
			# adminstatus �berpr�fen
			if ($admin == 1){
				$admin = "up";
			}	else {
				$admin = "admin down";
				next;
			}
			#portsecurity status �berpr�fen
			if ($portsec == 1){
				$portsec = "enabled";
			}	else{
				$portsec = "disabled";
			}
			
			#wenn 802.1x an aber operation down next
			#olf# (soll auch angezeigt werden wenn der Port down ist)
                        #olf# 20130311 geaendert von 
                        #olf# if (($dot1x ne "enabled") and ($oper eq "down")){
                        #olf# nach:
			if ($dot1x ne "enabled"){
				next;
			}
			#wnn vlan VID kleiner 101 oder gr��er 660
			if (($vlanid < 101 ) or ($vlanid > 600)){
				next;
			}
			
			#�berpr�fen ob portfast aktiviert ist
			if ($stpfast == 2)	{
				$stpfast = "enabled";
			}	else{
				$stpfast = "disabled";
			}
			#STP Guard �berpr�fen ob aktiviert
			if ($stpguard == 2){
				$stpguard = "enabled";
			}	else{
				$stpguard = "disabled";
			}
			
			#Bau des HTML Content
			$buffer .= "<tr><td style=\"width:60px\" class='$type'>$interface</td>";
			$buffer .= "<td style=\"width:60px\" class='$type'>$trunk</td>";
			$buffer .= "<td style=\"width:230px\" class='$type'>$desc</td>";
			$buffer .= "<td style=\"width:40px\" class='$type'>$vlanid</td>";
			if ($dot1x eq "enabled")
			{
				 $buffer .= "<td style=\"width:60px\" class='good'>$dot1x</td>";
			}
			else
			{
				$buffer .= "<td style=\"width:60px\" class='bad'>$dot1x</td>";
			}
			if ($oper eq "down")
			{
				$buffer .= "<td style=\"width:60px\" class='good'>$oper</td>";
			}
			else
			{
				$buffer .= "<td style=\"width:60px\" class='bad'>$oper</td>";
			}
			if ($portsec eq "enabled")
			{
				$buffer .= "<td style=\"width:100px\" class='good'>$portsec</td>";
			}
			else
			{
				$buffer .= "<td style=\"width:100px\" class='bad'>$portsec</td>";
			}
			if ($stpfast eq "enabled")
			{
				$buffer .= "<td style=\"width:100px\" class='good'>$stpfast</td>";
			}
			else
			{
				$buffer .= "<td style=\"width:100px\" class='bad'>$stpfast</td>";
			}
			if ($stpguard eq "enabled")
			{
				$buffer .= "<td style=\"width:100px\" class='good'>$stpguard</td>";
			}
			else
			{
				$buffer .= "<td style=\"width:100px\" class='bad'>$stpguard</td>";
			}
			$buffer .= "<td style=\"width:30px\" class='$type'>$max_mac</td></tr>\n";									
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
	#$pm->finish;
}
#$pm->wait_all_children;

my $etime = time;
my $time = $etime - $atime;	
@workers = &del_doubles(@workers);
my $mailing_list = "";
foreach my $mailer (@workers)
{
	$mailing_list .= "$mailer,";
}
$mailing_list =~ s/^,(.*),$/$1/g;
	
#printf "Mailing to %s",$mailing_list;
#$mailing_list = "user\@company.com";

$msgbuf .= "<p class=MsoNormal><font size=1 face=Verdana><span style='font-size:8.0pt;\n";
$msgbuf .= "font-family:Verdana'><br>\n";
if ($opt_d == 0)
{
	$msgbuf .= "<table style=\"width:600; border-style:none; background-color:#FFFFFF\">";
	$msgbuf .= "<tr><th style=\"text-align:center\"><center>Bitte die offenen 802.1x Ports schnellstm�glichst schlie�en - d.h. 802.1X konfigurieren/reenablen!</th></center></tr>\n";
	$msgbuf .= "<tr><td>Bei \"offenen\" Druckerports: Mailversand an das Client Management Desk!</td></tr>\n";
	$msgbuf .= "<tr><td>Bei \"offenen\" Clientports: Mailversand an den jeweiligen Bearbeiter!</td></tr>\n";
	$msgbuf .= "<tr><td>Diese Mail wird st�ndlich bei \"offenen\" 802.1X Ports generiert!</td></tr></table>\n";
}
$msgbuf .= "<center><br><br>Es wurden $anz_host Switche und $anz_int Interfaces in einer Zeit von $time Sekunden �berpr�ft!<br>\n";
$msgbuf .= "The script is located on watcher in the following path: /scripts/dot1x_check/$script <br>\n";
if ($opt_d == 0)
{
	$msgbuf .= "<br>Ein Wiki-Eintrag zur Deaktivierung von 802.1X findet man hier: <a href=\"http://internal.company.local/wiki/index.php/802.1x_auf_Client-Switch_deaktivieren\">Wiki-dot1x</a><br>\n";
	$msgbuf .= "Link zum <a href=\"http://dot1x\">Dot1x-Interface</a><br>\n";
}
$msgbuf .= "<o:p></o:p></span></font></p> \n";
$msgbuf .= "</body>\n</html>\n";
if ($opt_d != 0)
{
	open ( FILE, ">/scripts/html/dot1x/index.html" ) or die $!;
		print FILE $msgbuf;
	close ( FILE );
	$msgbuf = "<html><body><center><br>\n";
	$msgbuf .= "Link zum <a href=\"http://watcher/switchstatus/index.html\">Switchstatus-Interface</a><br>\n";
	$msgbuf .= "</body></html>\n";
}
if ($mailsend == 1)
{
	mailalert($mailing_list, $msgbuf);
}

sub mailalert($$)
{
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

sub del_doubles
{ 
	my %all;
	grep {$all{$_}=0} @_;
	return (keys %all);
}

sub help()
{
	print "\nswitchchecker is a little tool to check status of 802.1x and description on switchports";
	print "\nSyntax:\t switchchecker <option> (optional)\n";
	print "\nOptions:\n\n";
	print "\t-h\t\tshow this message and exit\n";
	print "\t-e\t\twithout Exclusion\n";
	print "\t-d\t\twith Dot1X Status\n";
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
