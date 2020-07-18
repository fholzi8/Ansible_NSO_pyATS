#author:	Florian Holzapfel
#email:		fholzi8@gmail.com
#date:		18-Mar-2011
#version:	1.0
#
#
###################################################################################################
########################                     MODULES                    ###########################
###################################################################################################
#
#

use strict;
use Net::SNMP;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use Mysql;
use PDF::Reuse;
use Switch;
use DateTime;

###################################################################################################
########################                     FUNCTIONS                  ###########################
###################################################################################################
#
#
sub collect_nagios_host($);
sub mail_missing_hosts($$);
sub mail_diff_configs($$);

###################################################################################################
########################                     VARIABLES                  ###########################
###################################################################################################
#
my $script = "diff-checker";
my $content = "";
#my $mail_getter = 'mailbox@company.com';
my $mail_getter = "user\@company.com, user2\@company.com";
my $no_mail = 1;
my $rev_neu = "";
my $rev_alt = "";
my $config_date = "";
my $change_date = "";
my $namediff = "";
my @hosts = ();
my @missing_hosts = ();
my $next_hosts = 0;
my $cdate = "";
my $date = "";


#Datum f�r Gestern und Heute in Format
my $dt = DateTime->now;
my ($ddt, $mdt, $ydt) = ($dt->day, $dt->month, $dt->year);
#gestern
my $nday = $ddt-1;
my $nmonth = $mdt;
if ($nmonth < 10){
	$nmonth = "0".$nmonth;
}
if ($nday < 10){
	$nday = "0".$nday;
}
$cdate = "$ydt-$nmonth-$nday";
#heute
my $cdat = $ddt;
my $cmonth = $mdt;
if ($cmonth < 10){
	$cmonth = "0".$cmonth;
}
if ($cdat < 10){
	$cdat = "0".$cdat;
}
$date = "$ydt-$cmonth-$cdat";

#helperfile
open(TMP,">/tftpboot/kron/tmp") or die("Fehler beim oeffnen $!");


#array dynamisch machen
#
#
my @locations = ("agb","bay","bbi","bfe","boc","bre","cgn","che","dtm","dus","ess","fkb","fra","haj","ham","hdb","kem","klt","lej","mhg","muc","nue","str","szw","wie");


#sammeln der nagios_hosts
my $dot1x_group = "Dot1x-Client-Switch";
my $network_group = "Network_Devices";
#host_array aus nagios_db abfrage mittels hostgroup
my @nagios_hosts = collect_nagios_host($network_group);
my @ng_hosts = @nagios_hosts;


foreach my $location (sort @locations){

	my $direction = "/tftpboot/kron/$location";
	opendir(DIR,$direction);
	my @files = readdir(DIR);
	closedir(DIR);

	foreach my $var (sort @files){
		if ($var =~ /.*conf/){
			$var =~ s/(.*)\.conf/$1/g;
			push(@hosts,$var);
			for (my $i=0;$i<@ng_hosts;$i++){
				if ($ng_hosts[$i] eq $var){
					delete $nagios_hosts[$i];
				}
			}
		}
	}

	foreach my $hostname (sort @hosts){

		#make a diff
		my $info_buffer = `svn info /tftpboot/kron/$location/$hostname.conf 2>/dev/null`;
		my @list_info_buffer = "";
		@list_info_buffer = split( /[\n\r]+/, $info_buffer );
		foreach my $line (@list_info_buffer){
			if ($line =~ /Letzte ge�nderte Rev: (.*)/){
				$rev_neu = $1;
			} elsif ($line =~ /Text zuletzt ge�ndert: (.*) \d\d:\d.*/){
				$config_date = $1;
				#print TMP "Hostname: $hostname\tConfig_date: $config_date Yesterday: $cdate\n";
				if ($config_date ne $date){
						print TMP "Hostname: $hostname\tConfig_date: $config_date Yesterday: $date\n";
						print "Hostname: $hostname\tConfig_date: $config_date Yesterday: $date\n";
						my $reason = "$hostname\t-\t(Date should be $date is $config_date)";
						push(@missing_hosts, $reason);
						#print "$hostname is missing\n";
				}
			} elsif ($line =~ /�nderungsdatum: (.*) \d\d:\d.*/){
				$change_date = $1;
				#print "Change_date: $change_date Today: $date\n";
				if ($change_date ne $date){
					#print "Change_date: $change_date Today: $date\n";
					$next_hosts = 1;
				}
			} else {
				next;
			}
		}

		print TMP "Hostname: $hostname\tConfig_date: $config_date Yesterday: $date\n";

		if ($next_hosts == 1){
			$next_hosts = 0;
			next;
		}


		my @list_diff_buffer = "";
		my $diff_buffer;
		$diff_buffer = `svn diff -c $rev_neu /tftpboot/kron/$location/$hostname.conf 2>/tftpboot/kron/errors`;
		@list_diff_buffer = split( /[\n\r]+/, $diff_buffer );

		$rev_neu = "";

		my $filename = "/tftpboot/kron/all_hosts.diff";
		#`touch $filename`;
		open(FILE,">>$filename") or die("Fehler bei open $filename $!");
		print TMP "\nHostname:\t $hostname\n\n";
		print FILE "\nHostname:\t $hostname\n\n";
		my ($username, $date) = ("","");
		foreach my $value (@list_diff_buffer) 	{
			if ( $value =~ /^(---|\+\+\+|@@)/ ) {
					next;
			}  elsif ( $value =~ /^Index.*\/(.*)\.conf/ ){
					next;
			} elsif ( $value =~ /^\+.*Last configuration .* at (.*) CET (.*) by (.*)/ ) {
				$date = "$1 $2";
				$username = $3;
				next;
			} elsif ( $value =~ /^-!.*/ ){
				next;
			} elsif ( $value =~ /^\+!.*/ ){
				next;
			} elsif ( $value =~ /^\=.*/ ){
				next;
			} elsif ( $value =~ /^!.*/ ){
				print FILE "\n";
				next;
			} elsif ( $value =~ /.*NVRAM.*/ ){
				next;
			}
			print FILE "$value\n";

		}
		if ($username ne ""){
				print FILE "Last change at ".$date." by ".$username."\n";
		}
		print FILE "\n==============================================\n\n";

		close (FILE);
	}
	@hosts = ();
}

close(TMP);


for (my $i=0;$i<@nagios_hosts;$i++){
	if (defined $nagios_hosts[$i]){
		if ($nagios_hosts[$i] !~ /internal-gateway/){
			push(@missing_hosts,$nagios_hosts[$i]);
		}
	}
}

my $anzahl_hosts = scalar(@missing_hosts);
$anzahl_hosts = $anzahl_hosts - 1;
#print "Anz: $anzahl_hosts\n";
if ($anzahl_hosts != 0){
	my $missingfile = "/tftpboot/kron/missing.hosts";
	open(FILE,">$missingfile") or die("Fehler bei open $missingfile $!");
	foreach my $var (sort @missing_hosts){
		if ((!defined $var) or ($var eq "test-vpn1")){
			next;
		}
		print FILE "$var\n";
	}
	close (FILE);
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
	#select statement (get all host from $hostgroup)
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

sub mail_missing_hosts($$){
	my $receiver = shift;
	my $content = shift;

	my $email = MIME::Lite->new(
		Subject	=>	'Missing Hosts',
		From	=>	'dot1x@company.com',
		To		=>	$receiver,
		Type	=>	'text/html',
		Data	=>	$content
	);
	$email->send();
}

sub mail_diff_configs($$){
	my $receiver = shift;
	my $content = shift;

	my $email = MIME::Lite->new(
		Subject	=>	'Configuration Diff',
		From	=>	'dot1x@company.com',
		To		=>	$receiver,
		Type	=>	'text/html',
		Data	=>	$content
	);
	#$email->attr("content-type"	=> "multipart/mixed");
	$email->attach(
			Type		=> 'application/pdf',
			Path		=> '/tftpboot/kron/configuration-diff.pdf',
			Filename	=> 'configuration-report.pdf',
			Disposition => 'attachment'
	);
	$email->send();
}