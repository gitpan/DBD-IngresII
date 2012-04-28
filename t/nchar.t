#
# Test various functions for each data type supported.
#

use DBI qw(:sql_types);
use Test::Harness qw($verbose);
use Encode;

use utf8;

require DBD::IngresII;

my $num_test = 23;

$verbose = $Test::Harness::verbose || 1;
my $testtable = "testhththdft";
my $t = 1;

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
    my $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    if (defined $dbname && $dbname !~ /^dbi:IngresII/) {
	$dbname = "dbi:IngresII:$dbname";
    }
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

my $dbname = get_dbname();

if (!defined $dbname) {
    print "1..0 # SKIP DBI_DBNAME and DBI_DSN aren't present\n";
    exit 0;
}

if (!$ENV{TEST_NCHAR}) {
    print "1..0 # SKIP TEST_NCHAR isn't present\n";
    exit 0;
}

print "1..$num_test\n";

my $dbh;

unless (ok($dbh = connect_db($dbname), "Connecting to database: $dbname")) {
    while ($t <= $num_test) {
	print "not ok $t # skipped\n";
	++$t;
    }
    exit 0;
}

#
# Table creation/destruction.  Can't do much else if this isn't working.
#
eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };
ok($dbh->do("CREATE TABLE $testtable(id INTEGER4 not null, name CHAR(64))"),
      "Basic create table");
ok($dbh->do("INSERT INTO $testtable VALUES(1, 'Alligator Descartes')"),
      "Basic insert(value)");
ok($dbh->do("DELETE FROM $testtable WHERE id = 1"),
      "Basic Delete");
ok($dbh->do( "DROP TABLE $testtable" ),
      "Basic drop table");

my $data = encode('utf-8', 'ąść');
my $data2 = encode('utf-8', 'śłź');


# CREATE TABLE OF APPROPRIATE TYPE
ok($dbh->do("CREATE TABLE $testtable (val NCHAR(10))"), "Create table (NCHAR)");
ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	  "Insert prepare (NCHAR)");
ok($cursor->execute($data), "Insert execute (NCHAR)");
ok($cursor->finish, "Insert finish (NCHAR)");
ok($cursor = $dbh->prepare("SELECT val FROM $testtable"), "Select prepare (NCHAR)");
ok($cursor->execute, "Select execute (NCHAR)");
my $ar = $cursor->fetchrow_arrayref; 
ok($ar && decode('utf-16le', $ar->[0]) eq ('ąść' . (' ' x 7)), "Select fetch (NCHAR)")
	or print STDERR "Got '" . encode('utf-8', decode('utf-16le', $ar->[0])) . "', expected '" . encode('utf-8', 'ąść' . (' ' x 7)) . "'.\n";
ok($cursor->finish, "Select finish (NCHAR)");
ok($dbh->do("DROP TABLE $testtable"), "Drop table (NCHAR)");

# CREATE TABLE OF APPROPRIATE TYPE
ok($dbh->do("CREATE TABLE $testtable (val NVARCHAR(10))"), "Create table (NVARCHAR)");
ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
	  "Insert prepare (NVARCHAR)");
ok($cursor->execute($data2), "Insert execute (NVARCHAR)");
ok($cursor->finish, "Insert finish (NVARCHAR)");
ok($cursor = $dbh->prepare("SELECT val FROM $testtable"), "Select prepare (NVARCHAR)");
ok($cursor->execute, "Select execute (NVARCHAR)");
$ar = $cursor->fetchrow_arrayref; 
ok($ar && $ar->[0] eq encode('utf-16le', 'śłź'), "Select fetch (NCHAR)")
	or print STDERR "Got '" . encode('utf-8', decode('utf-16le', $ar->[0])) . "', expected '" . encode('utf-8', 'śłź') . "'.\n";
ok($cursor->finish, "Select finish (NVARCHAR)");
ok($dbh->do("DROP TABLE $testtable"), "Drop table (NVARCHAR)");