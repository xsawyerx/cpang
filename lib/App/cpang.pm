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
use Path::Class;
use File::ShareDir 'dist_dir';
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
    return file( dist_dir(__PACKAGE__), 'cpang.glade' );
}

sub _build_gui {
    my $self  = shift;
    my $glade = $self->glade_path;
    return Gtk2::GladeXML->new($glade);
}

sub BUILD {
    my $self = shift;
    $self->gui->signal_autoconnect_from_package(__PACKAGE__);
}

sub _create_main_window {
    my $self   = shift;
    my $window = Gtk2::Window->new;

    # create a nice window
    $window->set_title( $self->{'title'} );
    $window->signal_connect(
        destroy => sub { Gtk2->main_quit }
    );

    $window->set_border_width(5);

    return $window;
}

sub run {
    my $self       = shift;
    my $terminal   = $self->{'_terminal'};
    my $vscrollbar = $self->{'_vscrollbar'};
    my $status     = $self->{'_status'};
    my $window     = $self->{'_main_window'};

    # create a vbox and put it in the window
    my $vbox = Gtk2::VBox->new( FALSE, 5 );
    $window->add($vbox);

    # create an hbox and put it in the vbox
    my $hbox = Gtk2::HBox->new( FALSE, 5 );
    $vbox->pack_start( $hbox, FALSE, TRUE, 5 );

    # create a label and put it in the hbox
    my $label = Gtk2::Label->new('Module name:');
    $hbox->pack_start( $label, FALSE, TRUE, 0 );

    # create an entry (textbox) and put it in the hbox
    my $entry = Gtk2::Entry->new;
    $entry->signal_connect(
        'activate' => sub { $self->click( $entry ) }
    );

    $hbox->pack_start( $entry, TRUE, TRUE, 0 );

    # create a button and put it in the hbox
    my $button = Gtk2::Button->new('Install');
    $button->signal_connect(
        clicked => sub { $self->click( $entry ) }
    );
    $hbox->pack_start( $button, FALSE, TRUE, 0 );

    # create a terminal and put it in the vbox too
    $vscrollbar->set_adjustment( $terminal->get_adjustment );
    $vbox->pack_start( $terminal, TRUE, TRUE, 0 );
    $terminal->signal_connect(
        child_exited => sub { $entry->set_editable(1) }
    );

    $vbox->pack_end ($status, FALSE, FALSE, 0);
    $window->show_all;
    $terminal->hide();
    Gtk2->main;
}

sub click {
    my ( $self, $entry ) = @_;
    my $status   = $self->{'_status'};
    my $terminal = $self->{'_terminal'};
    my $window   = $self->{'_main_window'};
    my $text     = $entry->get_text() || q{};

    if ($text) {
        $entry->set_editable(0);
        $entry->set_text('');

        $terminal->show();
        $status->pop (0);
        $status->push (0, "Installing $text...");

        my $cmd_result = $terminal->fork_command(
            'cpanm', [ 'cpanm', $text ],
            undef, '/tmp', FALSE, FALSE, FALSE,
        );

        if ( $cmd_result == -1 ) {
            my $cmd_result = $terminal->fork_command(
                'sudo', [ 'sudo', 'cpan', '-i', $text ],
                undef, '/tmp', FALSE, FALSE, FALSE,
            );

            if ( $cmd_result == -1 ) {
                print STDERR "Cannot find 'cpanm' command\n";
                my $dialog = Gtk2::MessageDialog->new(
                    $window,
                    'destroy-with-parent',
                    'warning',
                    'ok',
                    'Cannot find "sudo", "cpan" or "cpanm" program',
                );

                $dialog->run;
                $dialog->destroy;
            }
        }
    }
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

