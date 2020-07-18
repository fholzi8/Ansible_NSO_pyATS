#!/usr/bin/perl
#OTRS-Config-Change
#
use strict;
use Net::SNMP;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use Mysql;
use PDF::Reuse;
use Switch;


#function
sub mail_diff_configs($$);
sub mailalert2otrs($$$);


#global vars
my $script = "diff-parser";
#my $mail_getter = 'mailbox@company.com';
#my $TO_OTRS = 'otrs@company.com';
my $TO_OTRS = 'user@company.com, user2@company.com';
my $mail_getter = "user\@company.com, user2\@company.com";
my $no_mail = 1;


my @log_parser;
my $filename = "/tftpboot/kron/all_hosts.diff";
open(FILE, "<$filename") or die("Fehler bei open $filename $!");
@log_parser = <FILE>;
close(FILE);
open(FILE, ">$filename") or die("Fehler bei open $filename $!");
print FILE "";
close(FILE);


my %HoH;
my $i;
my $reference;
my @hosts;
my ($old_host, $hostname) = ("","");
my $ndl = "";
my $old_ndl = "";
my @ndl_hosts;
my $html_content = "";
my $change_tmp = "";
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);

#durch alle diff-�nderungen einlesen
foreach my $line (@log_parser){
	if ($line eq ""){ 
		next; 
	}
	elsif ($line =~ /^=+/){ 
		next; 
	}
	elsif ($line =~ /^.*!/){ 
		next; 
	}
	if ($line =~ /Hostname/){
		$hostname = $line;
		$hostname =~ s/.*Hostname:\s*(de.*)\s*/$1/g;
		push (@hosts, $hostname);
	}
	if ($old_host eq $hostname){
		$i++;
	} else {
		$old_host = $hostname;
		$i = 1;
	}
	my $temp = "$i#$line";
	my ($key, $value) = split(/#/,$temp);
	if ($value =~ /Hostname/){
		next;
	}
	if ($hostname eq ""){
		next;
	}
	$reference->{$key}->{$hostname} = $value;

}

#entfernen von unn�tigen �nderungen wie ntp clock etc.
foreach my $host (sort @hosts){
	my $next3lines = 0;
	foreach my $nr (sort %$reference){
		my $line = $reference->{$nr}->{$host};
		if (defined $line){
				 $HoH{$host}{$nr}=$line;
				 if ($line =~ /^\s+$/){
				 	delete $HoH{$host}{$nr};
			 	} elsif ($line =~ /^-\s*ntp/){
			 		$next3lines = 3;
				 	for (my $j=3; $j > 0; $j--){
				 		my $key = int($nr) - $j;
				 		$key = sprintf "%s",$key;
				 		if (!defined $HoH{$host}{$key}){
				 			next;
				 		} elsif ($HoH{$host}{$key} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$key};
				 		}
				 	}
				 	delete $HoH{$host}{$nr};
			 	}  elsif ($line =~ /^-\s*switchport .* sticky [a-f0-9].*/){
			 		$next3lines = 3;
				 	for (my $j=3; $j > 0; $j--){
				 		my $key = int($nr) - $j;
				 		$key = sprintf "%s",$key;
				 		if (!defined $HoH{$host}{$key}){
				 			next;
				 		} elsif ($HoH{$host}{$key} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$key};
				 		}
				 	}
				 	delete $HoH{$host}{$nr};
			 	}  elsif (($line =~ /^-\s*description.*changed by.*/) or ($line =~ /^-\s*description.*dot1x.*/i)){
			 		$next3lines = 3;
				 	for (my $j=3; $j > 0; $j--){
				 		my $key = int($nr) - $j;
				 		$key = sprintf "%s",$key;
				 		if (!defined $HoH{$host}{$key}){
				 			next;
				 		} elsif ($HoH{$host}{$key} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$key};
				 		}
				 	}
				 	delete $HoH{$host}{$nr};
			 	} elsif ($HoH{$host}{$nr} =~ /^\+\s*ntp/){
					$next3lines = 3;
					for (my $j=3; $j > 0; $j--){
				 		my $key = int($nr) - $j;
				 		$key = sprintf "%s",$key;
				 		if (!defined $HoH{$host}{$key}){
				 			next;
				 		} elsif ($HoH{$host}{$key} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$key};
				 		}
				 	}
				 	delete $HoH{$host}{$nr};
				} elsif ($HoH{$host}{$nr} =~ /^\+\s*switchport .* sticky [a-f0-9].*/){
					$next3lines = 3;
					for (my $j=3; $j > 0; $j--){
				 		my $key = int($nr) - $j;
				 		$key = sprintf "%s",$key;
				 		if (!defined $HoH{$host}{$key}){
				 			next;
				 		} elsif ($HoH{$host}{$key} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$key};
				 		}
				 	}
				 	delete $HoH{$host}{$nr};
				} elsif (($HoH{$host}{$nr} =~ /^\+\s*description.*changed by.*/) or ($line =~ /^-\s*description.*dot1x.*/i)){
					$next3lines = 3;
					for (my $j=3; $j > 0; $j--){
				 		my $key = int($nr) - $j;
				 		$key = sprintf "%s",$key;
				 		if (!defined $HoH{$host}{$key}){
				 			next;
				 		} elsif ($HoH{$host}{$key} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$key};
				 		}
				 	}
				 	delete $HoH{$host}{$nr};
				} elsif ($next3lines != 0){ 
					$next3lines--;
					if (!defined $HoH{$host}{$nr}){
				 			next;
				 	} elsif ($HoH{$host}{$nr} !~ /^(-|\+).*/){
				 			delete $HoH{$host}{$nr};
				 	}
				} elsif ($line =~ /^\s+version/){
					delete $HoH{$host}{$nr};
				} elsif ($line =~ /^\s+.*service pad/){
				 	delete $HoH{$host}{$nr};
				} elsif ($line =~ /^\s+end/){
				 	delete $HoH{$host}{$nr};
				} elsif ($line =~ /^\s+service timestamps/){
				 	delete $HoH{$host}{$nr};
				} elsif ($line =~ /^\s+ntp server/){
					delete $HoH{$host}{$nr};
				} elsif ($line =~ /^\s+ntp access/){
					delete $HoH{$host}{$nr};
				} elsif ($line =~ /^\s+Last change/){
					delete $HoH{$host}{$nr};
				} elsif ($HoH{$host}{$nr} =~ /^(-|\+).*/){
					$HoH{$host}{0}= 1;
				} 
		} else {
			next;
		}	
	}
}

#entfernen von hosts ohne �nderungen
foreach my $host (sort keys %HoH){
	
	if ($HoH{$host}{0} !~ /^1$/){
		delete $HoH{$host};
	}
	delete $HoH{$host}{0};
	my $size = scalar keys %{$HoH{$host}};
	if ($size < 2){
		delete $HoH{$host};
	}
	
}

#erstellung des html contents
$html_content .= "<html>\n<body>\n";
$html_content .= "<center><h1>Configuration-Diff of Network Devices</h1></center>\n";

#erstellung des pdf contents
prFile('/tftpboot/kron/configuration-diff.pdf');
prFont('TB');
prFontSize(22);

my @pageMarks;
my $step = 14;
my $page = 0;
my ($x, $y) = (50, 760);
my $string_pdf = "      Configuration-Diff of Network Devices\n";
prText($x, $y, $string_pdf);
$y -= (3*$step);



#erstellung der �nderungen
foreach my $host (sort keys %HoH){
	my $location = $host;
	if (($location =~ /muc-...\d\d\d/) or ($location =~ /muc-swt5\d/) or ($location =~ /muc-vpn0\d/) or ($location =~ /muc-blade2/)){
		$location = "muc-rz";
	}elsif(($location =~ /muc-swt[0-4]\d/) or ($location =~ /muc-mls0\d/) or ($location =~ /muc-blade1/)){
		$location = "muc-hq";
	}else{
		$location =~ s/de(...).*/$1/g;
	}
	switch ($location) {
			case /agb/ { $ndl = "Augsburg";}
			case /ess/ { $ndl = "Essen";}
			case /bfe/ { $ndl = "Bielefeld";}
			case /fkb/ { $ndl = "Karlsruhe";}
			case /dtm/ { $ndl = "Dortmund";}
			case /bre/ { $ndl = "Bremen";}
			case /lej/ { $ndl = "Leipzig";}
			case /mhg/ { $ndl = "Mannheim";}
			case /haj/ { $ndl = "Hannover";}
			case /wie/ { $ndl = "Wiesbaden";}
			case /nue/ { $ndl = "Nuernberg";}
			case /hdb/ { $ndl = "Schwetzingen";}
			case /bbi/ { $ndl = "Berlin";}
			case /dus/ { $ndl = "Duesseldorf";}
			case /fra/ { $ndl = "Frankfurt";}
			case /ham/ { $ndl = "Hamburg";}
			case /cgn/ { $ndl = "Koeln";}
			case /str/ { $ndl = "Stuttgart";}
			case /bay/ { $ndl = "Bayreuth";}
			case /boc/ { $ndl = "Bocholt";}
			case /che/ { $ndl = "Chemnitz";}
			case /klt/ { $ndl = "Kaiserslautern";}
			case /kem/ { $ndl = "Kempten";}
			case /szw/ { $ndl = "Schwerin";}
			case /muc-hq/ { $ndl = "M�nchen Headquarter";}
			case /muc-rz/ { $ndl = "M�nchen Rechenzentrum";}
			else { $ndl = "Unknown";}
	}
	prFont('TB');
	prFontSize(14);
	if ($ndl ne $old_ndl){
		$change_tmp .= "<table>\n";
		$change_tmp .= "<tr><td>Evaluierung �berpr�fung auf Vollst�ndigkeit und Richtigkeit:</td><td>IOS-Implementation</td></tr>\n";
		$change_tmp .= "<tr><td>Verkn�pfen mit Config-Item: <b>".join(" ",@ndl_hosts)."</b></td></tr></table><br><br>\n";
		$change_tmp .= "</body></hmtl>\n";
		mailalert2otrs( $TO_OTRS, $change_tmp, $old_ndl ) if $old_ndl ne "";
		$change_tmp = "";
		@ndl_hosts = ();
		$old_ndl = $ndl;
		$html_content .= "<br><h3>$ndl</h3>\n";
		$string_pdf = "$ndl\n";
		$y -= (2*$step);	
		prText($x, $y, $string_pdf);
		my $bookmarks = {	text	=>	"Niederlassung $ndl",
											act		=>	"$page, $x, ".($y-14)."	"};
		if ($y < 90 ){
			prFont('TB');
			prFontSize(10);
			my $pgnr = $page +1;
			prText(275, 30, "- page $pgnr -");
			prPage();
			$page += 1;
			$y = 760;
		}
		push @pageMarks, $bookmarks;
		#$y -= (2*$step);
		
		#auswahl um welches ger�t es sich handelt
		my $sender = $host;
		if ($sender =~ /swt/){
			$sender = "switch";
		}elsif ($sender =~ /(vpn|mls)/){
			$sender = "router";
		}elsif ($sender =~ /acp/){
			$sender = "accesspoint";
		}
		#changeticket matrix erstellen
		$change_tmp .= "<html>\n<head>\n<title>Change in $ndl</title>\n</head>\n";
		$change_tmp .= "<body style=\"font-family: consolas; font-size: 10px; color: black;\"><center><h3>Networkchange in $ndl</h3>\n";
		$change_tmp .= "<table>\n";
		my $date;
		if ($mon < 9 ){
			$date = ($mday - 1)."-0".($mon + 1)."-".($year + 1900);
		} else {
			$date = ($mday - 1)."-".($mon + 1)."-".($year + 1900);
		}
		if ($location =~ /muc-rz/){
			$change_tmp .= "<tr><td>Ticketname:</td><td>major Change: $ndl at ".$date."</td></tr>\n";
		}else{
			$change_tmp .= "<tr><td>Ticketname:</td><td>normal Change: $ndl at ".$date."</td></tr>\n";
		}
		$change_tmp .= "<tr><td>Grund:</td><td>gesch�tzten Netzwerkzugriff erlauben</td></tr>\n";
		$change_tmp .= "<tr><td>Bearbeiter:</td><td>Network and Security Services</td></tr>\n";
		$change_tmp .= "<tr><td>Kunde:</td><td>Sonne, Michael</td></tr>\n";
		if ($location =~ /muc-rz/){
			$change_tmp .= "<tr><td>Dringlichkeit:</td><td>1 - hohe Dringlichkeit</td></tr>\n";
			$change_tmp .= "<tr><td>Auswirkung:</td><td>2 - gro�e Auswirkung</td></tr>\n";
		}else{
			$change_tmp .= "<tr><td>Dringlichkeit:</td><td>2 - mittlere Dringlichkeit</td></tr>\n";
			$change_tmp .= "<tr><td>Auswirkung:</td><td>3 - mittlere Auswirkung</td></tr>\n";			
		}
		$change_tmp .= "<tr><td>Hinweis:</td><td>nicht security-relevant</td></tr>\n"; 
		$change_tmp .= "<tr><td>Planung notwendige Resourcen:</td><td>SSH Console</td></tr>\n";
		$change_tmp .= "<tr><td>wichtige Dokumente:</td><td>Testprozedur: in Test-Niederlassung (exakte Abbildung einer NDL)</td></tr>\n";
		$change_tmp .= "<tr><td>Koordinierung:</td><td>Livestellungstermin: jederzeit</td></tr>\n";
		$change_tmp .= "<tr><td>Dokumentation und Information:</td><td>�nderungen hier enthalten</td></tr></table><br>\n";
	}
	push @ndl_hosts, $host;
	prFont('TB');
	prFontSize(12);
	$change_tmp .= "<table border=\"0\" width=\"100%\"><tr><td width=\"30%\"><b>Hostname:</b></td><td width=\"70%\"><b>$host</b></td></tr>\n";
	$html_content .= "<table border=\"0\" width=\"100%\"><tr><td width=\"30%\"><b>Hostname:</b></td><td width=\"70%\"><b>$host</b></td></tr>\n";
	$string_pdf = "\nHostname:\t $host\n";
	$y -= 14;	
	prText($x, $y, $string_pdf);
	if ($y < 90 ){
		prFont('TB');
		prFontSize(10);
		my $pgnr = $page +1;
		prText(275, 30, "- page $pgnr -");
		prPage();
		$page += 1;
		$y = 760;
	}
	$y -= $step;
	$string_pdf = "";
	foreach my $nr ( sort {$a <=>$b} keys %{$HoH{$host}}){
		$string_pdf = "$HoH{$host}{$nr}\n";
		if ( $HoH{$host}{$nr} =~ /^(\+|-)/){
			prFont('TB');
		} else {
			prFont('TR');
		}
		prFontSize(10);
		prText(($x+40), $y, $string_pdf);
		if ($y < 90 ){
			prFont('TR');
			prFontSize(10);
			my $pgnr = $page +1;
			prText(275, 30, "- page $pgnr -");
			prPage();
			$page += 1;
			$y = 760;
		}
		$y -= $step;
		if ( $HoH{$host}{$nr} =~ /^-.*/ ){
			$change_tmp .= "<tr><td width=\"30%\">&nbsp;</td><td bgcolor=\"#ff6600\" width=\"70%\"><h5>$HoH{$host}{$nr}</h5></td></tr>\n";
			$html_content .= "<tr><td width=\"30%\">&nbsp;</td><td bgcolor=\"#ff6600\" width=\"70%\"><h5>$HoH{$host}{$nr}</h5></td></tr>\n";
		} elsif ( $HoH{$host}{$nr} =~ /^\+.*/ ){
			$change_tmp .= "<tr><td width=\"30%\">&nbsp;</td><td bgcolor=\"#00cc00\" width=\"70%\"><h5>$HoH{$host}{$nr}</h5></td></tr>\n";
			$html_content .= "<tr><td width=\"30%\">&nbsp;</td><td bgcolor=\"#00cc00\" width=\"70%\"><h5>$HoH{$host}{$nr}</h5></td></tr>\n";
		} else {
			$change_tmp .= "<tr><td width=\"30%\">&nbsp;</td><td width=\"70%\"><h5>$HoH{$host}{$nr}</h5></td></tr>\n";
			$html_content .= "<tr><td width=\"30%\">&nbsp;</td><td width=\"70%\"><h5>$HoH{$host}{$nr}</h5></td></tr>\n";
		}
	}
	$html_content .= "</table><br>\n";
	$change_tmp .= "</table><br>\n";
}

$html_content .= "<h6>The script is located on watcher in the following path: /scripts/check/".$script.".pl</h6><br>\n</center></body>\n";
$html_content .= "</body></html>\n";

#erstellung der bookmarks f�r das pdf
prBookmark( { text => 'Configuration-Diff of Network Devices',
							act => "0, 35, 760",
							close => 1,
						kids	=>	\@pageMarks } );

#ende des pdfs
prEnd();

my $anzahl = scalar keys %HoH;
if ($anzahl != 0){
		$no_mail = 0;
	}
if ($no_mail != 1) {
  #MAIL-ALERTING
  $html_content = "<html><body><h1>Configuration Report</h1><br>\n";
  $html_content .= "<br>The Report is attached in the PDF-File. An Change Ticket for the branches is automatically created\n</body></hmtl>";
  mail_diff_configs($mail_getter, $html_content);
  
}

#mail-versand
sub mail_diff_configs($$){
	my $receiver = shift;
	my $content = shift;
	
	my $email = MIME::Lite->new(
		Subject	=>	'Configuration Report',
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

sub mailalert2otrs($$$){
my $receiver = shift;
my $content = shift;
my $switch = shift;
my $sub = "Config Change in : ".$switch."\n";
my $email = MIME::Lite->new(
	Subject	=>	$sub,
	From	=>	'dot1x@company.com',
	To		=>	$receiver,
	Type	=>	'text/html',
	Data	=>	$content
);
$email->send();
}