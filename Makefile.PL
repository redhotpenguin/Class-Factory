use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Class::Factory',
    'VERSION_FROM'	=> 'Factory.pm', # finds $VERSION
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'Factory.pm',
       AUTHOR     => 'Chris Winters <chris@cwinters.com') : ()),
);
