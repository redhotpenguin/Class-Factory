package Class::Factory;

# $Id$

use strict;

$Class::Factory::VERSION = '0.02';

# Simple constructor -- override as needed

sub new {
    my ( $pkg, $type, @params ) = @_;
    my $class = $pkg->get_factory_class( $type );
    my $self = bless( {}, $class );
    return $self->init( @params );
}


# Subclasses should override, but if they don't they shouldn't be
# penalized...

sub init { return $_[0] }

# Find the class associated with $object_type

sub get_factory_class {
    my ( $item, $object_type ) = @_;
    my $class = ref $item || $item;
    my $map = $item->get_factory_map;
    my $factory_class = ( ref $map eq 'HASH' )
                          ? $map->{ $object_type }
                          : $item->get_factory_type( $object_type );
    unless ( $factory_class ) {
        die "Factory type [$object_type] is not defined in [$class]\n";
    }
    return $factory_class;
}


# Associate $object_type with $object_class

sub add_factory_type {
    my ( $item, $object_type, $object_class ) = @_;
    my $class = ref $item || $item;
    unless ( $object_type )  {
        die "Cannot add factory type to [$class]: no type defined\n";
    }
    unless ( $object_class ) {
        die "Cannot add factory type [$object_type] to [$class]: no class defined\n";
    }

    my $map = $item->get_factory_map;
    my $set_object_class = ( ref $map eq 'HASH' )
                              ? $map->{ $object_type }
                              : $item->get_factory_type( $object_type );
    if ( $set_object_class ) {
        warn "Attempt to add type [$object_type] to [$class] redundant; ",
             "type already exists with class [$set_object_class]\n";
        return;
    }

    eval "require $object_class";
    if ( $@ ) {
        die "Cannot add factory type [$object_type] to class [$class]: ",
            "factory class [$object_class] cannot be required [$@]\n";
    }

    if ( ref $map eq 'HASH' ) {
        $map->{ $object_type } = $object_class;
    }
    else {
        $item->set_factory_type( $object_type, $object_class );
    }
    return $object_class;
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

=pod

=head1 NAME

Class::Factory - Base class for dynamic factory classes

=head1 SYNOPSIS

  package My::Factory;

  use base qw( Class::Factory );

  my %TYPES = ();

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

  My::Factory->add_factory_type( perl  => 'My::Factory::Perl' );
  My::Factory->add_factory_type( blech => 'My::Factory::Blech' );

  1;

  # Adding a new factory type in code

  My::Factory->add_factory_type( custom => 'Other::Custom::Class' );
  my $custom_object = My::Factory->new( 'custom', { this => 'that' } );

=head1 DESCRIPTION

This is a simple module that factory classes can use to generate new
types of objects on the fly, providing a consistent interface to
common groups of objects.

Factory classes are used when you have different implementations for
the same set of tasks but may not know in advance what implementations
you will be using. For instance, take configuration files. There are
four basic operations you would want to do with any configuration
file: read it in, lookup a value, set a value, write it out. There are
also many different types of configuration files, and you may want
users to be able to provide an implementation for their own home-grown
configuration format.

With a factory class this is easy. To create the factory class, just
subclass C<Class::Factory> and create an interface for your
configuration serializer. C<Class::Factory> even provides a simple
constructor for you:

 package My::ConfigFactory;

 use strict;
 use base qw( Class::Factory );

 my %TYPES = ();
 sub get_factory_map { return \%TYPES }

 sub read  { die "Define read() in implementation" }
 sub write { die "Define write() in implementation" }
 sub get   { die "Define get() in implementation" }
 sub set   { die "Define set() in implementation" }

 1;

And then users can add their own subclasses:

 package My::CustomConfig;

 use strict;
 use base qw( My::ConfigFactory );

 sub init {
     my ( $self, $filename, $params ) = @_;
     if ( $params->{base_url} ) {
         $self->read_from_web( join( '/', $params->{base_url}, $filename ) );
     }
     else {
         $self->read( $filename );
     }
     return $self;
 }

 sub read  { ... implementation to read a file ... }
 sub write { ... implementation to write a file ...  }
 sub get   { ... implementation to get a value ... }
 sub set   { ... implementation to set a value ... }

 sub read_from_web { ... implementation to read via http ... }

 1;

(Normally you probably would not make your factory the same as your
interface, but this is an abbreviated example.)

So now users can use the custom configuration with something like:

 #!/usr/bin/perl

 use strict;
 use My::ConfigFactory;

 My::ConfigFactory->add_factory_type( 'custom' => 'My::CustomConfig' );

 my $config = My::ConfigFactory->new( 'custom', 'myconf.dat' );

This might not seem like a very big win, and for small standalone
applications it is not. But when you develop large applications the
C<add_factory_type()> step will almost certainly be done at
application initialization time, hidden away from the eyes of the
application developer. That developer will only know that she can
access the different object types as if they are part of the system.

As you see in the example above, implementation for subclasses is very
simple. The base class defines two methods for subclasses to use:
C<get_factory_class()> and C<add_factory_type()>. Subclasses must
define either C<get_factory_map()> or both C<get_factory_type()> and
C<set_factory_type()>.

=head1 METHODS

B<new( $type, @params )>

This is a default constructor you can use. It is quite simple:

 sub new {
     my ( $pkg, $type, @params ) = @_;
     my $class = $pkg->get_factory_class( $type );
     my $self = bless( {}, $class );
     return $self->init( @params );
 }

We just create a new object of the class associated (from an earlier
call to C<add_factory_type()>) with C<$type> and then call the
C<init()> method of that object. The C<init()> method should return
the object, or die on error.

B<get_factory_class( $object_type )>

Usually called from a constructor when you want to lookup a class by a
type and create a new object of C<$object_type>.

Returns: name of class. If a class matching C<$object_type> is not
found, then a C<die()> is thrown.

B<add_factory_type( $object_type, $object_class )>

Tells the factory to dynamically add a new type to its stable and
brings in the class implementing that type using C<require()>. After
running this the factory class will be able to create new objects of
type C<$object_type>.

Returns: name of class added if successful. If the proper parameters
are not given or if we cannot find C<$object_class> in @INC, then a
C<die()> is thrown.

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
     my ( $class, $type, $object_class ) = @_;
     return $TYPES{ $type } = $object_class;
 }

How these methods work is entirely up to you -- maybe
C<get_factory_class()> does a lookup in some external resource before
returning the class. Whatever floats your boat.

=head1 USAGE

=head2 Common Pattern

This is a very common pattern. Subclasses create an C<init()>
method that gets called when the object is created:

 package My::Factory;

 use strict;
 use base qw( Class::Factory );

 my %TYPES = ();
 sub get_factory_map { return \%TYPES }

 1;

And here is what a subclass might look like:

 package My::Subclass;

 use strict;
 use base qw( Class::Accessor );
 my @CONFIG_FIELDS = qw( status created_on created_by updated_on updated_by );
 my @FIELDS = ( 'filename', @CONFIG_FIELDS );
 My::Subclass->mk_accessors( @FIELDS );

 # Note: we've taken the flattened C<@params> passed in and assigned
 # the first element as C<$filename> and the other element as a
 # hashref C<$params>

 sub init {
     my ( $self, $filename, $params ) = @_;
     unless ( -f $filename ) {
         die "Filename [$filename] does not exist. Object cannot be created";
     }
     $self->filename( filename );
     $self->read_file_contents;
     foreach my $field ( @CONFIG_FIELDS ) {
         $self->{ $field } = $params->{ $field } if ( $params->{ $field } );
     }
     return $self;
 }

The parent class (C<My::Factory>) has made as part of its definition
that the only parameters to be passed to the C<init()> method are
C<$filename> and C<$params>, in that order. It could just as easily
have specified a single hashref parameter.

These sorts of specifications are informal and not enforced by this
C<Class::Factory>.

=head1 COPYRIGHT

Copyright (c) 2002 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

"Design Patterns", by Erich Gamma, Richard Helm, Ralph Johnson and
John Vlissides. Addison Wesley Longman, 1995. Specifically, the
'Factory Method' pattern, pp. 107-116.

=head1 AUTHOR

Chris Winters <chris@cwinters.com>

=cut
