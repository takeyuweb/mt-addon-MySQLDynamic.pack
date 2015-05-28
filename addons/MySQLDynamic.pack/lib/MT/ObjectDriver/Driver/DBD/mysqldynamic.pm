package MT::ObjectDriver::Driver::DBD::mysqldynamic;

use strict;
use warnings;

use base 'MT::ObjectDriver::Driver::DBD::mysql';

# DBIはmysqlと同じで良いので調整
sub dsn_from_config {
    my $dbd   = shift;
    my $dsn   = $dbd->SUPER::dsn_from_config(@_);
    $dsn =~ s/^dbi:mysqldynamic:/dbi:mysql:/;
    return $dsn;
}

# DDLで ROW_FORMAT=DYNAMIC 使う
sub ddl_class {
    require MT::ObjectDriver::DDL::mysqldynamic;
    return 'MT::ObjectDriver::DDL::mysqldynamic';
}

sub _set_names {
    my $dbd = shift;
    my ($dbh) = @_;
    return 1 if exists $dbh->{private_set_names};

    my $cfg       = MT->config;
    my $set_names = $cfg->SQLSetNames;
    $dbh->{private_set_names} = 1;
    return 1 if ( defined $set_names ) && !$set_names;

    eval {
        local $@;
        my $sth
            = $dbh->prepare('show variables like "character_set_database"')
            or die "error collecting variables from mysql: " . $dbh->errstr;
        $sth->execute
            or die "error collecting variables from mysql: " . $sth->errstr;
        my $result     = $sth->fetchall_hashref('Variable_name');
        my $charset_db = $result->{character_set_database}{Value};
        if ( defined($charset_db) && ( $charset_db ne 'latin1' ) ) {

            # MySQL 4.1+ and non-latin1(database) == needs SET NAMES call.
            my $c       = lc $cfg->PublishCharset;
            my %Charset = (
# CUSTOMIZE
                'utf-8'     => 'utf8mb4',
# /CUSTOMIZE
                'shift_jis' => 'sjis',
                'shift-jis' => 'sjis',
                'euc-jp'    => 'ujis',

                #'iso-8859-1' => 'latin1'
            );
            $c = $Charset{$c} ? $Charset{$c} : $c;
            $dbh->do( "SET NAMES " . $c )
                or return ( $dbh->errstr );
            if ( !defined $set_names ) {

               # SQLSetNames has never been assigned; we had a successful
               # 'SET NAMES' command, so it's safe to SET NAMES in the future.
                $cfg->SQLSetNames(1);
            }
        }
        else {

            # 'set names' command isn't working for this verison of mysql,
            # assign SQLSetNames to 0 to prevent further errors.
            $cfg->SQLSetNames(0);
            return 0;
        }
    };
    1;
}

1;