#!/usr/bin/perl

use strict;
use warnings;
package
    cpang;

# Glib/Gtk stuff
use Glib qw/TRUE FALSE/;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::SimpleList;

# additional modules
use CPANDB;
use Path::Class;
use File::ShareDir 'dist_dir';
use Module::Version 'get_version';
use Data::Dump 'dd';

my $gui = Gtk2::GladeXML->new( file( dist_dir('App-cpang'), 'cpang.glade' ) );
my $dbh = CPANDB->dbh;

$gui->signal_autoconnect_from_package('cpang');

Gtk2->main;

sub run_search {
    my $widget    = shift;
    my $searchbox = $gui->get_widget('searchtextbox');

    # decide what kind of search we want
    my $widget_name = $widget->get_name();
    if ( $widget_name eq 'distbutton' ) {
        # we want a dist search
    } elsif ( $widget_name eq 'authorbutton' ) {
        # we want an author search
    } else {
        # we want a dist search
        # TODO: default
    }

    my $tree_widget = $gui->get_widget('searchresults');
    my $resultslist = Gtk2::SimpleList->new_from_treeview(
        $tree_widget =>
        ''            => 'bool',
        'Dist name'   => 'text',
        'Latest'      => 'text',
        'Installed'   => 'text',
        'Author'      => 'text',
        'Description' => 'text',
    );
#    $tree_widget->{data} is an ARRAYREF

    $searchbox->get_text or return;

    #$resultslist->set_headers_clickable(1);
    foreach my $col ( $resultslist->get_columns() ) {
        $col->set_resizable(1);
        $col->set_sizing('grow-only');
    }

    my $sth = $dbh->prepare('SELECT DISTINCT distribution, module FROM module WHERE module LIKE ? ORDER BY distribution');
    $sth->execute( '%' . $searchbox->get_text . '%' );
    my $arrayref = $sth->fetchall_arrayref;

    foreach my $distref ( @{$arrayref} ) {
        my $distname   = shift @{$distref};
        my $modulename = shift @{$distref};

        # get dist information
        $sth = $dbh->prepare('SELECT version, author FROM distribution WHERE distribution = ?');
        $sth->execute($distname);
        my $distdata = $sth->fetchrow_arrayref;

        my ( $latest_version, $author_id ) = $distdata    ?
                                             @{$distdata} :
                                             ( 'no info', 'no info' );

        my $installed_version = get_version($modulename);

        push @{ $resultslist->{'data'} },
            [
                FALSE,
                $modulename,
                $latest_version,
                $installed_version,
                $author_id,
                'A postmodern object system for Perl 5',
            ];
    }

    $resultslist->select(0);
}

sub searchresults_activated {
    my $widget = shift;

    my $index = ($widget->get_selected_indices())[0];
    print "Index: $index\n";
}

sub searchresults_key_release {

}

sub gtk_main_quit {
    Gtk2->main_quit;
}
