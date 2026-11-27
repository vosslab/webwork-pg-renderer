package RenderApp::Controller::Pages;
use Mojo::Base 'Mojolicious::Controller';
use Mojo::File 'path';

sub twocolumn {
    _render_page(shift, 'pages/twocolumn');
}

sub oplUI {
    _render_page(shift, 'pages/oplUI');
}

sub _render_page {
    my ($c, $template) = @_;
    # ASVS 5.3.2. Check fixed directory names under the configured installation path.
    my $opl_root = path($ENV{OPL_DIRECTORY});
    my @opl_folders = map { [$_->[0], $_->[0] . '/'] }
        grep { -d $opl_root->child($_->[1]) }
        ([Contrib => 'Contrib'], [Library => 'OpenProblemLibrary']);
    my $opl_available = grep { $_->[0] eq 'Library' } @opl_folders;
    $c->render(template => $template, opl_available => $opl_available, opl_folders => \@opl_folders);
}

1;
