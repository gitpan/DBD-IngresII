use DBI qw(:sql_types);

use utf8;

use Test::Harness qw($verbose);

my $num_test = 1;
my $t = 1;

$verbose = $Test::Harness::verbose || 1;

sub ok ($$) {
    my ($ok, $expl) = @_;
    print "Testing $expl\n" if $verbose;
    ($ok) ? print "ok $t\n" : print "not ok $t\n";
    if (!$ok && $warn) {
	$warn = $DBI::errstr if $warn eq '1';
	$warn = "" unless $warn;
	warn "$expl $warn\n";
    }
    ++$t;
    $ok;
}

sub get_dbname {
    # find the name of a database on which test are to be performed
    # Should ask the user if it can't find a name.
    $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    unless ($dbname) {
        print "1..0 # SKIP DBI_DBNAME and DBI_DSN aren't present\n";
        exit 0;
    }
    $dbname = "dbi:IngresII:$dbname" unless $dbname =~ /^dbi:IngresII/;
    $dbname;
}

sub connect_db ($) {
    # Connects to the database.
    # If this fails everything else is in vain!
    my ($dbname) = @_;
    $ENV{II_DATE_FORMAT}="SWEDEN";       # yyyy-mm-dd

    my $dbh = DBI->connect($dbname, "", "",
		    { AutoCommit => 0, RaiseError => 0, PrintError => 1, ShowErrorStatement=>1 })
	or return undef;
    $dbh->{ChopBlanks} = 0;

    $dbh;
}

my $dbname = get_dbname;

print "1..$num_test\n";

my $dbh = connect_db($dbname);

ok(($dbh->ing_utf8_quote(q{ąść'}) eq q{U&'\+000105\+00015b\+000107'''}), "Testing UTF-8 quoting");

exit(0);
