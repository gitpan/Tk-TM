#!perl -w
#
# Tk Transaction Manager.
# Data Object.
#
# makarow, demed
#

package Tk::TM::DataObject;
require 5.000;
use strict;
require Exporter;
use Tk;
use Tk::TM::Common;
use Tk::TM::Lang;
use Tk::TM::DataObjSet;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = qw(Exporter);

use vars qw($Current @Available $Error $Search);
$Current    ='';    # Current DO
@Available  =();    # All available DOs
$Error      ='';    # Error if occured
$Search     ='';    # Search for

1;

#######################
sub new {
 my $class=shift;
 my $self ={};
 bless $self,$class;
 $self->initialize(@_);
}

#######################
sub initialize {
 my $self =shift;

 $self->{-wgtbl} =undef;       # WG screen table          # configurable
 $self->{-wgbln} =undef;       # WG screen blank          # configurable
 $self->{-wgarr} =[];          # WG widget list           # configurable
 $self->{-wgscr} =undef;       # WG parent screen widget  # configurable
 $self->{-wgnav} =             # WG navigator widget      # configurable
                  ref($Tk::TM::DataObjSet::Current) && ($Tk::TM::DataObjSet::Current->set(-dos) eq \@Available) ? $Tk::TM::DataObjSet::Current : undef;
 $self->{-wgind} =             # WG widget for indicator  # configurable
                  ref($Tk::TM::DataObjSet::Current) ? $Tk::TM::DataObjSet::Current->set(-wgind) : undef;
 $self->{-mdedt} =             # MD edit mode on          # configurable
                  $Tk::TM::Common::Edit;
 $self->{-dscol} =[];          # DS columns definitions;  # configurable, unused
 $self->{-dsdta} =[];          # DS retrieved data store
 $self->{-dsdtm} =1000;        # DS data store margin;    # configurable

 $self->{-dsrid} =0;           # DS current row id
 $self->{-dsrsd} =0;           # DS current screen row id
 $self->{-dsrfd} =undef;       # DS current field no
 $self->{-dsrwd} =undef;       # DS current widget id
 $self->{-dsrwt} =0;           # DS current widget is table?
 $self->{-dsrnw} =0;           # DS current row new?
 $self->{-dsrch} =0;           # DS current row changed?
 $self->{-dsrd0} =[];          # DS current row presaved data

 $self->{-cbcmd} =\&doDefault; # CB routine;              # configurable
#$self->{-cbXXX}               # CB routines for operations instead of '-cbcmd'

 $self->{-dbh}   =undef;       # DBI database handle      # configurable
 $self->{-dbfds} =[];          # DBI field descriptions
 $self->{-dbfnm} ={};          # DBI field names
 $self->{-parm}  ={};          # Programmer`s parameters  # configurable

 $Current =$self;
 push(@Available, $self);

 $self->set(-mdedt=>$self->{-mdedt},@_);
 $self;
}

#######################
sub destroy {
 my $self =$_[0];
 print "destroy($self)\n" if $Tk::TM::Common::Debug;
 $self->Stop('#force#end');
 @Available = grep($self ne $_, @Available);
 $self;
}

#######################
sub DESTROY {
 my $self =$_[0];
 print "DESTROY($self)\n" if $Tk::TM::Common::Debug;
}

#######################
sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($self, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $self->{$k} =$opt{$k};
 }

 if ($opt{-wgtbl}) {
    $self->{-wgtbl}->set(-do=>$self);
    $self->{-dsrwt} =1;
 }
 if ($opt{-wgbln}) {
    $self->{-wgbln}->set(-do=>$self);
    $self->{-dsrwt} =0 if !$self->{-wgtbl};
 }
 if ($opt{-wgarr}) {
    my $fld =-1;
    foreach my $wg (@{$self->{-wgarr}}) {
      $fld++;
      next if !$wg || ref($wg) eq 'Tk::Label';
      my $tv;
      $wg->configure(-textvariable=>\$tv);
      $wg->bind('<Key-Prior>'   ,sub{$self->RowGo('prev')});
      $wg->bind('<Key-Next>'    ,sub{$self->RowGo('next')});
      $wg->bind('<Control-Home>',sub{$self->RowGo('top')});
      $wg->bind('<Control-End>' ,sub{$self->RowGo('bot')});
      my $fld1 =$fld;
      $wg->bind('<FocusIn>' ,sub{$self->wgFldFocusIn ($wg, $fld1)});
      $wg->bind('<FocusOut>',sub{$self->wgFldFocusOut($wg, $fld1)});
      $wg->bind('<Key-F4>'  ,sub{$self->wgFldHelper  ($wg, $fld1)});
    }
    $self->{-dsrwt} =0 if !$self->{-wgtbl};
 }
 if (!$self->{-wgscr}) {
    $self->{-wgscr} =($self->{-wgtbl} 
                     ? $self->{-wgtbl} 
                     : $self->{-wgbln} 
                       ? $self->{-wgbln}
                       : $self->{-wgarr}->[0]);
    $self->{-wgscr} =$self->{-wgscr}->parent if $self->{-wgscr};
 }
 if (ref($opt{-wgnav}) || (exists($opt{-mdedt}) && ref($self->{-wgnav}))) {
    $self->{-wgnav}->setpush(-dos => $self) if ref($opt{-wgnav}) && !grep {$_ eq $self} @{$self->{-wgnav}->set(-dos)};
    $self->{-wgnav}->set(-mdedt => $self->{-mdedt}) if $self->{-wgnav}->DataObject() eq $self;
 }
 $self;
}

#######################
sub setpush {
 my ($self, $opt) =(shift,shift);
 if    ($opt =~/-wgarr/) {
       $self->set(-wgarr => [$self->set(-wgarr),@_]);
 }
 elsif (ref($self->{$opt}) eq 'ARRAY') {
       push(@{$self->{$opt}}, @_)
 }
 elsif (ref($self->{$opt}) eq 'HASH') {
       my %v =@_;
       foreach my $k (keys(%v)) { $self->{$opt}->{$k} =$v{$k} }
 }
 scalar(@_) ==1 ? $_[0] : @_;
}


#######################
# Widget Data System Dependent Functions
#######################

sub dsDisplay {              # Display data
 $_[0]->{-wgtbl}->Display() if $_[0]->{-wgtbl};
 $_[0]->dsDispWg();
 return $_[0];
}

sub dsDispWg {               # Display data in widgets and blank widget
 my $self =shift;
 my $fld =-1;
 $self->{-wgbln}->Display() if $self->{-wgbln};
 foreach my $wg (@{$self->{-wgarr}}) {
   $fld++;
   next if !$wg || ref($wg) eq 'Tk::Label';
   ${$wg->cget(-textvariable)} =undef;
   ${$wg->cget(-textvariable)} =($self->{-dsdta}->[$self->{-dsrid}]->[$fld]) if $self->{-dsdta}->[$self->{-dsrid}];
 }
 $self
}

sub dsFldDta {               # Get specified field current data; Silent
 my ($self, $wg) =@_;
 my $ret;
 if    (defined($wg) && !ref($wg)) {
       $ret =$wg =~/^([\d]+)$/ 
             ? $self->{-dsdta}->[$self->{-dsrid}]->[$wg]
             : $self->{-dsdta}->[$self->{-dsrid}]->[$self->{-dbfnm}->{$wg}]
 }
 elsif (defined($wg) && Exists($wg)) {
       $ret =${$wg->cget(-textvariable)}
 }
 elsif ($self->{-dsrwd} && Exists($self->{-dsrwd})) {
       $ret =${$self->{-dsrwd}->cget(-textvariable)}
 }
 # !defined($ret) ? '' : $ret;
 $ret
}

sub dsFldUpd {               # Replace specified field data; Display
 my ($self, $fld, $data) =@_;
 my $wg;
 if (!defined($fld) || $fld eq '') {$fld =$self->{-dsrfd} || 0}
 elsif ($fld !~/^([\d]+)$/)        {$fld =$self->{-dbfnm}->{$fld}}

 $wg =$self->{-wgtbl}->set('-widgets')->[$self->{-dsrsd}]->[$fld] if $self->{-wgtbl};
 if ($wg){
    ${$wg->cget(-textvariable)} =$data;
 }

 $wg =undef;
 $wg =$self->{-wgbln}->set('-widgets')->[$fld] if $self->{-wgbln};
 if ($wg){
    ${$wg->cget(-textvariable)} =$data;
 }

 $wg =undef;
 $wg =${$self->{-wgarr}}[$fld];
 if ($wg){
    ${$wg->cget(-textvariable)} =$data;
 }

 $self->{-dsdta}->[$self->{-dsrid}]->[$fld] =$data;
 return 1;
}

sub dsFocus {                # Set focus to current row & widget
 if    ($_[0]->{-dsrwt} && $_[0]->{-wgtbl}) {$_[0]->{-wgtbl}->Focus()}
 elsif ($_[0]->{-wgbln})                    {$_[0]->{-wgbln}->Focus()}
 elsif ($_[0]->{-dsrwd})                    {$_[0]->{-dsrwd}->focusForce()}
 $_[0];
}

sub dsReset {                # Reset data system, before retrieving; Silent
 $_[0]->{-dsdta} =[];
 $_[0]->{-dsrid} =0 if !$_[1];
 $_[0]->{-dsrd0} =[];
 return $_[0];
}

sub dsRowCount {             # Number of data rows
 return (scalar(@{$_[0]->{-dsdta}}) || 0);
}

sub dsRowDel {               # Delete current row in data system; Display
 my $self =shift;
 splice(@{$self->{-dsdta}}, $self->{-dsrid}, 1);
 $self->{-dsrid} =$#{$self->{-dsdta}} if $self->{-dsrid} >$#{$self->{-dsdta}};
 $self->{-dsrid} =0 if $self->{-dsrid} <0;
 $self->dsDisplay();
 return 1;
}

sub dsRowDta {               # Get current row data from store; Silent
 my ($self, $row) =@_;
 $row =$self->{-dsrid} if !defined($row);
 return ($self->{-dsdta}->[$row]);
}

sub dsRowFeed {              # Feed row into data system store; Silent
 return 0 if defined($_[0]->{-dsdtm}) && scalar(@{$_[0]->{-dsdta}}) >$_[0]->{-dsdtm};
 push(@{$_[0]->{-dsdta}}, $_[1]);
 return 1;
}

sub dsRowFeedAll {           # Feed all rows into data system store; Silent
  $_[0]->{-dsdta} =$_[1];
  splice(@{$_[0]->{-dsdta}},$_[0]->{-dsdtm}) if defined($_[0]->{-dsdtm});
  $_[0]->{-dsdta}
}

sub dsRowGo {                # Go to specified row in data system; Display
 my ($self, $row) =@_;
 my $tbldraw =0;
 if    (!defined($row)) {
    if    (!$self->{-wgtbl}) {}
    elsif ($self->{-dsrsd} >$self->{-dsrid}) {$self->{-dsrsd} =$self->{-dsrid}};
    $tbldraw =1 if $self->{-wgtbl};
 }
 elsif ($row eq 'next') {
    if    (!$self->{-wgtbl}) {}
    elsif ($self->{-wgtbl}->set('-rowcount')-1 >$self->{-dsrsd}
          && $self->{-dsrid} <$#{$self->{-dsdta}}) {$self->{-dsrsd}+=1}
    else  {$tbldraw =1};
    $self->{-dsrid} +=1 if $self->{-dsrid} <$#{$self->{-dsdta}};
 }
 elsif ($row eq 'prev') {
    if    (!$self->{-wgtbl}) {}
    elsif ($self->{-dsrsd} >0) {$self->{-dsrsd}-=1}
    else  {$tbldraw =1};
    $self->{-dsrid} -=1 if $self->{-dsrid} >($self->{-dsrsd}||0);
 }
 elsif ($row eq 'pgdn') {
    return $self->dsRowGo('next') if !$self->{-wgtbl} || !$self->{-dsrwt};
    return $self->dsRowGo('bot')  if $self->{-wgtbl}->set('-rowcount') >$self->dsRowCount() -$self->{-dsrid} -1;
    $self->{-dsrid} +=$self->{-wgtbl}->set('-rowcount') -1;
    $tbldraw =1
 }
 elsif ($row eq 'pgup') {
    return $self->dsRowGo('prev') if !$self->{-wgtbl} || !$self->{-dsrwt};
    return $self->dsRowGo('top')  if $self->{-wgtbl}->set('-rowcount') >$self->{-dsrid};
    $self->{-dsrid} -=$self->{-wgtbl}->set('-rowcount') -1;
    $tbldraw =1
 }
 elsif ($row eq 'top') {
    $self->{-dsrsd} =0;
    $tbldraw =1 if $self->{-wgtbl};
    $self->{-dsrid} =($self->{-dsrsd}||0);
 }
 elsif ($row eq 'bot') {
    if ($self->{-wgtbl}) {
       $self->{-dsrsd} =$self->{-wgtbl}->set('-rowcount');
       $self->{-dsrsd} =$self->dsRowCount() if $self->dsRowCount() <$self->{-dsrsd};
       $self->{-dsrsd} -=1 if $self->{-dsrsd};
       $tbldraw =1
    }
    $self->{-dsrid} =$#{$self->{-dsdta}};
 }
 else {
    if    ($row <0) { $row =0}
    elsif ($row >$#{$self->{-dsdta}}) {$row =$#{$self->{-dsdta}}}
    if    (!$self->{-wgtbl})      {}
    elsif ($self->{-dsrsd} >$row) {$self->{-dsrsd} =$row}
    $tbldraw =1 if $self->{-wgtbl};
    $self->{-dsrid} =$row;
 }
 $self->{-dsrid} =0 if $self->{-dsrid} <0;
 $self->{-dsrsd} =0 if $self->{-dsrsd} <0;
 $self->{-wgtbl}->Display() if $tbldraw;
 $self->dsDispWg();
 $self->dsFocus();
 return 1;
}

sub dsRowNew {               # Create new row in data system; Display
 my ($self, $place) =@_;
 push(@{$self->{-dsdta}}, []);
 $self->{-dsrid} =$#{$self->{-dsdta}};
 $self->{-dsrsd}+=1 if $self->{-wgtbl} && $self->{-dsrid} >0 && $self->{-wgtbl}->set('-rowcount')-1 >$self->{-dsrsd};
 $self->dsDisplay();
 $self->dsFocus();
 return 1;
}

sub dsRowUpd {               # Replace current row in data system; Display
 my ($self, $data) =@_;
 my $fld;

 $fld =-1;
 foreach my $dt (@$data) {
   $fld++;
   $self->{-dsdta}->[$self->{-dsrid}]->[$fld] =$dt;
 }

 $self->dsDisplay();

 return 1;
}



#######################
# Abstract Functions: Widget Level
#######################


sub wgFldFocusIn {           # Field got focus; internally used by ds
 my ($self, $wg, $fld, $row) =@_;
 my ($rowchg, $tblin) =(0, defined($row));
 print "wgFldFocusIn(",join(', ',map {defined($_) ? $_ : 'null'} @_),"; ",$self->dsRowCount(),")\n" if $Tk::TM::Common::Debug;
 if ($Current ne $self) {$Current =$self; $self->{-wgnav}->set(-mdedt=>$self->{-mdedt}) if ref($self->{-wgnav})}
 $wg  =$self->{-dsrwd} ||return(0) if !defined($wg);
 $fld =$self->{-dsrfd} ||0 if !defined($fld);
 $row =$self->{-dsrsd} ||0 if !defined($row);
 # print "wgFldFocusIn1($wg,$fld,$row)\n" if $Tk::TM::Common::Debug;
 if ($row ne $self->{-dsrsd}) {
   # print "wgFldFocusIn2($wg,$fld,$row -> ",$self->{-dsrsd},")\n" if $Tk::TM::Common::Debug;
   if (!$self->Stop('#save')) 
      {$self->{-dsrwd}->focusForce(); $self->wgIndicate(); return(0)}
   if ($self->{-dsrid} +$row -$self->{-dsrsd} >$self->dsRowCount()-1) 
      {ref($self->{-dsrwd}) ? $self->{-dsrwd}->focusForce() : $self->dsFocus(); return(0)};
   $self->{-dsrid} =$self->{-dsrid} +$row -$self->{-dsrsd};   
   $self->{-dsrd0} =$self->dsRowDta();
   &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
   $rowchg =1;
 }
 $self->{-dsrwd} =$wg;
 $self->{-dsrwt} =$tblin;
 $self->{-dsrfd} =$fld;
 $self->{-dsrsd} =$row;
 if ($rowchg) { $self->dsDispWg() }
 &{$self->{-cbcmd}}($self,'fdChg1','',$self->{-dsrid},$fld,$wg);
 $self->wgIndicate();
}


sub wgFldFocusOut {          # Field lost focus; internally used by ds
 my ($self, $wg, $fld, $row) =@_;
 print "wgFldFocusOut(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 if ($Current ne $self) {$Current =$self; $self->{-wgnav}->set(-mdedt=>$self->{-mdedt}) if ref($self->{-wgnav})}
 $wg  =$self->{-dsrwd} ||return(0) if !defined($wg);
 $fld =$self->{-dsrfd} ||0 if !defined($fld);
 $row =$self->{-dsrsd} ||0 if !defined($row);
 return(0) if $row ne $self->{-dsrsd} || !Exists($wg);
 my $old =${$self->{-dsrd0}}[$self->{-dsrfd} ||0];
    $old ='' if !defined($old);
 my $new =$self->dsFldDta();
    $new ='' if !defined($new);
 # print "wgFldFocusOut1($wg,f=$fld->",$self->{-dsrfd},",r=$row->",$self->{-dsrid},"; d=",$new,"->",$old,")\n" if $Tk::TM::Common::Debug;

 if ( $old ne $new ) {
     if (  !$self->{-mdedt}  
        || (  !$self->{-dsrch}
           && !&{$self->{-cbcmd}}($self,'rwUpd0','',$self->{-dsrid}))
        || !&{$self->{-cbcmd}}( $self, 'fdUpd0'
                              , ''
                              , $self->{-dsrid}
                              , $self->{-dsrfd}
                              , $self->{-dsrwd})
        || !&{$self->{-cbcmd}}( $self, 'fdUpd1'
                              , ''
                              , $self->{-dsrid}
                              , $self->{-dsrfd}
                              , $self->{-dsrwd}
                              , ${$self->{-dsrd0}}[$self->{-dsrfd}||0]
                              , $new)
        ) {
        $self->dsFldUpd( $self->{-dsrfd}
                       , ${$self->{-dsrd0}}[$self->{-dsrfd}]);
     }
     else {
        $self->{-dsrch} =1;
        $self->{-dsrnw} =1 if $self->dsRowCount()-1 <$self->{-dsrid};
        $self->dsFldUpd( $self->{-dsrfd}
                       , $new);
     }
 }
}


sub wgFldHelper {            # F4 field helper
 my ($self, $wg, $fld, $row) =@_;
 print "wgFldHelper(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 if ($Current ne $self) {$Current =$self; $self->{-wgnav}->set(-mdedt=>$self->{-mdedt}) if ref($self->{-wgnav})}
 $wg  =$self->{-dsrwd} ||return(0) if !defined($wg);
 $fld =$self->{-dsrfd} ||0 if !defined($fld);
 $row =$self->{-dsrsd} ||0 if !defined($row);
 return(0) if $row ne $self->{-dsrsd};
 if (!$self->{-dsrch}
     && !&{$self->{-cbcmd}}($self,'rwUpd0','',$self->{-dsrid})) 
    { return(0) };
 !  &{$self->{-cbcmd}}( $self, 'fdUpd0'
                             , ''
                             , $self->{-dsrid}
                             , $self->{-dsrfd}
                             , $self->{-dsrwd})
 || &{$self->{-cbcmd}}( $self, 'fdHelp'
                             , ''
                             , $self->{-dsrid}
                             , $self->{-dsrfd}
                             , $self->{-dsrwd})
}


sub wgIndicate {
 $_[0]->{-wgind}->configure(-text=>(
           '(r='   .(($_[0]->{-dsrid} ||0) +1)
           .'/'    .$_[0]->dsRowCount()
           .', c=' .(($_[0]->{-dsrfd} ||0) +1) 
           .($_[0]->{-dsrnw} ? ' New' : '')
           .($_[0]->{-dsrch} ? ' Chg' : '')
           .') ' .($_[1] ||''))
                           )
    if $_[0]->{-wgind};
 1
}


sub wgCursorWait {
 if (Exists($_[0]->{-wgscr})) {
   my $curs =$_[0]->{-wgscr}->toplevel->cget(-cursor);
   $_[0]->{-wgscr}->toplevel->configure(-cursor=>$Tk::TM::Common::CursorWait);
   $_[0]->{-wgscr}->toplevel->update;
   $_[0]->{-wgscr}->toplevel->configure(-cursor=>$curs);
 }
}


#######################
# Abstract Functions: Outside used commands
#######################


sub Action {                 # Execute action
 my ($self, $act) =@_;
 print "Action(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 &{$self->{-cbcmd}}( $self, 'usAct'
                              , $act
                              , $self->{-dsrid}  ||0
                              , $self->{-dsrfd}  ||0
                              , $self->{-dsrwd}  ||'')
}


sub Clear {                  # Clear all data in data system
 my ($self, $opt) =@_;
 print "Clear(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->Stop(($opt||'') .'#end') || return 0;
 $self->dsReset(); 
 $self->dsRowGo('top');
 $self->{-dsrd0} =$self->dsRowDta();
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
 return 1;
}


sub Display {                # Display data
 $_[0]->dsDisplay() && $_[0]->wgIndicate();
}


sub Export {                 # Export Data
 my $self =shift;
 print "Export(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 return 0 if !$self->Stop('');
 &{$self->{-cbcmd}}($self,'doExport',@_)
}


sub Find   {                 # Find Data
 my ($self, $find) =@_;
 print "Find(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 return(0) if !$self->Stop('');
 eval('use Tk::TM::wDialogBox');
 my $sch  =(defined($find) ? $find : $Search);
 my $dbox =$self->{-wgscr}->toplevel->tmDialogBox
           (-title=>Tk::TM::Lang::txtMsg('Find')
           ,-buttons=>[Tk::TM::Lang::txtMsg('Find')
                      ,Tk::TM::Lang::txtMsg('Cancel')]);
 my $wg =$dbox->add('Entry',-textvariable=>\$sch)->pack(-fill=>'x');
 $wg->icursor('end');
 $wg->selectionRange(0,'end');
 return(0) if $dbox->Show() !=0;
 $Search  =$sch;
 $self->FindNxt(0);
}


sub FindNxt {                # Find Data Again
 my ($self,$offs) =@_;
 print "FindNxt(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 return(0) if !$self->Stop('');
 $self->wgCursorWait;
 $offs =1 if !defined($offs);
 my $col =$self->{-dsrfd};
 my $mrg =$self->dsRowCount() -1;
 my $cur =$self->{-dsrid} +$offs;
 eval("while (\$cur <=\$mrg && \$self->dsRowDta(\$cur)->[\$col] !~/$Search/i) {\$cur +=1}");
 if ($cur >$mrg) {$self->{-wgscr}->toplevel->bell; return(0)};
 $self->RowGo($cur);
}


sub Import {                 # Import Data
 my $self =shift;
 print "Import(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 return 0 if !$self->Stop('') || !$self->Clear('');
 &{$self->{-cbcmd}}($self,'doImport',@_)
}


sub Print {                  # Print Data
 my $self =shift;
 print "Print(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 return 0 if !$self->Stop('');
 &{$self->{-cbcmd}}($self,'doPrint',@_)
}


sub Retrieve {               # Retrieve data into data system
 my ($self,$opt) =@_;
 print "Retrieve(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $opt =$opt ||'';
 $self->Stop($opt) || return 0;
 my $row =$self->{-dsrid};
 $self->dsReset();
 &{$self->{-cbcmd}}($self,'dbRead','') || return 0;
 $self->dsRowGo($opt =~/reread/i ? $row : 'top');
 $self->{-dsrd0} =$self->dsRowDta();
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
 return 1;
}


sub RowDel {                 # Delete current row
 my $self =shift;
 print "RowDel($self; ",$self->{-dsrid},")\n" if $Tk::TM::Common::Debug;
 $self->{-mdedt} || return(0);
 my $ret =$self->Stop('#save');
 return 0 if !$ret;
 return 1 if $ret ==2;
 &{$self->{-cbcmd}}($self,'rwDel0','',$self->{-dsrid}) || return 0;
 &{$self->{-cbcmd}}($self,'dbDel','',$self->{-dsrid},undef,undef,$self->dsRowDta()) || return 0;
 $self->dsRowDel();
 $self->{-dsrd0} =$self->dsRowDta();
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
 return 1;
}   	


sub RowGo {                  # Go to specified row
 my ($self, $row) =@_;
 print "RowGo(",join(', ',map {defined($_) ? $_ : 'null'} @_),"; ",$self->{-dsrid},")\n" if $Tk::TM::Common::Debug;
 my $ret =$self->Stop('#save');
 return 0 if !$ret;
 if (!($row eq 'next' && $ret ==2)) {
    $self->dsRowGo($row);
    $self->{-dsrd0} =$self->dsRowDta();
 }
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
 return 1;
}


sub RowNew {                 # Create new row in given place
 my $self =shift;
 print "RowNew($self)\n" if $Tk::TM::Common::Debug;
 $self->{-mdedt} || return(0);
 return 0 if !$self->Stop('#save');
 &{$self->{-cbcmd}}($self,'rwIns0','') || return 0;
 $self->dsRowNew(@_);
 $self->{-dsrnw} =1;
 &{$self->{-cbcmd}}($self,'rwIns1',$self->{-dsrid});
 $self->{-dsrd0} =$self->dsRowDta();
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
 return 1;
}


sub RowUndo {                # Undo current row
 my ($self, $opt) =@_;
 print "RowUndo(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->{-mdedt} || return(0);
 $self->Stop($opt .'#undo') || return 0;
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
}


sub Save {                   # Save data if changed
 my ($self, $opt) =@_;
 print "Save(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->{-mdedt} || return(0);
 $self->Stop(($opt||'') .'#save') || return 0;
 &{$self->{-cbcmd}}($self,'rwChg1','',$self->{-dsrid});
 $self->wgIndicate();
}


sub Sleep  {                 # Free data system, Retrieve - ups.
 my ($self, $opt) =@_;
 print "Sleep(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->Stop(($opt||'') .'#force#end') || return 0;
 if ($opt =~/wgs/i) {
    $self->{-wgtbl}->destroy if Exists($self->{-wgtbl});
    $self->{-wgbln}->destroy if Exists($self->{-wgbln});
    grep {$_->destroy if Exists($_)} @{$self->{-wgarr}};
    $self->{-wgtbl} =undef;
    $self->{-wgbln} =undef;
    $self->{-wgarr} =[];
    $self->{-wgind} =undef;
    $self->{-dsrwd} =undef;
 }
 if ($opt =~/dta/i || !$opt) {
    $self->dsReset(1); 
 }
 1;
}


sub Stop {                   # Stop editing data if any
 my ($self, $opt) =@_;
 print "Stop(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 $self->wgFldFocusOut();
 # print "Stop1(",join(', ',map {defined($_) ? $_ : 'null'} @_),"; ", $self->{-dsrid}, ", ", $self->{-dsrnw}, ", ", $self->{-dsrch},")\n" if $Tk::TM::Common::Debug;
 $self->{-dsrnw} || &{$self->{-cbcmd}}($self,'rwChg0',$opt,$self->{-dsrid}) || return 0;
                      # Traverse for update
 if (!$self->{-dsrch} && !$self->{-dsrnw}) {
    &{$self->{-cbcmd}}($self,'doEnd',$opt,$self->{-dsrid},undef,undef,$self->dsRowDta()) if $opt=~/end/;
    return 1
 }
 if (   $self->{-dsrnw} 
    && !$self->{-dsrch}) {
    return 2 if $self->dsRowCount() <2;
    $self->{-dsrch} =0;
    $self->{-dsrnw} =0;
    if ($opt=~/end/i) {
       &{$self->{-cbcmd}}($self,'doEnd',$opt,$self->{-dsrid},$self->dsRowDta());
       return 1
    }
    $self->dsRowDel();
    $self->{-dsrd0} =$self->dsRowDta();
    $self->wgIndicate();
    return 2
 }
 if ($opt=~/undo/i) { # In doubt
    $self->{-dsrch} =0;
    $self->{-dsrnw} =0;
    if ($opt=~/end/i) {
       &{$self->{-cbcmd}}($self,'doEnd',$opt,$self->{-dsrid},$self->dsRowDta());
       return 1
    }
    $self->dsRowUpd($self->{-dsrd0});
    $self->wgIndicate();
    return 1;
 }
 if ($opt!~/save/i) {
    my $reply =$self->StopMsgBox($opt);
    return 0 if $reply =~/c/i && $opt !~/force/i;
    if ($reply =~/[nc]/i) {
       eval {$_[1] =$opt =$opt ."#undo"};
       $self->{-dsrch} =0;
       $self->{-dsrnw} =0;
       if ($opt=~/end/i) {
          &{$self->{-cbcmd}}($self,'doEnd',$opt,$self->{-dsrid},$self->dsRowDta());
          return 1
       }
       $self->dsRowUpd($self->{-dsrd0});
       $self->wgIndicate();
       return 1;
    }
    eval {$_[1] =$opt =$opt ."#save"};
 }
 $self->wgCursorWait;
 &{$self->{-cbcmd}}( $self
                   , $self->{-dsrnw} ? 'dbIns' : 'dbUpd'
                   , $opt
                   , $self->{-dsrid}
                   , undef, undef
                   , $self->{-dsrd0}
                   , $self->dsRowDta() # sync scr may be
                   ) || return 0;
 !$self->{-dsrnw} || &{$self->{-cbcmd}}($self,'rwChg0',$opt,$self->{-dsrid}) || return 0;
                      # Traverse for Insert
 &{$self->{-cbcmd}}( $self
                   , 'rwUpd1'
                   , $opt
                   , $self->{-dsrid}
                   , undef, undef
                   , $self->{-dsrd0}
                   , $self->dsRowDta() # sync scr may be
                   ) || return 0;
 $self->{-dsrch} =0;
 $self->{-dsrnw} =0;
 $self->{-dsrd0} =$self->dsRowDta();
 $self->wgIndicate();
 &{$self->{-cbcmd}}( $self,'doEnd',$opt,$self->{-dsrid},$self->dsRowDta()) if $opt=~/end/;
 return 1;
}


sub StopMsgBox {             # MessageBox 'Save Changes?'; Internally used in 'Stop'
 my ($self, $opt) =@_;
 my $ret;
 $ret =$self->{-wgscr}->
            messageBox('-icon'   => 'question'
                      , -type    => ($opt=~/force/i ? 'YesNo' : 'YesNoCancel')
                      , -title   => Tk::TM::Lang::txtMsg('Save changes?')
                      , -message => Tk::TM::Lang::txtMsg('Data was modified') .', ' .Tk::TM::Lang::txtMsg('Save changes?'));
 $ret =substr(lc($ret), 0, 1);
 $ret =~tr/c/n/ if $opt=~/force/i;
 return $ret;
}



#######################
# Abstract Functions: Implementations
#######################


sub doDefault {              # Template of User-defined function
 my ($self, $cmd, $opt, $row, $fld, $wg, $dta, $new) =(shift, shift, @_);

 print "**CB($self, $cmd, ", join(", ", map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 if ($self->{"-cb${cmd}"}) {
    my $sub =$self->{"-cb${cmd}"};
    return(&$sub($self,@_))
 }

 if    ($cmd eq 'fdChg1')   { # goto field
 }
 elsif ($cmd eq 'fdHelp')   { # F4 field helper
 }
 elsif ($cmd eq 'fdUpd0')   { # modify field? immediate before 'fdUpd1'
 }
 elsif ($cmd eq 'fdUpd1')   { # field modified: accept changes?
 }
 elsif ($cmd eq 'rwChg0')   { # change row? save details
 }
 elsif ($cmd eq 'rwChg1')   { # row changed: retrieve details
 }
 elsif ($cmd eq 'rwDel0')   { # delete row?
 }
 elsif ($cmd eq 'rwIns0')   { # insert row? save masters
 }
 elsif ($cmd eq 'rwIns1')   { # row created: fill default values
 }
 elsif ($cmd eq 'rwUpd0')   { # update row?
 }
 elsif ($cmd eq 'rwUpd1')   { # row updated or inserted: SQL reselectrow
 }
 elsif ($cmd eq 'dbRead')   { # SQL select
 }
 elsif ($cmd eq 'dbIns')    { # SQL insert
 }                       
 elsif ($cmd eq 'dbUpd')    { # SQL update
 }
 elsif ($cmd eq 'dbDel')    { # SQL delete
 }
 elsif ($cmd eq 'doEnd')    { # end using data object
 }
 elsif ($cmd eq 'doExport') { # export data to file
   return($self->doExport(@_))
 }
 elsif ($cmd eq 'doImport') { # import data from file
   return($self->doImport(@_))
 }
 elsif ($cmd eq 'doPrint') {  # print data
   return($self->doPrint(@_))
 }
 return 1;
}


sub doExport {               # Export Data
 my ($self, $file, $fmt) =@_;
 if (!$file) {
    eval('use Tk::FileSelect');
    $file =$self->{-wgscr}->toplevel->getSaveFile(-title=>Tk::TM::Lang::txtMsg('Save data into file'),-defaultextension=>'.txt');
    return('') if !$file;
 }
 local *OUT;
 open(OUT, ">$file") || ($self->{-wgscr}->messageBox(-icon=>'error',-type=>'Ok',-title=>Tk::TM::Lang::txtMsg('Error'),-message=>(Tk::TM::Lang::txtMsg('Opening') ." >$file: $!")), return('')); 
 for (my $rowno =0; $rowno <$self->dsRowCount(); $rowno++) {
   my $row ='';
   foreach my $flddta (@{$self->dsRowDta($rowno)}) {
      $row =$row .$flddta ."\t";
   }
   print(OUT $row, "\n") || ($self->{-wgscr}->messageBox(-icon=>'error',-type=>'Ok',-title=>Tk::TM::Lang::txtMsg('Error'),-message=>(Tk::TM::Lang::txtMsg('Writing') ." >$file: $!")), return(''));
 }
 close(OUT)          || ($self->{-wgscr}->messageBox(-icon=>'error',-type=>'Ok',-title=>Tk::TM::Lang::txtMsg('Error'),-message=>(Tk::TM::Lang::txtMsg('Closing') ." >$file: $!")), return(''));
 return($file);
}


sub doImport {               # Import Data
 my ($self, $file, $fmt) =@_;
 if (!$file) {
    eval('use Tk::FileSelect');
    $file =$self->{-wgscr}->toplevel->getOpenFile(-title=>Tk::TM::Lang::txtMsg('Load data from file'),-defaultextension=>'.txt');
    return('') if !$file;
 }
 local *IN;
 open(IN, "<$file") || ($self->{-wgscr}->messageBox(-icon=>'error',-type=>'Ok',-title=>Tk::TM::Lang::txtMsg('Error'),-message=>(Tk::TM::Lang::txtMsg('Opening') ." <$file: $!")), return('')); 

 while (!eof(IN)) {
    my $row =<IN>;
    if (!defined($row)) {
       $Error =(Tk::TM::Lang::txtMsg('Reading') ." <$file: $!");
       last;
    }
    chomp($row);
    $self->dsRowFeed([split(/\t/, $row)]);
    $self->{-dsrid}  =$self->dsRowCount() -1;
    $self->{-dsrnw}  =1;
    $self->{-dsrch}  =1;
    next if $self->Stop('#save#silent');
    $self->{-dsrnw}  =0;
    $self->{-dsrch}  =1;
    $self->{-dsrd0}  =$self->dsRowDta();
    next if $self->Stop('#save#silent');
    $self->{-dsrnw}  =1;
    $self->{-dsrch}  =0;
    $self->dsRowDel();
    last;
 }

 $self->RowGo('bot');
 close(IN) || ($Error =$Error || (Tk::TM::Lang::txtMsg('Closing') ." >$file: $!"));
 $Error && $self->{-wgscr}->messageBox(-icon=>'error',-type=>'Ok',-title=>Tk::TM::Lang::txtMsg('Error'),-message=>$Error);
 return ($Error ? '' : $file);
}


sub doPrint {                # Print Data
 my ($self, $file, $fmt) =@_;
 $self->{-wgscr}->
           messageBox(-icon   => 'info'
                     ,-type   => 'Ok'
                     ,-title  => Tk::TM::Lang::txtMsg('Pardon')
                     ,-message=> Tk::TM::Lang::txtMsg('Function not released'));
 return('');
}


#######################
# Abstract Functions: Useful methods
#######################


sub DBICmd {                 # DBI Command execution
 my $self =shift;
 print "DBICmd($self; ",join(';',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 my $dbh =($_[0] =~/^DBI:/i ? shift : $self->{-dbh} ? $self->{-dbh} : $Tk::TM::Common::DBH);
 return(0) if !$dbh;
 my $opt =($_[0] =~/^#/i || $_[0] eq '' ? shift : '');
 my $ret =1;
 my $err ='';
 $Error  ='';

 $self->wgCursorWait;

 CMD:
 my $cmd =shift || 'commit';

 SQL:
 my $sql ='';
 my $sqx =0;
 if    ($cmd =~/^selectrow (.*)/i)          {$sql ='select '.$1; $cmd ='selectrow_arrayref'; $sqx =1}
 elsif ($cmd =~/^select /i)                 {$sql =$cmd; $cmd ='selectall_arrayref'; $sqx =2}
 elsif ($cmd =~/^(insert|update|delete) /i) {$sql =$cmd; $cmd ='do'}
 elsif ($cmd !~/^(commit|rollback)/i)       {$sql =shift}

 if (ref($_[0]) =~/array/i && $dbh->{AutoCommit}) {eval {$dbh->{AutoCommit} =0}}

 print "$sql\n" if $Tk::TM::Common::Echo;

 my $rv;
 if ($sqx ==2) {
    my $dbs =$dbh->prepare($sql);
    $dbs->execute(ref($_[0]) =~/array/i ? @{$_[0]} : @_);
    $rv =$dbs->fetchall_arrayref;
    if ($rv) {
       $self->{-dbfds} =[];
       $self->{-dbfnm} ={};
       eval {
          for (my $i =$[; $i <$dbs->{NUM_OF_FIELDS} +$[; $i++) {
             $self->{-dbfnm}->{$dbs->{NAME}->[$i]} =$i;
             my $dsc ={};
             eval {$dsc->{NAME}      =$dbs->{NAME}->[$i]};
             eval {$dsc->{TYPE}      =$dbs->{TYPE}->[$i]};
             eval {$dsc->{SCALE}     =$dbs->{SCALE}->[$i]};
             eval {$dsc->{PRECISION} =$dbs->{PRECISION}->[$i]};
             eval {$dsc->{NULLABLE}  =$dbs->{NULLABLE}->[$i]};
             push(@{$self->{-dbfds}}, $dsc);
          }
       }
    }
 }
 else {
    $rv  =(ref($cmd) 
          ? &$cmd($dbh) 
          : !$sql
            ? $dbh->$cmd()
            : $dbh->$cmd($sql, ref($_[0]) =~/array/i ? @{$_[0]} : @_)
          )
 }

 if    (!$sqx)                {$ret =$ret ? $rv : $ret}
 elsif ($cmd =~/^selectrow/i) {$ret =$ret ? $self->dsRowUpd($rv) : $ret}
 elsif ($cmd =~/^selectall/i) {$ret =$ret ? $self->dsRowFeedAll($rv) : $ret}

 $Error = $err = $err || $dbh->errstr || $dbh->err;

 if (ref($_[0]) =~/array/i) {
    shift;
    if ($err) {$cmd ='rollback'; goto SQL}
    goto CMD;
 }

 if ($cmd =~/^(commit|rollback) /i && !$dbh->{AutoCommit}) {eval {$dbh->{AutoCommit} =1}};
 if    (!$err)           {}
 elsif ($opt =~/#silent/i) {}
 else  {
    $self->{-wgscr}->
           messageBox(-icon   => 'error'
                     ,-type   => 'Ok'
                     ,-title  => Tk::TM::Lang::txtMsg('Error')
                     ,-message=> $err);
 }
 $ret;
}



sub DBIHlp {                 # DBI entry helper screen
 my $self =shift;
 print "DBIHlp($self; ",join(';',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;

 $self->wgCursorWait;

 my $cmd  =(ref($_[0]) ? '' : shift);
 my $do   =new Tk::TM::DataObject(-mdedt=>0);
 if ($cmd) {$do->DBICmd($cmd,@{$_[0]})}
 else      {$do->dsRowFeedAll($_[0])}
 if (!$do->dsRowCount) {$do->destroy(); return(0)};

 my $colcount =scalar($#{$do->dsRowDta(0)});
 my $colspecs =[];
 foreach (my $i=@[; $i<=$colcount; $i++) {
   push(@$colspecs, ['','Entry']);
 }

 eval('use Tk::TM::wDialogBox');
 my $dlg  =$self->{-wgscr}->tmDialogBox
    (-title=>Tk::TM::Lang::txtMsg('Choose')
    ,-buttons=>[Tk::TM::Lang::txtMsg('Ok')
               ,Tk::TM::Lang::txtMsg('Cancel')]);
 $dlg->add('tmActionBar',-mdnav=>1,-dos=>[$do])->pack(-anchor=>'nw');
 my $tbl  =$dlg->add('tmTable'
                    ,-rowcount=>($do->dsRowCount()>10 ? 10 : $do->dsRowCount())
                    ,-colspecs=>$colspecs)->pack(-anchor=>'w');
 $do->RowGo('top');
 $do->set(-wgtbl=>$tbl)->Display();
 $tbl->Focus();
 if ($dlg->Show()!=0) {$do->destroy(); return(0)};

 my $dta =$do->dsRowDta();
 $self->{-dsrch} =1;
 if (!ref($_[1])) {
    $self->dsFldUpd(undef, $dta->[0])
 }
 else {
    foreach my $inc (@{$_[1]}) {
      $self->dsFldUpd($self->{-dsrfd} +$inc, $dta->[0])      
    }
 }
 $do->destroy();
 1;
}

