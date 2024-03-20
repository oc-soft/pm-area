use strict;
use Parse::Yapp;
use File::Basename;
use File::Spec;

my $target = $ARGV[0];

if ($target) {
    my ($name, $dirs, $suffix) = fileparse($target, qr/\.(pm|pl)/);

    # $dirs have '/' at end of line.
    # $dirs = 'abc/efg/'
    my @dirs = File::Spec->splitdir($dirs);
    # $dirs[0] == 'abc', $dirs[1] == 'efg', dirs[2] == ''
    pop @dirs;
    # $dirs[0] == 'abc', $dirs[1] == 'efg'
 
    my $gen_input = File::Spec->catfile(@dirs,  $name . '.yp');
    if (-f $gen_input) {
        my $yapp = Parse::Yapp->new(inputfile => $gen_input);
        my $warnings = $yapp->Warnings;
        if ($warnings) {
            print STDERR "Warnings:\n$warnings\n";
        }
        my $conflicts = $yapp->Conflicts;
        if ($conflicts) {
            print STDERR "Conflicts:\n$conflicts\n";
        }
        my $summary = File::Spec->catfile(@dirs,  $name . '.txt');

        my @pkg_dir = splice @dirs, 2;
        my $package_name = join '::', (@pkg_dir, $name); 

        open (OUT, ">$target") or die "can not open $target";

        print OUT $yapp->Output(classname => $package_name); 
        
        close OUT;
        open (OUT, ">$summary") or die "can not open $summary";
        print OUT "Rules:\n-------\n";
        print OUT $yapp->ShowRules() . "\n";
        print OUT "State:\n-------\n";
        print OUT $yapp->ShowDfa() . "\n";
        print OUT "Summary:\n-------\n";
        print OUT $yapp->Summary() . "\n";
        close OUT;
    } 
}

0;

# vi: se ts=4 sw=4 et:
