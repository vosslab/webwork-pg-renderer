package WeBWorK::PreTeXt;
use Mojo::Base 'Mojolicious::Controller', -async_await;

use Data::Structure::Util qw(unbless);

use warnings;
use strict;

use lib "$ENV{PG_ROOT}/lib";
use WeBWorK::PG;

sub render_ptx {
	my $p      = shift;
	my $source = $p->{rawProblemSource};
	my $pg     = WeBWorK::PG->new(
		showSolutions       => 1,
		showHints           => 1,
		processAnswers      => 1,
		displayMode         => 'PTX',
		language_subroutine => WeBWorK::PG::Localize::getLoc('en'),
		problemSeed         => $p->{problemSeed} // 1234,
		$p->{problemUUID}       ? (problemUUID       => $p->{problemUUID})       : (),
		$p->{templateDirectory} ? (templateDirectory => $p->{templateDirectory}) : (),
		$p->{tempDirectory}     ? (tempDirectory     => $p->{tempDirectory})     : (),
		$p->{sourceFilePath}    ? (sourceFilePath    => $p->{sourceFilePath})    : (),
		$source                 ? (r_source          => \$source)                : ()
	);

	my $ret = {
		body    => $pg->{body_text},
		answers => unbless($pg->{answers})
	};

	$pg->free;
	return $ret;
}
1;
