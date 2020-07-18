use strict;
use Net::NBName;
use Net::Netmask;

my $mask = shift or die "expected: <subnet>\n";

my $nb = Net::NBName->new;
my $subnet = Net::Netmask->new2($mask);
for my $ip ($subnet->enumerate) {
    print "$ip ";
    my $ns = $nb->node_status($ip);
    my ($domain,$user,$machine) = ('','','');
	my ( $host, $name, $suffix, $flags ) = ('','','','');
	$nb->name_query( $host, $name, $suffix, $flags );
	if ($ns) {
        for my $rr ($ns->names) {
            if ($rr->suffix == 0 && $rr->G eq "GROUP") {
                $domain = $rr->name;
            }
            if ($rr->suffix == 3 && $rr->G eq "UNIQUE") {
                $user = $rr->name;
            }
            if ($rr->suffix == 0 && $rr->G eq "UNIQUE") {
                $machine = $rr->name unless $rr->name =~ /^IS~/;
            }
        }
        my $mac_address = $ns->mac_address;
        print "$mac_address $domain\\$machine $user   - $host # $name ## $suffix ### $flags";
    }
    print "\n";
 }