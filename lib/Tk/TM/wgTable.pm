#!perl -w
#
# Tk Transaction Manager.
# Table data widget. To use with data object.
#
# makarow, demed
#

package Tk::TM::wgTable;
require 5.000;
use strict;
require Exporter;
use Tk;
use Tk::TM::Common;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = ('Tk::Derived','Tk::Frame');

Tk::Widget->Construct('tmTable'); 

#######################
sub Populate {
 my ($self, $args) = @_;
 my $mw =$self->parent;

 # print "********Populate/Initing...\n";
 $self->initialize();
 foreach my $opt ($self->set()) {
   if ($args->{$opt}) {
      $self->set($opt=>$args->{$opt});
      delete($args->{$opt});
   }
 }
 $self->configure(-borderwidth=>2,-relief=>'groove');
 $self->ConfigSpecs(-font=>['DESCENDANTS']);
 $self->ConfigSpecs(-relief=>['CHILDREN']);
 $self->ConfigSpecs(-background=>['CHILDREN']);
 $self->ConfigSpecs(-foreground=>['CHILDREN']);

 # print "********Populate/Populating...\n";
 $self->Remake();
 $self
}

#######################
sub initialize {
 my $self = shift;
 my $mw   =$self->parent;
 $self->{-do}       =undef; # transaction manager            # configurable
 $self->{-colspecs} =[];    # widgetSpec =$self->[$col]      # configurable
 $self->{-rowcount} =3;     # count of rows                  # configurable
 $self->{-widgets}  =[];    # widget =$self->[$row]->[$col]
}

#######################
sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($self, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $self->{$k} =$opt{$k};
 }
 if ($opt{-do} || ($self->{-do} && $opt{-widgets})) {
    # print "****bindings****\n";
    my $row =-1;
    foreach my $wgrow (@{$self->{-widgets}}) {
      $row++;
      my $col =-1;
      foreach my $wg (@$wgrow) {
        $col++;
        next if !$wg || ref($wg) eq 'Tk::Label';
        my $tv;
        $wg->configure(-textvariable=>\$tv);
        my ($row1, $col1) =($row, $col);
        $wg->bind('<Up>'          ,sub{$self->{-do}->RowGo('prev')});
        $wg->bind('<Down>'        ,sub{$self->{-do}->RowGo('next')});
        $wg->bind('<Prior>'       ,sub{$self->{-do}->RowGo('pgup')});
        $wg->bind('<Next>'        ,sub{$self->{-do}->RowGo('pgdn')});
        $wg->bind('<Control-Home>',sub{$self->{-do}->RowGo('top')});
        $wg->bind('<Control-End>' ,sub{$self->{-do}->RowGo('bot')});
        $wg->bind('<FocusIn>' ,sub{$self->{-do}->wgFldFocusIn ($wg, $col1, $row1)});
        $wg->bind('<FocusOut>',sub{$self->{-do}->wgFldFocusOut($wg, $col1, $row1)});
        $wg->bind('<Key-F4>'  ,sub{$self->{-do}->wgFldHelper  ($wg, $col1, $row1)});
      }
    }
 }
 $self;
}

#######################
sub Remake {
 my $self =shift;

 foreach my $wg ($self->children) {
   $wg->destroy();
 }

 my $col =-1;
 foreach my $wgs (@{$self->{-colspecs}}) {
       $col++;
       my @wgs =@{$wgs};
       my $wgn =shift(@wgs);
       my $wg;
       if ($wgn) {
          $wg =$self->Label(-text, !ref($wgn) ? $wgn : @$wgn);
          $wg->grid(-column=>$col, -row=>0, -sticky=>'w');
       }
 }

 for (my $row=0; $row <$self->{-rowcount}; $row++) {
   push(@{$self->{-widgets}}, []);
   my $col =-1;
   foreach my $wgs (@{$self->{-colspecs}}) {
       $col++;
       my @wgs =@{$wgs}; shift(@wgs);
       my $wgn =shift(@wgs);
       my $wg  =$self->$wgn(@wgs);
       $wg->grid(-column=>$col, -row=>$row+1, -sticky=>'w');
       $self->{-widgets}->[$row]->[$col] =$wg;
   }
 }

 $self->set(-widgets=>$self->{-widgets});
 $self
}

#######################
sub Display {
  my ($self) =(shift);
  if ($self->{-do}) {
    my $do  =$self->{-do};
    my $row =-1;
    my $rowadd =$do->{-dsrid} -($do->{-dsrsd} ||0);
       $rowadd =0 if $rowadd <0;
    # print "Display: ",$do->{-dsrid},":",-$do->{-dsrsd},"+",$rowadd,"\n";
    foreach my $wgrow (@{$self->{-widgets}}) {
      $row++;
      my $rowdta =$do->dsRowDta($row +$rowadd);
      my $col    =-1;
      foreach my $wg (@$wgrow) {
        $col++;
        next if !Exists($wg) || ref($wg) eq 'Tk::Label';
        ${$wg->cget(-textvariable)} =$rowdta->[$col];
      }
    }
  }
  $self
}

#######################
sub Focus {
  my ($self) =(shift);
  my $do  =$self->{-do};
  return if !$do;
  if (ref($do) && defined($do->{-dsrfd}) && defined($do->{-dsrsd})) {
     $self->{-widgets}->[($do->{-dsrsd} <0 ? 0 : $do->{-dsrsd})]->[$do->{-dsrfd}]->focusForce()
  }
  else {
     foreach my $wg (@{$self->{-widgets}->[0]}) {
        return($wg->focusForce()) if ref($wg)
     }
  }
}