use ExtUtils::MakeMaker;

my %opts = (
    'NAME'         => 'Class::Factory',
    'VERSION_FROM' => 'lib/Class/Factory.pm',
    'PREREQ_PM'    => { 'Test::More' => 0.40, }
);

if ( $ExtUtils::MakeMaker::VERSION >= 5.43 ) {
    $opts{AUTHOR}   = 'Chris Winters <chris@cwinters.com';
    $opts{ABSTRACT} = 'Useful base class for factory classes',
}

WriteMakefile( %opts );
