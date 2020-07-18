


use strict;
use warnings;
use Net::SNMP qw(:snmp);
use Getopt::Std;



my $host;
my $net;
my $route_oid = '1.3.6.1.2.1.4.24.4.1.4';
my $subnet_oid = '255.255.255.0';
my $default_oid = '1.3.6.1.2.1.4.24.4.1.4.0.0.0.0.0.0.0.0';

#
#GETOPTS
#
my %options;

getopts('H:',\%options) || die <<USAGE;
Usage: routecheck.pl [options]

FAST_SNMPWALK_VERSION 3 in company Network

Options:
        -H                      host
USAGE
    ;

if (defined($options{'H'})){
        $host = $options{'H'};
} else {
        print "No Host defined!\n";
        exit 1;
}

$net = substr($host,0,-3);
$net .= '0';

#
#Abfrage Branch-Router
#
my ($session, $error) = Net::SNMP->session(
           -hostname => $host,
           -authprotocol =>  'md5',
           -authpassword =>  'SNMP_Passwd!',
           -username     =>  'SNMPUser',
           -nonblocking  =>     1,
           -version      =>  '3',
           -privprotocol =>  'des',
           -privpassword =>  'SNMP_Secret'
);

if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 0;
}

my %table_branch; # Hash to store the results
my $OID_ifTable = $default_oid;
my $result = $session->get_bulk_request(
   -varbindlist    => [ $OID_ifTable ],
   -callback       => [ \&table_callback, \%table_branch ],
   -maxrepetitions => 10,
);

if (!defined $result) {
   printf "ERROR: %s\n", $session->error();
   $session->close();
   exit 1;
}

# Now initiate the SNMP message exchange.
snmp_dispatcher();

$session->close();

#
#Ende der Abfrage des Branch-Routers
#

#
#Abfrage DEMUC-CORE (HQ-Router)
#
my ($ses, $err) = Net::SNMP->session(
           -hostname => '10.12.2.1',
           -authprotocol =>  'md5',
           -authpassword =>  'SNMP_Passwd!',
           -username     =>  'SNMPUser',
           -nonblocking  =>     1,
           -version      =>  '3',
           -privprotocol =>  'des',
           -privpassword =>  'SNMP_Secret'
);

if (!defined $ses) {
   printf "ERROR: %s.\n", $err;
   exit 0;
}

my %table_hq; # Hash to store the results
my $OID_ifTab = "$route_oid.$net.$subnet_oid";
my $res = $ses->get_bulk_request(
   -varbindlist    => [ $OID_ifTab ],
   -callback       => [ \&tab_callback, \%table_hq ],
   -maxrepetitions => 10,
);

if (!defined $res) {
   printf "ERROR: %s\n", $ses->error();
   $ses->close();
   exit 1;
}

# Now initiate the SNMP message exchange.
snmp_dispatcher();

$ses->close();

#
#Ende der Abfrage HQ-Routers
#

my $hq_key = (sort (keys %table_hq))[0];
my $hq_value = $table_hq{$hq_key};
my $branch_key  = (sort (keys %table_branch))[0];
my $branch_value = $table_branch{$branch_key};
my $hq_route;
my $branch_route;
if ($hq_value eq '10.12.2.254'){
	$hq_route = 'DC1';
} else {
	$hq_route = 'DC2';
}
if ($branch_value =~ /10\.14\..*/){
	$branch_route = 'DC1';
} elsif ($branch_value =~ /10\.15\..*/){
	$branch_route = 'DC2';
} elsif ($branch_value =~ /10\.64\.0\.3.*/){
	$branch_route = 'DC1';
} else {
	$branch_route = 'Neighbor';
}

#
#Ausgabe
#
if ($hq_route eq $branch_route){
	printf "OK - SNMP Result: Route to and back %s\n", $hq_route;
} else {
	printf "WARNING - SNMP Result: Branch-Route: %s and DC-Route: %s\n", $branch_route, $hq_route;	
}

exit 0;


#
#SUBROUTINEN
#
sub table_callback
{
   my ($session, $table_branch) = @_;

   my $list = $session->var_bind_list();

   if (!defined $list) {
      printf "ERROR: %s\n", $session->error();
      exit 1;
   }

   # Loop through each of the OIDs in the response and assign
   # the key/value pairs to the reference that was passed with
   # the callback.  Make sure that we are still in the table
   # before assigning the key/values.

   my @names = $session->var_bind_names();
   my $next  = undef;

   while (@names) {
      $next = shift @names;
      if (!oid_base_match($OID_ifTable, $next)) {
         return; # Table is done.
      }
      $table_branch->{$next} = $list->{$next};
   }

   # Table is not done, send another request, starting at the last
   # OBJECT IDENTIFIER in the response.  No need to include the
   # calback argument, the same callback that was specified for the
   # original request will be used.

   my $result = $session->get_bulk_request(
      -varbindlist    => [ $next ],
      -maxrepetitions => 10,
   );
   if (!defined $result) {
      printf "ERROR: %s.\n", $session->error();
   }

   return;
}
sub tab_callback
{
   my ($ses, $table_hq) = @_;

   my $list = $ses->var_bind_list();

   if (!defined $list) {
      printf "ERROR: %s\n", $ses->error();
      exit 1;
   }

   # Loop through each of the OIDs in the response and assign
   # the key/value pairs to the reference that was passed with
   # the callback.  Make sure that we are still in the table
   # before assigning the key/values.

   my @names = $ses->var_bind_names();
   my $next  = undef;

   while (@names) {
      $next = shift @names;
      if (!oid_base_match($OID_ifTab, $next)) {
         return; # Table is done.
      }
      $table_hq->{$next} = $list->{$next};
   }

   # Table is not done, send another request, starting at the last
   # OBJECT IDENTIFIER in the response.  No need to include the
   # calback argument, the same callback that was specified for the
   # original request will be used.

   my $rest = $ses->get_bulk_request(
      -varbindlist    => [ $next ],
      -maxrepetitions => 10,
   );
   if (!defined $res) {
      printf "ERROR: %s.\n", $ses->error();
   }

   return;
}
