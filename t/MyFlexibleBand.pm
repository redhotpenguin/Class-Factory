package MyFlexibleBand;

# $Id$

use strict;
use base qw( Class::Factory );

my %TYPES = ();
sub get_factory_type { return $TYPES{ $_[1] } }
sub set_factory_type { return $TYPES{ $_[1] } = $_[2] }

sub new {
    my ( $class, $type, $params ) = @_;
    my $factory_class = $class->get_factory_class( $type );
    my $self = bless( {}, $factory_class );
    return $self->initialize( $params );
}


sub initialize {
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

MyFlexibleBand->add_factory_type( rock    => 'MyRockBand' );
MyFlexibleBand->add_factory_type( country => 'MyCountryBand' );

1;

