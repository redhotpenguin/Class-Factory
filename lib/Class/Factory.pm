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

    my $map = $item->get_factory_map;
    my $set_factory_class = ( ref $map eq 'HASH' )
                              ? $map->{ $factory_type }
                              : $item->get_factory_type( $factory_type );
    if ( $set_factory_class ) {
        warn "Attempt to add type [$factory_type] to [$class] redundant; ",
             "type already exists with class [$set_factory_class]\n";
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
types of objects on the fly, providing a consistent interface to
common groups of objects.

Implementation for subclasses is very simple. The base class defines
two methods for subclasses to use: C<get_factory_class()> and
C<add_factory_type()>. Subclasses must define either
C<get_factory_map()> or both C<get_factory_type()> and
C<set_factory_type()>.

=head1 METHODS

B<get_factory_class( $factory_type )>

B<add_factory_type( $factory_type, $factory_class )>

=head1 SUBCLASSING

You can do this either the simple way or the flexible way. For most
cases, the simple way will suffice:

 package My::Factory;

 use base qw( Class::Factory );

 my %TYPES = ();
 sub get_factory_map { return \%TYPES }

If you elect to use the flexible way, you need to implement two
methods:

 package My::Factory;

 use base qw( Class::Factory );

 my %TYPES = ();
 sub get_factory_class {
     my ( $class, $type ) = @_;
     return $TYPES{ $type };
 }

 sub set_factory_class {
     my ( $class, $type, $factory_class ) = @_;
     return $TYPES{ $type } = $factory_class;
 }

How these methods work is entirely up to you -- maybe
C<get_factory_class()> does a lookup in some external resource before
returning the class. Whatever floats your boat.

=head1 USAGE

=head2 Common Pattern

This is a very common pattern. Subclasses create an C<initialize()>
method that gets called when the object is created:

 package My::Factory;

 use base qw( Class::Factory );

 my %TYPES = ();
 sub get_factory_map { return \%TYPES }

 sub new {
     my ( $class, $type, @params ) = @_;
     my $factory_class = $class->get_factory_class( $type );
     my $self = bless( {}, $factory_class );
     return $self->initialize( @params );
 }

 1;

And here is what a subclass might look like:

 package My::Subclass;

 use base qw( Class::Accessor );
 my @FIELDS = qw( filename status );
 My::Subclass->mk_accessors( @FIELDS );

 # Note: we've taken the flattened C<@params> passed in and assigned
 # the first element as C<$filename> and the other element as a
 # hashref C<$params>

 sub initialize {
     my ( $self, $filename, $params ) = @_;
     unless ( -f $filename ) {
         die "Filename [$filename] does not exist. Object cannot be created";
     }
     foreach my $field ( @FIELDS ) {
         $self->{ $field } = $params->{ $field } if ( $params->{ $field } );
     }
     return $self;
 }

=head1 COPYRIGHT

Copyright (c) 2002 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<perl>.

=head1 AUTHOR

Chris Winters <chris@cwinters.com>

=cut
