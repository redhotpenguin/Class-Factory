package MySimpleBand;

# $Id$

use strict;
use base qw( Class::Factory );

sub init {
    my ( $self, $params ) = @_;
    $self->band_name( $params->{band_name} );
    return $self;
}


sub band_name {
    my ( $self, $name ) = @_;
    $self->{band_name} = $name if ( $name );
    return $self->{band_name};
}

sub genre {
    my ( $self, $genre ) = @_;
    $self->{genre} = $genre if ( $genre );
    return $self->{genre};
}

__PACKAGE__->add_factory_type( rock => 'MyRockBand' );
__PACKAGE__->register_factory_type( country => 'MyCountryBand' );

1;

