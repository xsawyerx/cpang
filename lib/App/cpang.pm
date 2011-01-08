use strict;
use warnings;
package App::cpang;
# ABSTRACT: CPAN GUI in Gtk2

use Any::Moose;

# Glib/Gtk stuff
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::Ex::Simple::List;

# additional modules
use CPANDB;
use CPANDB::Distribution;
use Path::Class;
use File::ShareDir  'dist_dir';
use Module::Version 'get_version';

has 'glade_path' => (
    is         => 'ro',
    isa        => 'Path::Class::File',
    lazy_build => 1,
);

has 'gui' => (
    is         => 'ro',
    isa        => 'Gtk2::GladeXML',
    lazy_build => 1,
);

sub _build_glade_path {
    my $self = shift;
    return file( dist_dir('App-cpang'), 'cpang.glade' );
}

sub _build_gui {
    my $self  = shift;
    my $glade = $self->glade_path;
    return Gtk2::GladeXML->new($glade);
}

sub BUILD {
    my $self = shift;
    $self->gui->signal_autoconnect_from_package($self);
}

sub run {
    Gtk2->main;
}

sub gtk_main_quit {
    Gtk2->main_quit;
}

sub run_search {
    my $self      = shift;
    my $widget    = shift;
    my $gui       = $self->gui;
    my $dbh       = CPANDB->dbh;
    my $searchbox = $gui->get_widget('searchtextbox');

    my $tree_widget = $gui->get_widget('searchresults');
    my $resultslist = Gtk2::Ex::Simple::List->new_from_treeview(
        $tree_widget =>
        ''            => 'bool',
        'Dist name'   => 'text',
        'Latest'      => 'text',
        'Installed'   => 'text',
        'Author'      => 'text',
        'Description' => 'text',
    );
#    $tree_widget->{data} is an ARRAYREF

    foreach my $col ( $resultslist->get_columns() ) {
        $col->set_resizable(1);
        $col->set_sizing('grow-only');
    }

    #$resultslist->set_headers_clickable(1);
    my $searchterm = $searchbox->get_text or return;
    my @results    = $self->fetch_results($searchterm);

    foreach my $dist (@results) {
        my $module = $dist;
        $module =~ s{-}{::}g;

        my $installed = get_version($module);

        push @{ $resultslist->{'data'} },
            [
                FALSE,
                $dist->distribution,
                $dist->version || 'no info',
                $installed     || '',
                $dist->author  || 'no info',
                'A postmodern object system for Perl 5',
            ];
    }

    $resultslist->select(0);
}

sub fetch_results {
    my $self    = shift;
    my $term    = shift;
    my %saw     = ();
    my @results = grep { ! $saw{ $_->distribution }++ }
                      $self->fetch_main_dist($term),
                      $self->fetch_starting_dists($term),
                      $self->fetch_ending_dists($term);

    return @results;
}

sub fetch_main_dist {
    my $self = shift;
    my $term = shift;
    my $dist = CPANDB->distribution($term);

    return $dist;
}

sub fetch_starting_dists {
    my $self = shift;
    my $term = shift;

    my @starting_with = CPANDB::Distribution->select(
        'where distribution LIKE ? order by distribution',
        "$term%",
    );

    return @starting_with;
}

sub fetch_ending_dists {
    my $self = shift;
    my $term = shift;

    my @ending_with = CPANDB::Distribution->select(
        'where distribution LIKE ? order by distribution',
        "\%$term",
    );

    return @ending_with;
}

1;

__END__

=head1 DESCRIPTION

It's about time we have a GUI for I<cpan>. Apparently we're not that into GUI,
but users are, so we need^Wshould care about it too.

This is a rough draft of a basic cpan GUI. It uses L<App::cpanminus> instead of
the basic I<cpan>. It's not pretty, but it's a start.

You are B<more than welcome> to help me work this into a beautiful GUI
application for users to use in order to search/install/test(?) modules and
applications from CPAN.

=head1 FOR USERS

If you are a user, please check L<cpang> for how to use this.

This paper describes the module behind the application.

=head1 ATTRIBUTES

These are the attributes available in C<new()>.

=head2 title

Sets the title of the main window.

    use App::cpang;

    my $app = App::cpang->new( title => 'MY MAIN TITLE!' );

=head1 SUBROUTINES/METHODS

=head2 new

Surprisingly this creates a new object of type L<App::cpang>.

=head2 run

Packs everything and runs the application.

    $app->run;

=head3 click($event)

Clicks on the "Install" step. This is bound to an event of the button in the
interface.

