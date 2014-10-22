#!perl -w
#
# Tk Transaction Manager.
# Blank data widget. To use with data object.
#
# makarow, demed
#

package Tk::TM::wgBlank;
require 5.000;
use strict;
require Exporter;
use Tk;
use Tk::TM::Common;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = ('Tk::Derived','Tk::Frame');

Tk::Widget->Construct('tmBlank'); 

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
 $self->{-do}       =undef; # transaction manager           # configurable
 $self->{-wgspecs}  =[];    # specifications of widgets     # configurable
 $self->{-widgets}  =[];    # widget =$self->[$col]
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
    my $fld =-1;
    foreach my $wg (@{$self->{-widgets}}) {
      $fld++;
      next if !$wg || ref($wg) eq 'Tk::Label';
      my $tv;
      $wg->configure(-textvariable=>\$tv);
      $wg->bind('<Key-Prior>'   ,sub{$self->{-do}->RowGo('prev')});
      $wg->bind('<Key-Next>'    ,sub{$self->{-do}->RowGo('next')});
      $wg->bind('<Control-Home>',sub{$self->{-do}->RowGo('top')});
      $wg->bind('<Control-End>' ,sub{$self->{-do}->RowGo('bot')});
      my $fld1 =$fld;
      $wg->bind('<FocusIn>' ,sub{$self->{-do}->wgFldFocusIn ($wg, $fld1)});
      $wg->bind('<FocusOut>',sub{$self->{-do}->wgFldFocusOut($wg, $fld1)});
      $wg->bind('<Key-F4>'  ,sub{$self->{-do}->wgFldHelper  ($wg, $fld1)});
    }
 }
 $self;
}

#######################
sub Remake {
 my ($self) =(shift);

 foreach my $wg ($self->children) {
   $wg->destroy();
 }

 my ($row, $col) =(-1, -1);
 foreach my $wgs (@{$self->{-wgspecs}}) {
   my @wgs1 =@$wgs;
   my ($wgs1, $wg);

   if ($wgs1[0] =~/^\d*$/) {$col +=$wgs1[0]; shift(@wgs1)}
   else {$row++; $col =0 }
   $wgs1 =shift(@wgs1);
   $wg =$self->Label(ref($wgs1) ? ('-text',@$wgs1) : ('-text',$wgs1));
   $wg->grid(-column=>$col, -row=>$row, -sticky=>'w');

   my ($colspan, $rowspan)=(1,1);
   if ($wgs1[0] =~/^\d*$/) {$colspan =$wgs1[0]; shift(@wgs1)}
   if ($wgs1[0] =~/^\d*$/) {$rowspan =$wgs1[0]; shift(@wgs1)}
   $col++;
   $wgs1 =shift(@wgs1);
   $wg =$self->$wgs1(@wgs1);
   $wg->grid(-column=>$col,-row=>$row,-sticky=>'w',-columnspan=>$colspan,-rowspan=>$rowspan);
   push(@{$self->{-widgets}}, $wg);
 }

 $self->set(-widgets=>$self->{-widgets});
}

#######################
sub Display {
  my ($self) =(shift);
  if ($self->{-do}) {
    my $do     =$self->{-do};
    my $fld    =-1;
    my $rowdta =$do->dsRowDta();
    foreach my $wg (@{$self->{-widgets}}) {
      $fld ++;
      next if !$wg || ref($wg) eq 'Tk::Label';
      ${$wg->cget(-textvariable)} =$rowdta->[$fld];
    }
  }
  $self
}

#######################
sub Focus {
  my ($self) =(shift);
  my $do  =$self->{-do};
  return if !$do;
  if (ref($do) && defined($do->{-dsrfd})) {
     $self->{-widgets}->[$do->{-dsrfd}]->focusForce()
  }
  else {
     foreach my $wg (@{$self->{-widgets}}) {
        return($wg->focusForce()) if ref($wg)
     }
  }
}