package Class::Factory;

# $Id$

use strict;

$Class::Factory::VERSION = '0.01';

sub get_factory_class {
    my ( $item, $factory_type ) = @_;
    my $class = ref $item || $item;
    my $map = $item->get_factory_map;
    my $factory_class = ( ref $map eq 'HASH' )
                          ? $map->{ $factory_type }
                          : $item->get_factory_type( $factory_type );
    unless ( $factory_class ) {
        die "Factory type [$factory_type] is not defined in [$class]\n";
    }
    return $factory_class;
}


sub add_factory_type {
    my ( $item, $factory_type, $factory_class ) = @_;
    my $class = ref $item || $item;
    unless ( $factory_type )  {
        die "Cannot add factory type to [$class]: no type defined\n";
    }
    unless ( $factory_class ) {
        die "Cannot add factory type [$factory_type] to [$class]: no class defined\n";
    }

    my $factory_class = $item->get_factory_type( $factory_type );
    if ( $factory_class ) {
        warn "Attempt to add type [$factory_type] to [$class] redundant; ",
             "type already exists with class [$class]\n";
        return;
    }

    eval "require $factory_class";
    if ( $@ ) {
        die "Cannot add factory type [$factory_type] to class [$class]: ",
            "factory class [$factory_class] cannot be required [$@]\n";
    }
    my $map = $item->get_factory_map;
    if ( ref $map eq 'HASH' ) {
        $map->{ $factory_type } = $factory_class;
    }
    else {
        $item->set_factory_type( $factory_type, $factory_class );
    }
    return $factory_class;
}


########################################
# INTERFACE

# We don't die when these are called because the subclass can define
# either A + B or C

sub get_factory_type { return undef }
sub set_factory_type { return undef }
sub get_factory_map  { return undef }

1;

__END__


=head1 NAME

Class::Factory - Base class for factory classes

=head1 SYNOPSIS

  package My::Factory;

  use base qw( Class::Factory );

  my %TYPES = ();

  sub new {
      my ( $class, $type, $params ) = @_;
      my $factory_class = $class->get_factory_class( $type );
      return bless( $params, $factory_class );
  }

  # SIMPLE: Let the parent know about our types

  sub get_factory_map { return \%TYPES }

  # FLEXIBLE: Let the parent know about our types

  sub get_factory_type {
      my ( $class, $type ) = @_;
      return $TYPES{ $type };
  }

  sub set_factory_type {
      my ( $class, $type, $factory_class ) = @_;
      $TYPES{ $type } = $factory_class;
  }

  # Add our default types

  My::Factory->add_factory_type( perl => 'My::Factory::Perl' );
  My::Factory->add_factory_type( blech => 'My::Factory::Blech' );

  1;

  # Adding a new factory type in code

  My::Factory->add_factory_type( custom => 'Other::Custom::Class' );
  my $custom_object = My::Factory->new( 'custom', { this => 'that' } );

=head1 DESCRIPTION

This is a simple module that factory classes can use to generate new
types of objects on the fly. The base class defines two methods for
subclasses to use: C<get_factory_class()> and
C<add_factory_type()>. Subclasses must define either
C<get_factory_map()> or both C<get_factory_type()> and
C<set_factory_type()>.

=head1 METHODS

B<get_factory_class( $factory_type )>

B<add_factory_type( $factory_type, $factory_class )>

=head1 COPYRIGHT

Copyright (c) 2002 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=head1 AUTHOR

Chris Winters <chris@cwinters.com>

=cut
