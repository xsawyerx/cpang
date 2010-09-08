use strict;
use warnings;
package App::cpang;

use Gtk2 '-init';
use Glib qw/ TRUE FALSE /;
use Gnome2::Vte;

our $VERSION = '0.03';

sub new {
    my $class = shift;
    my $self  = bless {
        main_window => Gtk2::Window->new,
        terminal    => Gnome2::Vte::Terminal->new,
        scrollbar   => Gtk2::VScrollbar->new,
        status      => Gtk2::Statusbar->new,
    }, $class;
    return $self;
}

sub run {
    my $self      = shift;
    my $terminal  = $self->{'terminal'};
    my $scrollbar = $self->{'scrollbar'};
    my $status    = $self->{'status'};
    my $window    = $self->{'main_window'};

    # create a nice window
    $window->set_title('cpang');
    $window->signal_connect( destroy => sub { Gtk2->main_quit; } );
    $window->set_border_width(5);

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
    $scrollbar->set_adjustment( $terminal->get_adjustment );
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
    my $status   = $self->{'status'};
    my $terminal = $self->{'terminal'};
    my $window   = $self->{'main_window'};
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
