package MyCountryBand;

use strict;

# Note: @ISA is modified during the test

sub initialize {
    my ( $self, $params ) = @_;
    $self->SUPER::initialize( $params );
    $self->genre( 'COUNTRY' );
    return $self;
}

1;
