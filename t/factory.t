# -*-perl-*-

use strict;
use Test::More  tests => 17;

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

    @MyRockBand::ISA    = qw( MySimpleBand );
    @MyCountryBand::ISA = qw( MySimpleBand );

    my @loaded = MySimpleBand->get_loaded_classes;
    is( scalar @loaded, 1, 'Number of classes loaded so far' );
    is( $loaded[0], 'MyRockBand', 'Default class added' );

    my @registered = MySimpleBand->get_registered_classes;
    is( scalar @registered, 1, 'Number of classes registered so far' );
    is( $registered[0], 'MyCountryBand', 'Default class registered' );

    my $rock = MySimpleBand->new( 'rock', { band_name => $rock_band } );
    is( ref( $rock ), 'MyRockBand', 'Type of added object returned' );
    is( $rock->band_name(), $rock_band,
        'Added object type super init parameter set' );
    is( $rock->genre(), $rock_genre,
        'Added object type self init parameter set' );

    my $country = MySimpleBand->new( 'country', { band_name => $country_band } );
    is( ref( $country ), 'MyCountryBand', 'Type of registered object returned' );
    is( $country->band_name(), $country_band,
        'Registered object type super init parameter set' );
    is( $country->genre(), $country_genre,
        'Registered object type self init parameter set' );

    my @loaded_new = MySimpleBand->get_loaded_classes;
    is( scalar @loaded_new, 2, 'Classes loaded after all used' );
    is( $loaded_new[0], 'MyCountryBand', 'Default registered class now loaded' );
    is( $loaded_new[1], 'MyRockBand', 'Default added class still loaded' );

    is( MySimpleBand->get_factory_class( 'country' ), 'MyCountryBand',
        'Proper class returned for registered type' );
    is( MySimpleBand->get_factory_class( 'rock' ), 'MyRockBand',
        'Proper class returned for added type' );

}
