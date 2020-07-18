

use strict;
use Getopt::Std;
use Data::Dumper;
use MIME::Lite;
use Net::SNMP v5.1.0 qw(:snmp DEBUG_ALL);
use Text::Diff;

sub mailalert($$$);


my $TO = 'mailbox@company.com';
my $TO1 = 'user@company.com';
my $atime = time;
my $username = "SNMPUser";
my $authpriv = "SNMP_Passwd!";
my $privpass = "SNMP_Secret";
my $script = "runts";
my $oid = "1.3.6.1.4.1.9.2.2.1.1.10";
my $oid_type = "1.3.6.1.4.1.9.2.2.1.1.1";
my $oid_version = "1.3.6.1.2.1.47.1.1.1.1.13";
my $count = 4;

use vars qw / $opt_C /;

$opt_C='host_config';
getopts( 'C:' ) || 
	die "$0: valid options: [-C config]\n";


# -----------------------------------------------------------------------
# read config file
# -----------------------------------------------------------------------
my %cf = ( '_default' => 
		{ 'user' => '' }
         );
my $cp = $cf{'_default'};

open( CF, "<$opt_C" ) ||
	die "can't open config file '$opt_C' for reading: $!";
while( <CF> )
{
    chomp;
    s/\s+$//;					# chop all trailing whitespace
    next if /^\s*$/ or /^\s*#/;

    $cp->{'cf'} = $_;

    if ( /^\s*host\s+(.*)/ )
    {
	my %anonhash = %{$cf{_default}};
	#print "A: ".Dumper(\%anonhash);

	$cf{$1} = \%anonhash;			# copy default values
	$cp=$cf{$1};				# set conf write ptr
	$cp->{'n'}=$1;		# temp
    }
    else
    {
	print STDERR "ERROR: syntax in config file: '$_'\n";
    }
    
}
close CF;
my $msgbuf='';
$msgbuf .= "<html>\n<head>\n<title>ERROR ALERTs</title>\n";
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
$msgbuf .= "width:280px;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.center {\n";
$msgbuf .= "text-align:center;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.good {";
$msgbuf .= "text-align:center;\n";
$msgbuf .= "width:200px;\n";
$msgbuf .= "background-color: #9BE096;\n";
$msgbuf .= "}\n";
$msgbuf .= "td.bad {text-align:center;\n";
$msgbuf .= "width:40px;\n";
$msgbuf .= "background-color: #FFAC96;\n";
$msgbuf .= "}\n";
$msgbuf .= "th {border:1px solid #DDDDDD;\n";
$msgbuf .= "font-family: 'Verdana';\n";
$msgbuf .= "font-size: 8pt;\n";
$msgbuf .= "font-weight: bold;\n";
$msgbuf .= "color: #000000;\n";
$msgbuf .= "background-color: #DDDDDD;\n";
$msgbuf .= "width:280px;\n";
$msgbuf .= "text-align:left;\n";
$msgbuf .= "}\n";
$msgbuf .= "th.tablehead {\n";
$msgbuf .= "color: #000000;\n";
$msgbuf .= "background-color: #FFFFFF;\n";
$msgbuf .= "}\n";
$msgbuf .= "</style>\n";
$msgbuf .= "</head>\n<body><center>\n";
$msgbuf .= "<table>\n";
my $combuf = $msgbuf;
$combuf .= "<tr><th colspan=\"2\" style=\"text-align:center\">The $script errors on switches</th></tr>\n";
$combuf .= "<tr>\n";
$msgbuf .= "<tr><th colspan=\"4\" style=\"text-align:center\">The $script errors on switches</th></tr>\n";
$msgbuf .= "<tr>\n";
my $i = 0; my $iter = 0; my $send = 0; my $nothing = 0;my @old_list; my @new_list; my @tmp_list; my $diffbuf;
foreach my $host ( sort ( keys %cf ) )
{
    next if $host eq '_default';		# skip default config

    print "$host -> ". Dumper( $cf{$host} );
		$iter++;
		my $buffer;
		$buffer .= "<td valign=\"top\">\n";
		my $prompt = `/usr/bin/snmpwalk -v 3 -u $username -l authpriv -A $authpriv -X $privpass $host $oid`;
		my $type = `/usr/bin/snmpwalk -v 3 -u $username -l authpriv -A $authpriv -X $privpass $host $oid_type`;
		my $ver = `/usr/bin/snmpwalk -v 3 -u $username -l authpriv -A $authpriv -X $privpass $host $oid_version`;
		my $version;
		if ( $ver =~ /.*\s*= STRING: "(.+)"/ ) {
			my @versions = split(/-/,$1);
			$version = $versions[1];
		}
		my $hostname = $host;
		$hostname =~ s/(de.*)\.company\.local/$1/g;
		$buffer .= "<table id='table'>\n";
		$buffer .= "<tr><th colspan=\"2\" style=\"text-align:center\">$hostname</th></tr>\n";
		my %if_ferr; my %if_gerr; 
		my %if_ftype; my %if_gtype;
		my @prompts = split(/\n/,$prompt);
		my @types = split(/\n/,$type);
		#print $prompt."\n------------------------------------\n".$type."\n";
		if ($version !~ /C29/i){
			foreach my $line (@prompts){
				if ( $line =~ /.*1(\d\d)(\d\d?) = INTEGER: (.+)/ ) {
					my ($gig, $int, $err) = ($1, $2, $3);
					if ($gig eq "00"){
						$if_ferr{$int} = $err;
						$if_ftype{$int} = "FastEthernet 0\/";
					} 
					elsif ( $gig == "01"){
						my $key = 1*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 1\/0\/";
					}
					elsif ( $gig == "06"){
						my $key = 2*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 2\/0\/";
					}
					elsif ( $gig == "11"){
						my $key = 3*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 3\/0\/";
					}
					elsif ( $gig == "16"){
						my $key = 4*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 4\/0\/";
					}
					elsif ( $gig == "21"){
						my $key = 5*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 5\/0\/";
					}
					elsif ( $gig == "26"){
						my $key = 6*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 6\/0\/";
					}
					elsif ( $gig == "31"){
						my $key = 7*100+$int;
						$if_gerr{$key} = $err;
						$if_gtype{$key} = "GigabitEthernet 7\/0\/";
					}					
				}
			}
		} elsif ($version !~ /C2950/i){
			foreach my $line (@prompts){
				if ( $line =~ /.*1(\d\d)(\d\d?) = INTEGER: (.+)/ ) {
					my ($gig, $int, $err) = ($1, $2, $3);
					if ($gig eq "00"){
						$if_ferr{$int} = $err;
						$if_ftype{$int} = "FastEthernet 0\/";
					} 
					else {
						$if_gerr{$int} = $err;
						$if_gtype{$int} = "GigabitEthernet 0\/";
					}
				}
			}
		} else {
			foreach my $line (@prompts){
				if ( $line =~ /.*\.(\d\d?) = INTEGER: (.+)/ ) {
					my ($int, $err) = ($1, $2);
					my $if;
					if ($int eq "1"){ $if = "01"; }
					elsif ($int eq "2"){ $if = "02"; }
					elsif ($int eq "3"){ $if = "03"; }
					elsif ($int eq "4"){ $if = "04"; }
					elsif ($int eq "5"){ $if = "05"; }
					elsif ($int eq "6"){ $if = "06"; }
					elsif ($int eq "7"){ $if = "07"; }
					elsif ($int eq "8"){ $if = "08"; }
					elsif ($int eq "9"){ $if = "09"; }
					else { $if = $int; }
					$if_ferr{$if} = $err;
				}
			}
			foreach my $line (@types){
				if ( $line =~ /.*\.(\d\d?) = STRING: "(.+)"/ ) {
					my ($int, $name) = ($1, $2);
					my $if;
					if ($int eq "1"){ $if = "01"; }
					elsif ($int eq "2"){ $if = "02"; }
					elsif ($int eq "3"){ $if = "03"; }
					elsif ($int eq "4"){ $if = "04"; }
					elsif ($int eq "5"){ $if = "05"; }
					elsif ($int eq "6"){ $if = "06"; }
					elsif ($int eq "7"){ $if = "07"; }
					elsif ($int eq "8"){ $if = "08"; }
					elsif ($int eq "9"){ $if = "09"; }
					else { $if = $int; }
					if ($name =~ /Fast Ethernet/i) {
						$if_ftype{$if} = "FastEthernet 0\/"; 
					}elsif ($name =~ /Gigabit Ethernet/i) {
						$if_ftype{$if} = "GigabitEthernet 0\/";						
					}
				}
			}
		}
		foreach my $key (sort keys %if_ftype){
			my $anz;
			if ($key eq "01"){ $anz = "1"; }
			elsif ($key eq "02"){ $anz = "2"; }
			elsif ($key eq "03"){ $anz = "3"; }
			elsif ($key eq "04"){ $anz = "4"; }
			elsif ($key eq "05"){ $anz = "5"; }
			elsif ($key eq "06"){ $anz = "6"; }
			elsif ($key eq "07"){ $anz = "7"; }
			elsif ($key eq "08"){ $anz = "8"; }
			elsif ($key eq "09"){ $anz = "9"; }
			else { $anz = $key; }
			if ( $if_ferr{$key} gt 100 ) {	
				$buffer .= "<tr><td width:200px>$if_ftype{$key}$anz</td><td class='bad'>$if_ferr{$key}</td>\n";
				$diffbuf .= "$hostname + $if_ftype{$key}$anz + $if_ferr{$key}\n";
				$send = 1;
			}
		}
		foreach my $key (sort keys %if_gtype){			
			my $anz;
			if ($key eq "01"){ $anz = "1"; }
			elsif ($key eq "02"){ $anz = "2"; }
			elsif ($key eq "03"){ $anz = "3"; }
			elsif ($key eq "04"){ $anz = "4"; }
			elsif ($key eq "05"){ $anz = "5"; }
			elsif ($key eq "06"){ $anz = "6"; }
			elsif ($key eq "07"){ $anz = "7"; }
			elsif ($key eq "08"){ $anz = "8"; }
			elsif ($key eq "09"){ $anz = "9"; }
			elsif (( 100 < $key ) && ($key < 200 )) { $anz = $key - 100; }
			elsif (( 200 < $key ) && ($key < 300 )) { $anz = $key - 200; }
			elsif (( 300 < $key ) && ($key < 400 )) { $anz = $key - 300; }
			elsif (( 400 < $key ) && ($key < 500 )) { $anz = $key - 400; }
			elsif (( 500 < $key ) && ($key < 600 )) { $anz = $key - 500; }
			elsif (( 600 < $key ) && ($key < 700 )) { $anz = $key - 600; }
			elsif (( 700 < $key ) && ($key < 800 )) { $anz = $key - 700; }
			else { $anz = $key; }
			if ( $if_gerr{$key} gt 100 ) {	
				$buffer .= "<tr><td width:200px>$if_gtype{$key}$anz</td><td class='bad'>$if_gerr{$key}</td>\n";
				$diffbuf .= "$hostname + $if_gtype{$key}$anz + $if_gerr{$key}\n";
				$send = 1; 
			}
		}
		$buffer .= "</tr></table><br>\n";
		$buffer .= "</td>\n";
		$i++ if ($send == 1);
		if ($i == $count) {
			$buffer .= "</tr>\n<tr align=\"top\">\n";
			$i=0;
		}	
		if ($send != 0){
			$msgbuf .= $buffer; 
			push(@tmp_list,$diffbuf);
			$diffbuf = "";
			$buffer = "";
			$send = 0;
			$nothing = 1;
		}
		
	}
my $new_file = "/scripts/html/switch-error/txt/".$script.".conf";
my $old_file = "/scripts/html/switch-error/txt/".$script."_old.conf";
open(FILE,">$new_file");
foreach my $line (@tmp_list){
	print FILE $line."\n";
}
close FILE;
open(FILE,"<$old_file");
@old_list = <FILE>;
close FILE;


foreach my $line (@tmp_list){
	push(@new_list,$line."\n");
}

my $out = diff( $old_file, $new_file, { STYLE => 'Unified' });
my @lines = split(/\n/, $out);
my ($new_host,$new_port,$new_count,$old_host,$old_port,$old_count, $cur_count) = ("","",0,"","",0,0);
my $last_host = "";
$combuf .= "<td valign=\"top\" style=\"text-align:center\">\n" if ($out ne "");  
foreach my $line (@lines){
		if ($line =~ /^-(de.*-swt.*) \+ (.*) \+ (\d*)/i){
			$new_host = $1; $new_port = $2; $new_count = $3;
		}
		if ($line =~ /^\+(de.*-swt.*) \+ (.*) \+ (\d*)/i){
			$old_host = $1; $old_port = $2; $old_count = $3;
			$cur_count = $old_count-$new_count;
			if (($new_host eq $old_host) && ($new_port eq $old_port)){
				#print "On ".$new_host." and Port ".$new_port." are ".$cur_count." new errors the ".$last_host." was.\n";
				$combuf .= "<table id='table'>\n";
				if ($new_host ne $last_host) {
					$combuf .= "<tr><th colspan=\"2\" style=\"text-align:center\">$new_host</th></tr>\n";
					$combuf .= "<tr><td width:200px>$new_port</td><td class='bad'>$cur_count</td>\n";
					$last_host = $new_host;
				} else {
					$combuf .= "<tr><td width:200px>$new_port</td><td class='bad'>$cur_count</td>\n";
				}
				$combuf .= "</tr></table>\n";
			}
		}
}
my $etime = time;
my $time = $etime - $atime;

$msgbuf .= "<td valign=\"top\" style=\"text-align:center\">none were found</td>\n" if ($nothing == 0);
$msgbuf .= "</tr></table><br>\n";
$msgbuf .= "<p class=MsoNormal><font size=1 face=Verdana><span style='font-size:8.0pt;\n";
$msgbuf .= "font-family:Verdana'><br>\n";
$msgbuf .= "These values are lifetime error messages and cannot reseted by clearing or rebooting of the device!\n<br><br>";
$msgbuf .= "There were ".$iter." switches in ".$time." seconds checked.\n";
$msgbuf .= "<br>The script is located on watcher in the following path: /scripts/check/check_".$script."_error.pl<br>\n";
$msgbuf .= "<o:p></o:p></span></font></p> \n";
$msgbuf .= "</body>\n</html>\n";
if ($out eq ""){
	$combuf .= "<td valign=\"top\" style=\"text-align:center\" class='good'>\n";
	$combuf .= "none were found</td>\n";
} else {
	$combuf .= "</td>\n";
}
$combuf .= "</tr></table><br>\n";
$combuf .= "<p class=MsoNormal><font size=1 face=Verdana><span style='font-size:8.0pt;\n";
$combuf .= "font-family:Verdana'><br>\n";
$combuf .= "There were ".$iter." switches in ".$time." seconds checked.\n";
$combuf .= "<br>The script is located on watcher in the following path: /scripts/check/check_".$script."_error.pl<br>\n";
$combuf .= "<o:p></o:p></span></font></p> \n";
$combuf .= "</body>\n</html>\n";

mailalert($TO, $combuf, $script) if ($out ne "");
my $current_file = "/var/www/html/switch-error/current_".$script."_error.html";
open(FILE,">$current_file");
print FILE $combuf;
close FILE;
my $file = "/var/www/html/switch-error/check_".$script."_error.html";
open(FILE,">$file");
print FILE $msgbuf;
close FILE;

system("mv -f $new_file $old_file");
#functions	
sub mailalert($$$){
my $receiver = shift;
my $content = shift;
my $head = shift;
my $sub = $head." errors";
my $email = MIME::Lite->new(
	Subject	=>	$sub,
	From	=>	'swterrors@company.com',
	To		=>	$receiver,
	Type	=>	'text/html',
	Data	=>	$content
);
$email->send();
}

sub del_doubles{ 
my %all;
grep {$all{$_}=0} @_;
return (keys %all);
}