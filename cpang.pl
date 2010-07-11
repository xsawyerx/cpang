#!/usr/bin/perl

use strict;
use warnings;

use Gtk2 '-init';
use Glib qw/ TRUE FALSE /;
use Gnome2::Vte;

# create a nice window
my $window = Gtk2::Window->new;
$window->set_title('cpang');
$window->signal_connect( destroy => sub { Gtk2->main_quit; } );
$window->set_border_width(5);

# create a vbox and put it in the window
my $vbox = Gtk2::VBox->new( FALSE, 5 );
$window->add($vbox);

# create an hbox and put it in the vbox
my $hbox = Gtk2::HBox->new( FALSE, 5 );
$vbox->pack_start( $hbox, TRUE, TRUE, 5 );

# create a label and put it in the hbox
my $label = Gtk2::Label->new('Module name:');
$hbox->pack_start( $label, FALSE, TRUE, 0 );

# create an entry (textbox) and put it in the hbox
my $entry = Gtk2::Entry->new;
$entry->signal_connect( 'activate' => \&click );

$hbox->pack_start( $entry, TRUE, TRUE, 0 );

# create a button and put it in the hbox
my $button = Gtk2::Button->new('Install');
$button->signal_connect( clicked => \&click );
$hbox->pack_start( $button, FALSE, TRUE, 0 );

# create a terminal and put it in the vbox too
my $terminal  = Gnome2::Vte::Terminal->new();
my $scrollbar = Gtk2::VScrollbar->new;
$scrollbar->set_adjustment( $terminal->get_adjustment );
$vbox->pack_start( $terminal, TRUE, TRUE, 0 );
$terminal->signal_connect( child_exited => sub { $entry->set_editable(1); } );

my $status = Gtk2::Statusbar->new ();
$vbox->pack_end ($status, FALSE, FALSE, 0);
$window->show_all;
$terminal->hide();
Gtk2->main;

sub click {
    my ($object) = @_;
    my $text = $entry->get_text() || q{};
    if ($text) {
        $entry->set_editable(0);

        $terminal->fork_command(
            'cpanm', [ 'cpanm', $text ], undef, '/tmp', FALSE, FALSE, FALSE
        );
    }
}

