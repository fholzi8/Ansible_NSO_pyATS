


use strict;
use warnings;
use Net::SNMP qw(:snmp);
use Getopt::Std;



my $OID_ifTable;
my $host;
my $dot1x_oid = '1.0.8802.1.1.1.1.2.1.1.6';
my $desc_oid  = '1.3.6.1.2.1.31.1.1.1.18';
my $oper_oid  = '1.3.6.1.2.1.2.2.1.8';
my $int_oid  = '1.3.6.1.2.1.2.2.1.7';

#
#GETOPTS
#
my %options;

getopts('H:o:',\%options) || die <<USAGE;
Usage: snmpwalk_v3.pl [options] 

FAST_SNMPWALK_VERSION 3 in company Network

Options:
	-H			host
	-o			oid oder smart-oid
USAGE
    ;

if (defined($options{'H'})){
	$host = $options{'H'};
} else {
	print "No Host defined!\n";
	exit 1;
}
if (defined($options{'o'})){
	my $tmp_oid = $options{'o'};
	if ( $tmp_oid =~ /dot1x\.(.*)/ ){
		$OID_ifTable = "$dot1x_oid";
	} elsif ( $tmp_oid =~ /desc\.(.*)/ ){
		$OID_ifTable = "$desc_oid";
	}  elsif ( $tmp_oid =~ /oper\.(.*)/ ){
		$OID_ifTable = "$oper_oid";
	} elsif ( $tmp_oid =~ /int\.(.*)/ ){
		$OID_ifTable = "$int_oid";
	} else {
		$OID_ifTable = $tmp_oid;
	}
} else {
	print "No OID defined!\n";
	exit 1;
}
my ($session, $error) = Net::SNMP->session(
		 -hostname => $host,
	   -authprotocol =>  'md5',
	   -authpassword =>  'SNMP_Passwd!',
	   -username     =>  'SNMPUser',
	   -nonblocking  => 	1,
	   -version      =>  '3',
	   -privprotocol =>  'des',
	   -privpassword =>  'SNMP_Secret'
);

if (!defined $session) {
   printf "ERROR: %s.\n", $error;
   exit 1;
}

my %table; # Hash to store the results

my $result = $session->get_bulk_request(
   -varbindlist    => [ $OID_ifTable ],
   -callback       => [ \&table_callback, \%table ],
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

# Print the results, specifically formatting ifPhysAddress.

for my $oid (oid_lex_sort(keys %table)) {
	 my $new_oid = $oid;
   $new_oid =~ s/.*\.(\d+)/$1/g;   
   printf "%s => %s\n", $new_oid, $table{$oid};
}

exit 0;

sub table_callback
{
   my ($session, $table) = @_;

   my $list = $session->var_bind_list();

   if (!defined $list) {
      printf "ERROR: %s\n", $session->error();
      return;
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
      $table->{$next} = $list->{$next};
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