package Class::Factory;

# $Id$

use strict;

$Class::Factory::VERSION = '0.04';

my %INCLUDE  = ();
my %REGISTER = ();

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
    my $factory_class = $INCLUDE{ $class }->{ $object_type };
    return $factory_class if ( $factory_class );

    $factory_class = $REGISTER{ $class }->{ $object_type };
    if ( $factory_class ) {
        $class->add_factory_type( $object_type, $factory_class );
        return $factory_class;
    }
    $item->factory_error( "Factory type [$object_type] is not defined ",
                          "in [$class]" );
}


# Associate $object_type with $object_class

sub add_factory_type {
    my ( $item, $object_type, $object_class ) = @_;
    my $class = ref $item || $item;
    unless ( $object_type )  {
        $item->factory_error( "Cannot add factory type to [$class]: no ",
                              "type defined");
    }
    unless ( $object_class ) {
        $item->factory_error( "Cannot add factory type [$object_type] to ",
                              "[$class]: no class defined" );
    }

    my $set_object_class = $INCLUDE{ $class }->{ $object_type };
    if ( $set_object_class ) {
        $item->factory_log( "Attempt to add type [$object_type] to [$class] ",
                            "redundant; type already exists with class ",
                            "[$set_object_class]" );
        return;
    }

    # Make sure the object class looks like a perl module/script
    # Acceptable formats:
    #   Module.pm  Module.ph  Module.pl  Module
    $object_class =~ m/^([\w:-]+(?:\.(?:pm|ph|pl))?)$/;
    $object_class = $1;

    eval "require $object_class";
    if ( $@ ) {
        $item->factory_error( "Cannot add factory type [$object_type] to ",
                              "class [$class]: factory class [$object_class] ",
                              "cannot be required [$@]" );
    }
    return $INCLUDE{ $class }->{ $object_type } = $object_class;
}

sub register_factory_type {
    my ( $item, $object_type, $object_class ) = @_;
    my $class = ref $item || $item;
    unless ( $object_type )  {
        $item->factory_error( "Cannot add factory type to [$class]: no type ",
                              "defined" );
    }
    unless ( $object_class ) {
        $item->factory_error( "Cannot add factory type [$object_type] to ",
                              "[$class]: no class defined" );
    }

    my $set_object_class = $REGISTER{ $class }->{ $object_type };
    if ( $set_object_class ) {
        $item->factory_log( "Attempt to register type [$object_type] with ",
                            "[$class] is redundant; type registered with ",
                            "class [$set_object_class]" );
        return;
    }
    return $REGISTER{ $class }->{ $object_type } = $object_class;
}


sub get_loaded_classes {
    my ( $item ) = @_;
    my $class = ref $item || $item;
    return () unless ( ref $INCLUDE{ $class } eq 'HASH' );
    return sort values %{ $INCLUDE{ $class } };
}

sub get_registered_classes {
    my ( $item ) = @_;
    my $class = ref $item || $item;
    return () unless ( ref $REGISTER{ $class } eq 'HASH' );
    return sort values %{ $REGISTER{ $class } };
}

########################################
# Overridable Log / Error

sub factory_log   { shift; warn @_, "\n" }
sub factory_error { shift; die @_, "\n" }

1;

__END__

=head1 NAME

Class::Factory - Base class for dynamic factory classes

=head1 SYNOPSIS

  package My::Factory;
  use base qw( Class::Factory );

  # Add our default types

  # This type is loaded when the statement is run

  __PACKAGE__->add_factory_type( perl => 'My::Factory::Perl' );

  # This type is loaded on the first request for type 'blech'

  __PACKAGE__->register_factory_type( blech => 'My::Factory::Blech' );

  1;

  # Adding a new factory type in code -- 'Other::Custom::Class' is
  # brought in when 'add_factory_type()' is called

  My::Factory->add_factory_type( custom => 'Other::Custom::Class' );
  my $custom_object = My::Factory->new( 'custom', { this => 'that' } );

  # Registering a new factory type in code --
  # 'Other::Custom::ClassTwo' in brought in when 'new()' is called
  # with type 'custom_two'

  My::Factory->register_factory_type( custom_two => 'Other::Custom::ClassTwo' );
  my $custom_object = My::Factory->new( 'custom_two', { this => 'that' } );

  # Get all the loaded and registered classes
  my @loaded = My::Factory->get_loaded_classes;
  my @registered = My::Factory->get_registered_classes;

=head1 DESCRIPTION

This is a simple module that factory classes can use to generate new
types of objects on the fly, providing a consistent interface to
common groups of objects.

Factory classes are used when you have different implementations for
the same set of tasks but may not know in advance what implementations
you will be using. For instance, take configuration files. There are
four basic operations you would want to do with any configuration:
read the file in, lookup a value, set a value, write the file
out. There are also many different types of configuration files, and
you may want users to be able to provide an implementation for their
own home-grown configuration format.

With a factory class this is easy. To create the factory class, just
subclass C<Class::Factory> and create an interface for your
configuration serializer. C<Class::Factory> even provides a simple
constructor for you:

 package My::ConfigFactory;

 use strict;
 use base qw( Class::Factory );

 sub read  { die "Define read() in implementation" }
 sub write { die "Define write() in implementation" }
 sub get   { die "Define get() in implementation" }
 sub set   { die "Define set() in implementation" }

 __PACKAGE__->add_factory_type( ini  => 'My::IniReader' );
 __PACKAGE__->add_factory_type( perl => 'My::PerlReader' );

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

 # Now register my type with the factory

 My::ConfigFactory->add_factory_type( 'mytype' => __PACKAGE__ );

 1;

(You may not with to make your factory the same as your interface, but
this is an abbreviated example.)

So now users can use the custom configuration with something like:

 #!/usr/bin/perl

 use strict;
 use My::ConfigFactory;

 my $config = My::ConfigFactory->new( 'custom', 'myconf.dat' );

And they can even add their own:

 My::ConfigFactory->register_factory_type( 'newtype' => 'My::New::ConfigReader' );

This might not seem like a very big win, and for small standalone
applications it is not. But when you develop large applications the
C<(add|register)_factory_type()> step will almost certainly be done at
application initialization time, hidden away from the eyes of the
application developer. That developer will only know that she can
access the different object types as if they are part of the system.

As you see in the example above, implementation for subclasses is very
simple -- just add C<Class::Factory> to your inheritance tree and you
are done.

=head2 Gotchas

All information is stored under the original subclass name. For
instance, the following will not do what you expect:

 package My::Factory;
 use base qw( Class::Factory );

 package My::Implementation;
 use base qw( My::Factory );

 My::Implementation->register_factory_type( impl => 'My::Implementation' );

This does not register 'My::Implementation' under 'My::Factory' as you
would like, it registers the type under 'My::Implementation'. Keep
everything in the original factory class name and you will be ok.

=head2 Registering Factory Types

As an additional feature, you can have your class accept registered
types that get brought in only when requested. This lazy loading
feature can be very useful when your factory offers many choices and
users will only need one or two of them at a time, or when some
classes the factory generates use libraries that some users may not
have installed.

For example, say I have a factory that generates an object which
parses GET/POST parameters. One type is straightforward L<CGI|CGI>,
one is L<Apache::Request|Apache::Request>. Many systems do not have
L<Apache::Request|Apache::Request> installed so we do not want to
'use' the module whenever we create the factory.

Instead, we will register these types with the factory and only when
that type is requested will be bring that implementation in. To extend
our example above, we will use the configuration factory:

 package My::ConfigFactory;

 use strict;
 use base qw( Class::Factory );

 sub read  { die "Define read() in implementation" }
 sub write { die "Define write() in implementation" }
 sub get   { die "Define get() in implementation" }
 sub set   { die "Define set() in implementation" }

 __PACKAGE__->register_factory_type( ini  => 'My::IniReader' );
 __PACKAGE__->register_factory_type( perl => 'My::PerlReader' );

 1;

We just changed the calls from C<add_factory_type()> to
C<register_factory_type>. This way you can leave the actual inclusion
of the module for people who would actually use it. For our
configuration example we might have:

 My::ConfigFactory->register_factory_type( SOAP => 'My::Config::SOAP' );

So the C<My::Config::SOAP> class will only get included at the first
request for a configuration object of that type:

 my $config = My::ConfigFactory->new( 'SOAP', 'http://myco.com/',
                                              { port => 8080, ... } );

=head2 Subclassing

Piece of cake:

 package My::Factory;
 use base qw( Class::Factory );

You can also override two methods for logging/error handling. There
are a few instances where C<Class::Factory> may generate a warning
message, or even a fatal error.  Internally, these are handled using
C<warn> and C<die>, respectively.

This may not always be what you want though.  Maybe you have a different
logging facility you wish to use.  Perhaps you have a more sophisticated method
of handling errors.  If this is the case, you are welcome to override either of
these methods.

Currently, these two methods are implemented like the following:

 sub factory_log   { shift; warn @_, "\n" }
 sub factory_error { shift; die @_, "\n" }

Assume that instead of using C<warn>, you wish to use
L<Log::Log4perl|Log::Log4perl>.  So, in your subclass, you might
override C<factory_log> like so:

 sub factory_log {
     shift;
     my $logger = get_logger;
     $logger->warn( @_ );
 }

=head2 Common Usage Pattern

This is a very common pattern. Subclasses create an C<init()>
method that gets called when the object is created:

 package My::Factory;

 use strict;
 use base qw( Class::Factory );

 1;

And here is what a subclass might look like:

 package My::Subclass;

 use strict;
 use base qw( Class::Accessor );
 my @CONFIG_FIELDS = qw( status created_on created_by updated_on updated_by );
 my @FIELDS = ( 'filename', @CONFIG_FIELDS );
 My::Subclass->mk_accessors( @FIELDS );

 # Note: we have taken the flattened C<@params> passed in and assigned
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

=head2 Registering Common Types by Default

Many times you will want the parent class to automatically register
the types it knows about:

 package My::Factory;

 use strict;
 use base qw( Class::Factory );

 My::Factory->register_factory_type( type1 => 'My::Impl::Type1' );
 My::Factory->register_factory_type( type2 => 'My::Impl::Type1' );

 1;

This allows the default types to be registered when the factory is
initialized. So you can use the default implementations without any
more registering/adding:

 #!/usr/bin/perl

 use strict;
 use My::Factory;

 my $impl1 = My::Factory->new( 'type1' );
 my $impl2 = My::Factory->new( 'type2' );

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
call to C<add|register_factory_type()>) with C<$type> and then call
the C<init()> method of that object. The C<init()> method should
return the object, or die on error.

B<get_factory_class( $object_type )>

Usually called from a constructor when you want to lookup a class by a
type and create a new object of C<$object_type>. If C<$object_type> is
associated with a class and that class has already been included, the
class is returned. If C<$object_type> is registered with a class (not
yet included), then we try to C<require> the class. Any errors on the
C<require> bubble up to the caller. If there are no errors, the class
is returned.

Returns: name of class. If a class matching C<$object_type> is not
found or cannot be C<require>d, then a C<die()> is thrown.

B<add_factory_type( $object_type, $object_class )>

Tells the factory to dynamically add a new type to its stable and
brings in the class implementing that type using C<require>. After
running this the factory class will be able to create new objects of
type C<$object_type>.

Returns: name of class added if successful. If the proper parameters
are not given or if we cannot find C<$object_class> in @INC, then a
C<die()> is thrown. A C<warn>ing is issued if the type has already
been added.

B<register_factory_type( $object_type, $object_class )>

Tells the factory to register a new factory type. This type will be
dynamically included (using C<add_factory_type()> at the first request
for an instance of that type.

Returns: name of class registered if successful. If the proper
parameters are not given then a C<die()> is thrown. A C<warn>ing is
issued if the type has already been registered.

B<get_loaded_classes()>

Returns a sorted list of the currently loaded classes. If no classes
have been loaded yet, returns an empty list.

B<get_registered_classes()>

Returns a sorted list of the classes that were ever registered. If no
classes have been loaded yet, returns an empty list.

Note that a class can be both registered and loaded since we do not
clear out the registration once a registered class has been loaded on
demand.

=head1 COPYRIGHT

Copyright (c) 2002 Chris Winters. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

"Design Patterns", by Erich Gamma, Richard Helm, Ralph Johnson and
John Vlissides. Addison Wesley Longman, 1995. Specifically, the
'Factory Method' pattern, pp. 107-116.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>

Eric Andreychek E<lt>eric@openthought.netE<gt> implemented overridable
log/error capability and prodded the module into a simpler design.
