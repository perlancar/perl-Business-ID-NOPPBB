package Business::ID::NOPPBB;

use 5.010;
use warnings;
use strict;

use Locale::ID::Province qw(list_id_provinces);

require Exporter;
our @ISA    = qw(Exporter);
our @EXPORT = qw(validate_nop_pbb);

our %SPEC;

# VERSION

$SPEC{validate_nop_pbb} = {
    summary => 'Validate (and parse) Indonesian property tax number (NOP PBB)',
    description => <<'_',

Indonesian property tax object number, or Nomor Objek Pajak Pajak Bumi dan
Bangunan, is a number given to a tax object (house, mostly).

NOP PBB is composed of 18 digits as follow:

 AA.BB.CCC.DDD.EEE-XXXX.Y

AA is the province code from BPS. BB is locality (city/regency a.k.a
kota/kabupaten) code from BPS. CCC is district (kecamatan) code from BPS. DDD is
village (desa/kelurahan) code from BPS. EEE is block code. XXXX is the object
number. Y is a special code (it is most likely not a check digit, since it is
almost always has the value of 0).

The function will return status 200 if syntax is valid and return the parsed
number. Otherwise it will return 400.

Currently the length and AA code is checked against valid province code. There
is currently no way to check whether a specific NOP PBB actually exists, because
you would need to query Dirjen Pajak's database for that.

_
    args => {
        str => ['str*' => {
            summary => 'The input string containing number to check',
            arg_pos => 0,
        }],
    },
};

sub validate_nop_pbb {
    my (%args) = @_;

    my $str = $args{str} or return [400, "Please specify str"];

    # cache provinces
    state $prov_codes;
    if (!$prov_codes) {
        my $res = list_id_provinces(fields=>'bps_code', show_field_names=>0);
        $res->[0] == 200 or die "Can't retrieve list of provinces: ".
            "$res->[0] - $res->[1]";
        $prov_codes = {};
        $prov_codes->{$_->[0]}++ for @{$res->[2]};
    }

    $str =~ s/\D+//g;
    length($str) == 18 or return [400, "Length must be 18 digits"];
    my ($aa, $bb, $ccc, $ddd, $eee, $xxxx, $y) =
        $str =~ /(.{2})(.{2})(.{3})(.{3})(.{4})(.{1})/;
    $prov_codes->{$aa} or return [400, "Unknown province code"];

    [200, "OK", {
        province => $aa,
        locality => $bb,
        district => $ccc,
        village => $ddd,
        block => $eee,
        object => $xxxx,
        special => $y,
    }];
}

1;
# ABSTRACT: Validate Indonesian property tax object number (NOP PBB)

=head1 SYNOPSIS

 use Business::ID::NOPPBB qw(validate_nop_pbb);

 my $res = validate_nop_pbb('327311000109900990');
 $res->[0] == 200 or die "Invalid NOP PBB!";

 # get structure
 use Data::Dumper;
 print Dumper $res->[2];

 # will print something like
 {
     province => 32,
     locality => 73,
     district => 110,
     village  => '001',
     block    => '099',
     object   => '0099',
     special  => 0,
     canonical => '32.73.110.001.099-0099.0',
 }


=head1 DESCRIPTION

This module provides one function: B<validate_nop_pbb>.

This module's functions have L<Sub::Spec> specs.


=head1 FUNCTIONS

None exported by default but they are exportable.

=cut
