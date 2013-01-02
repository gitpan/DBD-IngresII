# Copyright (c) 2013 Tomasz Konojacki
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;
use DBI;
use Encode;

my $testtable = 'asdsdfgza';

sub get_dbname {
    # find the name of a database on which test are to be performed
    my $dbname = $ENV{DBI_DBNAME} || $ENV{DBI_DSN};
    if (defined $dbname && $dbname !~ /^dbi:IngresII/) {
	    $dbname = "dbi:IngresII:$dbname";
    }
    return $dbname;
}

sub connect_db {
    # Connects to the database.
    # If this fails everything else is in vain!
    my ($dbname) = @_;
    $ENV{II_DATE_FORMAT}='SWEDEN';       # yyyy-mm-dd

    my $dbh = DBI->connect($dbname, '', '',
		    { AutoCommit => 0, RaiseError => 0, PrintError => 1, ShowErrorStatement=>1 })
	or die 'Unable to connect to database!';
    $dbh->{ChopBlanks} = 0;

    return $dbh;
}

my $dbname = get_dbname();

############################
# BEGINNING OF TESTS       #
############################

unless (defined $dbname) {
    plan skip_all => 'DBI_DBNAME and DBI_DSN aren\'t present';
}
else {
    plan tests => 23;
}

my $dbh = connect_db($dbname);
my($cursor, $str);

eval { local $dbh->{RaiseError}=0;
       local $dbh->{PrintError}=0;
       $dbh->do("DROP TABLE $testtable"); };

if ($dbh->ing_is_vectorwise) {
    ok($dbh->do("CREATE TABLE $testtable(lol VARCHAR(12)) WITH STRUCTURE=HEAP"),
      'CREATE TABLE');
}
else {
    ok($dbh->do("CREATE TABLE $testtable(lol VARCHAR(12))"),
      'CREATE TABLE');
}

$dbh->{ing_empty_isnull} = 0;

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->execute(''), 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok((my $ar = $cursor->fetchrow_hashref), 'Fetch row');

ok(((defined $ar->{lol}) && ($ar->{lol} eq '')), 'Check whether string is empty');

ok($dbh->do(qq{DELETE FROM $testtable WHERE lol = ''}), 'DELETE row');

$dbh->{ing_empty_isnull} = 1;

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)"),
      'Prepare INSERT');

ok($cursor->execute(''), 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok((!defined $ar->{lol}), 'Check whether returned value is NULL');

ok($dbh->do("DELETE FROM $testtable WHERE lol IS NULL"), 'DELETE row');

ok($cursor = $dbh->prepare("INSERT INTO $testtable VALUES (?)", {ing_empty_isnull => 0}),
      'Prepare INSERT');

ok($cursor->execute(''), 'Execute INSERT');

ok($cursor = $dbh->prepare("SELECT lol FROM $testtable"),
      'Prepare SELECT');

ok($cursor->execute, 'Execute SELECT');

ok(($ar = $cursor->fetchrow_hashref), 'Fetch row');

ok(((defined $ar->{lol}) && ($ar->{lol} eq '')), 'Check whether string is empty');

ok($cursor->finish, 'Finish SELECT cursor');

ok($dbh->do("DROP TABLE $testtable"), 'DROP TABLE');

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;