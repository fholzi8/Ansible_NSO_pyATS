

#our $logbase = "ssh_copyconfig";
#do "/opt/scripts/generic-log.pl";

#loading modules
use strict;
use Net::SSH2;
use Net::Ping;
use Getopt::Std;
use MIME::Lite;
use Data::Dumper;
use DBI();
use Switch;


sub mailalert($$$);
sub collect_nagios_host($);
sub check_date();
sub cisco_command($$);

#global variables

#my $mail_getter = "mailbox\@company.com";
my $mail_getter = "user\@company.com";#, user2\@company.com";
my $no_mail = 1;
my $script = "ssh_copyconfig";
#my $tftp_server = '10.11.14.215';
my $tftp_server = '10.11.14.221';
#my $backup_path = '/opt/network_backup/tftp/networkdevice_backup';
my $user = "ciscobackup";
my $pass = "7HrPdY!7VUEENQYx9etR2a=9";
#my $pwd_weblb = "7HrPdY!7VUEENQYx9etR2a=9"; #ciscobackup (nur f�r Loadbalancer!) 
my $ssh2;
my $prompt;
our $retbuf;

#sammeln der nagios_hosts
my $asa_group = "ASA";

#host_array aus nagios_db abfrage mittels hostgroup
my @asa_hosts = collect_nagios_host($asa_group);

my @hosts;
my @weblbs = ("hostname","derz1-lb2","derz2-lb1","derz2-lb2","derz2-core1","derz2-core1-external","derz2-core1-m-internal","derz2-core1-f-internal","derz2-core2","derz2-core2-external","derz2-core2-m-internal","derz2-core2-f-internal");
push (@hosts, @asa_hosts);
push (@hosts, @weblbs);
my $count_host = 0;
#ping aufbauen
my $ping = Net::Ping->new("icmp");
my $source = '10.11.14.221';
$ping->bind($source);

foreach my $hostname (sort @hosts){
	
	if ($hostname =~ /.*-internal-.*/){
		next;
	}elsif ($hostname =~ /detest/){
		next;
	}elsif ($hostname =~ /standby/){
		next;
	}
  unless ($ping->ping($hostname, 2)){
  	print "Not reachable $hostname\n";
  	next;
  }
  $count_host++;
	chomp($hostname);
	print "Hostname: $hostname\n"; 
# Create the SSH session - with Privilege Level 1 Permission
	#$prompt = '';
	$ssh2 = Net::SSH2->new();
    #
    # connect() needs to be done in eval - it will die on errors
    # 
  eval { $ssh2->connect($hostname); };
	my $i=0;
	BEGIN:
	unless( $ssh2->auth_password($user, $pass) ){
		my $m = "ssh2->auth_password() failed: $!";
		while( $i<3 ){
		 $i++;
		 sleep(10);
		 goto BEGIN;
		}
		print STDERR "$m\n";
		next;
  }
	#my $location = $hostname;
	#if(($location =~ /muc-swt[0-4]\d/) or ($location =~ /muc-mls0\d/) or ($location =~ /muc-rt/)){
	#	$location = "muc-hq";
	#}elsif($location =~ /diba/){
	#	$location = "rz1";
	#}else{
	#	$location =~ s/de(...).*/$1/g;
	#}
	#my $dir = "$backup_path";
	#unless (-d $dir){
	#	mkdir($dir);
	#	my $dir_rights = `chown -R user.LINUX_USER $dir`;
	#}
  #print "establish command channel...\n";
  my $chan=$ssh2->channel();
  unless( $chan->pty('vt100') ){
		my $m = "chan->pty() failed: $!";
		#print STDERR "$hostname: $m\n";
		next;
  } unless( $chan->shell() ){
		my $m = "chan->shell() failed: $!";
		#print STDERR "$hostname: $m\n";
		next;
  }

  my $dest_config;
  my $sourc_config;
  my $copy_result;
  if ($hostname =~ /(.*)-mgmt/){
		$hostname = $1;
	}
  #$copy_result = `cp -f $backup_path/$location/$hostname.conf $backup_path/$location/$hostname.old`;
  my $ref_date = check_date();
  $dest_config = "backup/$hostname$ref_date.conf";
  $sourc_config = "running-config";
  my $cmd;
  if ($hostname =~ /derz2-core/ ){
	$cmd = "copy $sourc_config tftp://$tftp_server/$dest_config vrf management\n\n\n\n";
  } else {
  	$cmd = "copy $sourc_config tftp://$tftp_server/$dest_config\n\n\n\n";
  }
  #print $cmd;
  unless( $chan->write( "$cmd" ) ) {
		die "error sending command to cisco: $!";
  }
  sleep(5);
  $dest_config = "";
  unless( $chan->write( "exit\n" ) ) {
	die "error sending exit to cisco: $!";
  }
  $chan->close();
  $ssh2->disconnect();	
}

$ping->close();

#print "\nConfig saved for $count_host hosts\n";


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

sub cisco_command($$)
{
my $chan=shift;
my $cmd=shift;
my $rbuf='';
my $rc;

    #print "* send: '$cmd' *";
    unless( $chan->write( "$cmd\n" ) )
    {
	die "error sending command to cisco: $!";
    }
		
    while(1)
    {
			my $chref = { handle=>$chan, 
                      events=>['in', 'hup', 'err'],
                      revents=> {} };
        
        $rc = $ssh2->poll( 600, [ $chref ] );
        if ( ! defined $rc )
				{
	    	die "error in ssh2->poll(): $!";
				}
				last if $rc == 0;		# timeout

       #print Dumper( \$chref );

				# remote side went away
					if ( defined $chref->{revents}->{listener_closed} ||
					     defined $chref->{revents}->{channel_closed} )
					{
					    #print "\n<connection closed by foreign host>\n";
					    last;
					}
		
				my $tbuf = ' ' x 600;
				unless( $chan->read( $tbuf, 600 ) )
					{
					    die "error reading response from cisco: $!";
					}
				#print $tbuf;
				$rbuf .= $tbuf;
		
			#
			# quick exit from loop if we find an (previously-known) cli prompt
			#
			#print "Promtp: $retbuf L\n";
			#last if ( $prompt ne '' and $tbuf =~ /$prompt$/ );
			last if ( $retbuf ne '' and $tbuf =~ /$retbuf$/ );
			
    }
    #
    # remove command echo from buffer
    # 
    $rbuf =~ s/^$cmd\s+//s;
    #
    # remove (next) prompt from buffer
    #
    $rbuf =~ s/$prompt$//s   if $prompt ne '';

    return $rbuf;
}
