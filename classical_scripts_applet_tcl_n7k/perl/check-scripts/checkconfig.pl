

#loading modules
use strict;
use Net::SNMP;
use Net::Ping;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use Mysql;
use Switch;
use Date::Calc qw( Today Date_to_Days );



sub mailalert($$$);
sub collect_nagios_host($);
sub string_to_hex($);
sub check_date();


#global variables


my $mail_getter = "user\@company.com";
my $mail = 0;
my $script = "checkconfig";
my $tftp_server = '10.11.14.215';
my $backup_path = '/opt/network_backup/tftp/networkdevice_backup';

#sammeln der nagios_hosts
my $asa_group = "ASA";
my $network_group = "Network_Devices";
my $wireless_group = "Wireless";
my $lb_group = "Loadbalancer";

#host_array aus nagios_db abfrage mittels hostgroup
my @network_hosts = collect_nagios_host($network_group);
my @wireless_hosts = collect_nagios_host($wireless_group);
my @asa_hosts = collect_nagios_host($asa_group);
my @weblb = collect_nagios_host($lb_group);

my @hosts;
push(@hosts, @network_hosts);
push(@hosts, @wireless_hosts);
push(@hosts, @asa_hosts);
push(@hosts, @weblbs);
my @no_current_file;
my @current_file;
my @outdated_file;
my $count_host = 0;

foreach my $hostname (sort @hosts){

	if ($hostname =~ /.*-internal-.*/){
		next;
	}elsif ($hostname =~ /(.*)-mgmt/){
		$hostname = $1;
	}
  $count_host++;
	chomp($hostname);
	#print "Hostname: $hostname\n";
	my $location = $hostname;
	if (($location =~ /au.*/)){
		$location = "autria";
	}else{
		$location =~ s/de(...).*/$1/g;
	}

	#�berpr�fung der Aktualit�t der Dateien
	my $file_to_check = "$backup_path/$location/$hostname.conf";
	my $file_stats = "";
	if (-e $file_to_check){
		$file_stats = `ls -l $file_to_check`;
	} else {
		push(@no_current_file,$hostname);
		$mail = 1;
		next;
	}
	my @file_stati = split (' ',$file_stats);
	my ($year,$month,$day) = Today();
	my $cmonth = $file_stati[5];
	#my $cmonth = $file_stati[6];
	my $cday = $file_stati[6];
	#my $cday = $file_stati[5];
	my $cyear = $file_stati[7];
	#my $cyear = "2012";
	#printf "Year: %s - Month: %s - Day: %s \n",$cyear,$cmonth,$cday;
	$cday =~ s/(\d+)\./$1/g;
	my $file_day = int($cday);
	#switch($cmonth){
	#	case /Jan/	{ $cmonth = "1";}
	#	case /Feb/	{ $cmonth = "2";}
	#	case /M�r/	{ $cmonth = "3";}
	#	case /Apr/	{ $cmonth = "4";}
	#	case /Mai/	{ $cmonth = "5";}
	#	case /Jun/	{ $cmonth = "6";}
	#	case /Jul/	{ $cmonth = "7";}
	#	case /Aug/	{ $cmonth = "8";}
	#	case /Sep/	{ $cmonth = "9";}
	#	case /Okt/	{ $cmonth = "10";}
	#	case /Nov/	{ $cmonth = "11";}
	#	case /Dez/	{ $cmonth = "12";}
	#}
	switch($cmonth){
		case /Jan/	{ $cmonth = "1";}
		case /Feb/	{ $cmonth = "2";}
		case /Mar/	{ $cmonth = "3";}
		case /Apr/	{ $cmonth = "4";}
		case /May/	{ $cmonth = "5";}
		case /Jun/	{ $cmonth = "6";}
		case /Jul/	{ $cmonth = "7";}
		case /Aug/	{ $cmonth = "8";}
		case /Sep/	{ $cmonth = "9";}
		case /Oct/	{ $cmonth = "10";}
		case /Nov/	{ $cmonth = "11";}
		case /Dec/	{ $cmonth = "12";}
	}

	my $file_year;
	if ($cyear =~ /\d\d\d\d/){
		$file_year = int($cyear);
	}else{
		$file_year = $year;
	}
	my $today = Date_to_Days($year,$month,$day);
	my $yesterday = Date_to_Days($year,$month,$day) -1;
	#my $fileday = Date_to_Days($year,$month,$day);
	my $fileday = Date_to_Days($file_year,$cmonth,$file_day);

	if ($yesterday == $fileday){
		push(@current_file,$hostname);
	}elsif($today == $fileday){
		push(@current_file,$hostname);
	}else{
		push(@outdated_file,$hostname);
		$mail = 1;
	}
}
my $content="";
if ($mail != 0){
	$content = "<html>\n<head>\n<title>Check for missing or outdated Backup-Configs</title>\n</head>\n";
	$content .= "<body style=\"font-family: verdana; font-size: 11px; color: black;\"><center><h3>Check for missing or outdated Backup-Configs</h3>\n";
	$content .= "<h5>Here are displayed the hosts with missing or outdated backup config</h5><br>\n";
	$content .= "<table width=\"200px\" border=\"0\">\n";
	foreach my $var (sort @no_current_file){
		if ((!defined $var) or ($var =~ /detest/)){
			next;
		}
		#print "Var: $var\n";
		$content .= "<tr><td>Host with missing backup:</td><td><b>".$var."</b></td></tr>\n";
	}
	$content .= "<tr><td colspan=\"2\">----------------------------------------</td></tr>\n";
	foreach my $var (sort @outdated_file){
		if ((!defined $var) or ($var =~ /detest/)){
			next;
		}
		#print "Var: $var\n";
		$content .= "<tr><td>Host with outdated backup:</td><td><b>".$var."</b></td></tr>\n";
	}
	$content .= "</table>\n";
	#$content .= "<h5>For ".$nodns_hosts." hosts are the config missing - please fix it</h5>\n";
	$content .= "<h6>The script is located on watcher in the following path: /opt/scripts/check-scripts/".$script.".pl</h6><br>\n</center></body>\n";
}
if ($mail != 0){
		mailalert($mail_getter, $content,"No config 4 Host");
}
$mail=0;



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