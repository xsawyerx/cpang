#!perl

use strict;
use warnings;

use Test::More tests => 7;
use App::cpang;

{
    my $cg = App::cpang->new();
    isa_ok( $cg, 'App::cpang' );
    isa_ok( $cg->{'_main_window'}, 'Gtk2::Window'          );
    isa_ok( $cg->{'_terminal'},    'Gnome2::Vte::Terminal' );
    isa_ok( $cg->{'_vscrollbar'},  'Gtk2::VScrollbar'      );
    isa_ok( $cg->{'_status'},      'Gtk2::Statusbar'       );

    is( $cg->{'title'}, 'cpang', 'Default title' );
}

{
    my $cg = App::cpang->new( title => 'new' );
    is( $cg->{'title'}, 'new', 'Title is changable in new' );
}

