package MyRockBand;

use strict;

# Note: @ISA is modified during the test

sub initialize {
    my ( $self, $params ) = @_;
    $self->SUPER::initialize( $params );
    $self->genre( 'ROCK' );
    return $self;
}

1;
