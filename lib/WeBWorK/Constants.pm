package WeBWorK::Constants;

use strict;
use warnings;

our $WEBWORK_DIRECTORY = $ENV{WEBWORK_ROOT}
    // $ENV{RENDER_ROOT}
    // $ENV{PG_ROOT}
    // '';

our $PG_DIRECTORY = $ENV{PG_ROOT}
    // ($WEBWORK_DIRECTORY ? "$WEBWORK_DIRECTORY/pg" : '');

1;
