# -*-perl-*-

use strict;
use Test::More  tests => 23;

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

    my $factory_map = MySimpleBand->get_factory_map;
    is( ref( $factory_map ), 'HASH', 'Return of get_factory_map()' );
    is( scalar keys %{ $factory_map }, 1, 'Keys in factory map' );
    is( $factory_map->{rock},    'MyRockBand',    'Simple type added' );

    my $register_map = MySimpleBand->get_register_map;
    is( ref( $register_map ), 'HASH', 'Return of get_register_map()' );
    is( scalar keys %{ $register_map }, 1, 'Keys in register map' );
    is( $register_map->{country}, 'MyCountryBand', 'Simple type registered' );

    my $rock = MySimpleBand->new( 'rock', { band_name => $rock_band } );
    is( ref( $rock ), 'MyRockBand', 'Simple added object returned' );
    is( $rock->band_name(), $rock_band, 'Simple added super init parameter set' );
    is( $rock->genre(), $rock_genre, 'Simple added self init parameter set' );

    my $country = MySimpleBand->new( 'country', { band_name => $country_band } );
    is( ref( $country ), 'MyCountryBand', 'Simple registered object returned' );
    is( $country->band_name(), $country_band, 'Simple registered object super init parameter set' );
    is( $country->genre(), $country_genre, 'Simple registered object self init parameter set' );
}

# Next the flexible settting

{
    require_ok( 'MyFlexibleBand' );

    # Set the ISA of our two bands to the one we're testing now

    @MyRockBand::ISA = qw( MyFlexibleBand );
    @MyCountryBand::ISA = qw( MyFlexibleBand );

    is( MyFlexibleBand->get_factory_type( 'rock' ),    'MyRockBand',    'Flexible type added' );
    is( MyFlexibleBand->get_register_type( 'country' ), 'MyCountryBand', 'Flexible type registered' );

    my $rock = MyFlexibleBand->new( 'rock', { band_name => $rock_band } );
    is( ref( $rock ), 'MyRockBand', 'Flexible added object returned' );
    is( $rock->band_name(), $rock_band, 'Flexible added object super init parameter set' );
    is( $rock->genre(), $rock_genre, 'Flexible added object self init parameter set' );

    my $country = MyFlexibleBand->new( 'country', { band_name => $country_band } );
    is( ref( $country ), 'MyCountryBand', 'Flexible registered object returned' );
    is( $country->band_name(), $country_band, 'Flexible registered object super init parameter set' );
    is( $country->genre(), $country_genre, 'Flexible registered object self init parameter set' );
}
