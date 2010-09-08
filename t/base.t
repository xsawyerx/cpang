#!perl

use strict;
use warnings;

use Test::More tests => 5;
use App::cpang;

my $cg = App::cpang->new();
isa_ok( $cg, 'App::cpang' );
isa_ok( $cg->{'main_window'}, 'Gtk2::Window'          );
isa_ok( $cg->{'terminal'},    'Gnome2::Vte::Terminal' );
isa_ok( $cg->{'scrollbar'},   'Gtk2::VScrollbar'      );
isa_ok( $cg->{'status'},      'Gtk2::Statusbar'       );


