package MySimpleBand;

# $Id$

use strict;
use base qw( Class::Factory );

#use Class::Factory;
#@MySimpleBand::ISA = qw( Class::Factory );

my %TYPES = ();
sub get_factory_map { return \%TYPES }

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

MySimpleBand->add_factory_type( rock    => 'MyRockBand' );
MySimpleBand->add_factory_type( country => 'MyCountryBand' );

1;

