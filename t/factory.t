# -*-perl-*-

use strict;
use Test::More  tests => 21;

use lib qw( ./t ./lib );

require_ok( 'Class::Factory' );

my $rock_band     = 'Slayer';
my $rock_genre    = 'ROCK';
my $country_band  = 'Plucker';
my $country_genre = 'COUNTRY';

# First do the simple setting

{
    require_ok( 'MySimpleBand' );

    # Set the ISA of our two bands to the one we're testing now

    @MyRockBand::ISA = qw( MySimpleBand );
    @MyCountryBand::ISA = qw( MySimpleBand );

    my $map = MySimpleBand->get_factory_map;
    is( ref( $map ), 'HASH', 'Return of get_factory_map()' );
    is( scalar keys %{ $map }, 2, 'Keys in map' );
    is( $map->{rock},    'MyRockBand',    'Simple type added 1' );
    is( $map->{country}, 'MyCountryBand', 'Simple type added 2' );

    my $rock = MySimpleBand->new( 'rock', { band_name => $rock_band } );
    is( ref( $rock ), 'MyRockBand', 'Simple object returned 1' );
    is( $rock->band_name(), $rock_band, 'Simple object super init parameter set 1' );
    is( $rock->genre(), $rock_genre, 'Simple object self init parameter set 1' );

    my $country = MySimpleBand->new( 'country', { band_name => $country_band } );
    is( ref( $country ), 'MyCountryBand', 'Simple object returned 2' );
    is( $country->band_name(), $country_band, 'Simple object super init parameter set 2' );
    is( $country->genre(), $country_genre, 'Simple object self init parameter set 2' );
}

# Next the flexible settting

{
    require_ok( 'MyFlexibleBand' );

    # Set the ISA of our two bands to the one we're testing now

    @MyRockBand::ISA = qw( MyFlexibleBand );
    @MyCountryBand::ISA = qw( MyFlexibleBand );

    is( MyFlexibleBand->get_factory_type( 'rock' ),    'MyRockBand',    'Flexible type added 1' );
    is( MyFlexibleBand->get_factory_type( 'country' ), 'MyCountryBand', 'Flexible type added 2' );

    my $rock = MyFlexibleBand->new( 'rock', { band_name => $rock_band } );
    is( ref( $rock ), 'MyRockBand', 'Flexible object returned 1' );
    is( $rock->band_name(), $rock_band, 'Flexible object super init parameter set 1' );
    is( $rock->genre(), $rock_genre, 'Flexible object self init parameter set 1' );

    my $country = MyFlexibleBand->new( 'country', { band_name => $country_band } );
    is( ref( $country ), 'MyCountryBand', 'Flexible object returned 2' );
    is( $country->band_name(), $country_band, 'Flexible object super init parameter set 2' );
    is( $country->genre(), $country_genre, 'Flexible object self init parameter set 2' );
}
