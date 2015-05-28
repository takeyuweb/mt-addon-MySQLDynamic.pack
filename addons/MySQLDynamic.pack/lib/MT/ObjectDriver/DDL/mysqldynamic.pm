package MT::ObjectDriver::DDL::mysqldynamic;

use strict;
use warnings;
use MT::ObjectDriver::DDL::mysql;
use base qw( MT::ObjectDriver::DDL::mysql );

sub create_table_as_sql {
    my $ddl = shift;
    my $sql = $ddl->SUPER::create_table_as_sql(@_);
    $sql . ' ROW_FORMAT=DYNAMIC';
}

sub create_table_sql {
    my $ddl = shift;
    my $sql = $ddl->SUPER::create_table_sql(@_);
    $sql . ' ROW_FORMAT=DYNAMIC';
}

1;