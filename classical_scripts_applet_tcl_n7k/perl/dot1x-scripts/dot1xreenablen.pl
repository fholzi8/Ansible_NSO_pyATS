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


my $TO =  'mailbox@company.com';
my $TO1 = 'user@company.com';


my $hostname;
my $anz_host = 0;
my $anz_int = 0;
my $atime = time;
my $send = 0;
my $mailsend = 0;
my @workers = '';
my $script = "dot1xreenablen.pl";

use vars qw / $opt_h $opt_e $opt_d $opt_m /;
$opt_h=0;
$opt_m='';
$opt_e=0;
$opt_d=0;

getopts( 'hedm:' ) || 
	die "$0: valid options: [-h] [-e] [-m <mailto>] \n";

if ($opt_h != 0){
	help();
}

my $msgbuf='';
$msgbuf .= "<html>\n<head>\n<title>DOT1X ENABLED</title>\n";
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
$msgbuf .= "<h3>Reenabled 802.1X Switchports</h3><br>\n";
$msgbuf .= "<table><tr><th style=\"text-align:center\"><center>Following Ports were reenabled with the 802.1X Security Feature</th></tr>\n";

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

#foreach my $host ( sort ( keys %cf ) )
foreach my $host ( sort @nagios_hosts ) 
{
  next if $host eq '_default';	# skip default config
	
	#ausnahme f�r autoassignment
	if (($host eq /demuc-swt07/) or ($host eq /demuc-swt08/)){
		next;
	}
	
	my $reference;
	my $buffer='';
	my $type = '';
	my $worker = '';
	my( $interface,  $desc, $mac ) = ( "", "", "" );
	my ( $dot1x, $admin, $oper, $stpfast, $stpguard ) = ( 0, 0, 0, 0, 0 );
	my ( $portsec, $sticky, $max_mac, $trunk, $vlanid ) = ( 0, 0, 0, 0, 0 );
	$type = "client";
	#print "$host -> ". Dumper( $cf{$host} );
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
	
	my $bufmac = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.315.1.2.1.1.10`;
	my @listbufmac = "";
	@listbufmac = split( /[\n\r]+/, $bufmac );
	foreach my $line (@listbufmac) 
	{
		if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
		{
			if ($2 ne '')
			{
				$reference->{$1}->{ 'macaddress' } = $2;
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
			
	#my $bufsticky = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.315.1.2.1.1.15`;
	#my @listbufsticky = "";
	#@listbufsticky = split( /[\n\r]+/, $bufsticky );
	#foreach my $line (@listbufsticky) 
	#{
	#	if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
	#	{
	#		if ($2 ne '')
	#		{
	#			$reference->{$1}->{ 'sticky' } = $2;
	#		}
	#		else
	#		{	
	#			next; 
	#		}
	#	}
	#}
	
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
				
	#my $bufmaxmac = `/usr/bin/perl /opt/scripts/check-scripts/snmpwalk_v3.pl -H $host -o 1.3.6.1.4.1.9.9.315.1.2.1.1.4`;
	#my @listbufmaxmac = "";
	#@listbufmaxmac = split( /[\n\r]+/, $bufmaxmac );
	#foreach my $line (@listbufmaxmac) 
	#{
	#	if ( $line =~ /^(\d+)\s*=> (.*)/ ) 
	#	{
	#		if ($2 ne '')
	#		{
	#			$reference->{$1}->{ 'max_mac' } = $2;
	#		}
	#		else
	#		{	
	#			next; 
	#		}
	#	}
	#}		
	
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
		
		foreach my $key (sort{$a <=> $b} keys %$reference)
		{
			
			$interface = $reference->{ $key }->{ 'interface' };
			$dot1x = $reference->{ $key }->{ 'dot1x' };
			$desc = $reference->{ $key }->{ 'description' };
			$admin = $reference->{ $key }->{ 'adminstatus' };
			$oper = $reference->{ $key }->{ 'operstatus' };
			$mac = $reference->{ $key }->{ 'macaddress' };
			$portsec = $reference->{ $key }->{ 'portsec' };
			#$sticky = $reference->{ $key }->{ 'sticky' };
			$trunk = $reference->{ $key }->{ 'trunk' };
			$vlanid = $reference->{ $key }->{ 'vlanid' };
			$max_mac = $reference->{ $key }->{ 'max_mac' };
			$stpfast = $reference->{ $key }->{ 'portfast' };
			$stpguard = $reference->{ $key }->{ 'spanning-tree guard' };
			
			my $new_mac = $mac;
			$new_mac =~ s/0x([a-f0-9]{4})([a-f0-9]{4})([a-f0-9]{4}).*/$1\.$2\.$3/g;
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
			} elsif (($desc =~ /usv/i) or ($desc =~ /accesspoint/i) or ($desc =~ /test-setup/i) or ($desc =~ /UNUSED -- SHUTDOWN/i)){
				next;
			} elsif (!defined $desc ){
				next;
			} elsif ( $desc eq "" ){
				next;
			}
			#dot1x �berpr�fung
			if ($dot1x == 2){
				if ($portsec == 1)	{
					next;
				}else {
					$dot1x = "enabled";
				} 
			}	elsif ($dot1x == 3)	{
				$dot1x = "disabled";
			}	else {
				$dot1x = "unknown";
			}
			#operation staus �berpr�fen
			#olf#  auch deaktivierte Ports sollen dot1x enabled sein (gerade die) siehe todo http://it/todo/#todopoint_102377 20130311
			#olf# if ($oper == 1){
			#olf# 	$oper = "up";
			#olf# }	else{
			#olf# 	$oper = "down";
			#olf# 	next;
			#olf# }
			# adminstatus �berpr�fen
			#if ($admin == 1){
			#	$admin = "up";
			#}	else {
			#	$admin = "admin down";
			#	next;
			#}
			#portsecurity status �berpr�fen
			if ($portsec == 1){
				$portsec = "enabled";
			}	else{
				$portsec = "disabled";
			}
			#portsecurity stickyness �berpr�fen
			#if ($sticky == 1){
			#	$sticky = "enabled";
			#}	else {
			#	if ($oper == 1) {
			#		$sticky = "disabled";
			#	}	else{
			#		$sticky = "unknown";
			#	}
			#}
			#wenn 802.1x an aber operation down next
			#if (($dot1x ne "enabled") and ($oper eq "down")){
			#	next;
			#}
			#wnn vlan VID kleiner 101 oder gr��er 660
			if (($vlanid < 101 ) or ($vlanid > 660)){
				next;
			}
			#wenn trunk port keine �berpr�fung
			if ($trunk == 1){
				$trunk = "trunk mode";
				next;
			}	else{
				$trunk = "access";
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
			my $oid = "1.0.8802.1.1.1.1.2.1.1.6.$key";
			my $prompt = `/usr/bin/snmpset -v 3 -u WatcherChecker -l authpriv -A FaqSNMP4Watcher! -X FaqWatcher2008! $hostname $oid i 2`;
			if ($prompt =~ /.* = .*: 2/i )
			{
				$buffer .= "<tr><td style=\"text-align:center\">On $hostname port $interface dot1x was succesfully reenabled</td></tr>\n";
				$buffer .= "<tr><td style=\"text-align:center\">Reason: $desc</td></tr>\n";
			}
			$send = 1;
		}
	if ($send == 0)
	{
		$buffer = "";
		next;
	}
	else
	{
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
$mailing_list =~ s/^,(.*),$/$1/g;
#$mailing_list = "user\@company.com";		
#printf "Mailing to %s",$mailing_list;
$msgbuf .= "</table><br>\n";
$msgbuf .= "<p class=MsoNormal><font size=1 face=Verdana><span style='font-size:8.0pt; font-family:Verdana'>\n";
$msgbuf .= "<center>Es wurden $anz_host Switche und $anz_int Interfaces in einer Zeit von $time Sekunden �berpr�ft!<br>\n";
$msgbuf .= "The script is located on watcher in the following path: /scripts/dot1x_check/$script<br>\n";
$msgbuf .= "<o:p></o:p></span></font></p>\n";
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
		Subject	=>	'DOT1X REENABLED',
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
	print "\ndot1xreenabled is a little tool to set the 802.1x status on switchports";
	print "\nSyntax:\t dot1xreenabled <option> (optional)\n";
	print "\nOptions:\n\n";
	print "\t-h\t\tshow this message and exit\n";
	print "\t-m\t\tMail-Receiver (i.e.: -m \"_syslog\@company.com, msonne\@company.com\")\n";
	print "\t-C\t\tConfig File (default: .\\config)\n";
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
