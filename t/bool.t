use strict;
use warnings;
use utf8;

use Test::More;
use DBD::IngresII;
use DBI;

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

    my $dbh = DBI->connect($dbname, "", "",
		    { AutoCommit => 0, RaiseError => 0, PrintError => 0 })
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
    plan tests => 8;
}

my $dbh = connect_db($dbname);

ok(($dbh->ing_bool_to_str(undef) eq 'NULL'), 'testing ->ing_bool_to_str(undef)');
ok(($dbh->ing_bool_to_str(0) eq 'FALSE'), 'testing ->ing_bool_to_str(0)');
ok(($dbh->ing_bool_to_str(1) eq 'TRUE'), 'testing ->ing_bool_to_str(1)');

$SIG{__WARN__} = sub {}; # Disable warnings for next test

ok((!defined $dbh->ing_bool_to_str(2)), 'testing ->ing_bool_to_str(2)');

$SIG{__WARN__} = 'DEFAULT';

ok((!defined $dbh->ing_norm_bool(undef)), 'testing ->ing_norm_bool(undef)');
ok(($dbh->ing_norm_bool(3) == 1), 'testing ->ing_norm_bool(3)');
ok(($dbh->ing_norm_bool(0) == 0), 'testing ->ing_norm_bool(0)');
ok(($dbh->ing_norm_bool(-1) == 1), 'testing ->ing_norm_bool(-1)');

$dbh and $dbh->commit;
$dbh and $dbh->disconnect;

exit(0);
