#!perl -w
#
# Tk Transaction Manager.
# Application window.
#
# makarow, demed
#

use Tk::TM::Lib;

package Tk::TM::wApp;
require 5.000;
use strict;
require Exporter;
use Tk::Tree;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = ('Tk::MainWindow');
@EXPORT_OK = qw(DBILogin);

my $PathLast ='0';
my $PathOpen =undef;

1;


#######################
sub new {
 my $class=shift;
 my $self =new Tk::MainWindow(@_);
 bless $self,$class;
 $self->initialize(@_);

}


#######################
sub initialize {
 my $self = shift;

 my $tmp =$self->Menubutton();
 my $fnt =$tmp->cget(-font);
          $tmp->destroy;

 $self->{-wgmnu} =$self->tmMenu()->pack(-fill=>'x');
 $self->{-wgmnu}->set(-dos=>[]);
 my $area =$self->Frame()->pack(-expand=>'yes',-fill=>'both');

 $self->{-wglst} =$area->Scrolled('Tree',-scrollbars=>'se',-font=>$fnt
                                 ,-itemtype=>'text'
                                 ,-command=>sub{$self->ScrOpen(@_)}
                               # ,-cursor=>'hand2'
                                 )->pack(-fill=>'y',-side=>'left');
 $self->{-wgscr} =$area->Frame()->pack(-expand=>'yes',-fill=>'both');
 $self->{-wgscr}->configure(-borderwidth=>2,-relief=>'groove');
 $self->{-title} =$self->cget(-title);

 $self->{-mdlst} ='tree';
 $self->{-parm}  ={}; $self->{-wgmnu}->set(-parm => $self->{-parm});

 $self->ConfigSpecs(-font=>['DESCENDANTS']);
 $self->ConfigSpecs(-relief=>['CHILDREN']);
 $self->ConfigSpecs(-background=>['CHILDREN']);
 $self->ConfigSpecs(-foreground=>['CHILDREN']);

 $self;
}

#######################
sub set {
 return(keys(%{$_[0]})) if scalar(@_) ==1;
 return($_[0]->{$_[1]}) if scalar(@_) ==2;
 my ($self, %opt) =@_;
 foreach my $k (keys(%opt)) {
  $self->{$k} =$opt{$k};
 }
 $self;
}


#######################
sub setscr {
 my ($self, $op, $lbl, $sub, $opt) =@_;
 if (!defined($op) ||$op eq '') {
    $PathLast =$PathLast =~/^(.*)\.([^\.]+)$/ ? "$1." .($2 +1) : $PathLast +1
 }
 elsif ($op eq '+') {
    eval {$self->{-wglst}->setmode($PathLast,'open'); $self->{-wglst}->open($PathLast)};
    $PathLast =$PathLast .'.0'
 }
 elsif ($op =~/^\d/) {
    my @a =split(/\./, $PathLast); 
    eval {$self->{-wglst}->setmode($PathLast,'open'); $self->{-wglst}->open($PathLast)} 
         if $#a <$op;
    $a[$op] +=1; 
    $PathLast =join('.',@a[0..$op])
 }
 if ($lbl =~/^Login$/ && !ref($sub)) {
     $lbl =Tk::TM::Lang::txtMsg($lbl);
     $sub =\&DBILogin;
 }
 $self->{-wglst}->add($PathLast
                     ,-text=>$lbl
                     ,-data=>{-cbcmd=>$sub
                             ,-cbnme=>$sub
                             ,-label=>$lbl
                             ,-title=>''
                             ,-opt=>(ref($opt) ? $opt : {})
                             ,-parm=>{}
                             ,-dos=>undef
                             ,-wgapp=>$self
                             ,-wgmnu=>$self->{-wgmnu}
                             ,-wgscr=>$self->{-wgscr}});
}

#######################
sub ScrOpen {
 print "ScrOpen(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 my ($self, $pth1) =@_;
 my $dta1 =$self->{-wglst}->info('data',$pth1);
 my $pthM =($pth1 =~/^(.*)\.([^\.]+)$/ ? $1 : undef);
 my $dtaM =(defined($pthM) ? $self->{-wglst}->info('data',$pthM) : undef);
 my $pth0 =$PathOpen;
 my $dta0 =(defined($pth0) ? $self->{-wglst}->info('data',$pth0) : undef);

 if (defined($pthM) && !defined($dtaM->{-cbcmd})) {
    undef($pthM); undef($dtaM)
 }
 if (defined($pth0) && $pth0 eq $pth1 ) {
    return($pth0)
 }
 if ($self->{-mdlst} =~/tree/i && defined($pthM) && !ref($dtaM->{-dos})) {
    return($pth0)
 }
 if (defined($pth0)) {
    $self->{-wgmnu}->Stop('#save#force') || return($pth0);
    my $stp =!ref($dta0->{-cbcmd}) || &{$dta0->{-cbcmd}}($dta0,'stop','',$dta1);
    return($pth0) if !$stp && substr($pth1,0,length($pth0)) eq $pth0;
    $self->{-wgmnu}->doAll(sub{shift->Sleep('#wgs')});
    if (defined($pthM) && $pth0 ne $pthM || $self->{-mdlst} !~/tree/i) {
       $self->{-wgmnu}->doAll(sub{shift->Sleep('#dta')})
    }
 }
 foreach my $w ($self->{-wgscr}->children) { 
   $w->destroy 
 }
 if ($self->{-mdlst} =~/tree/i
    && defined($pthM) && defined($pth0) && $pth0 ne $pthM) {
    $self->{-wgmnu}->set(-dos=>($dtaM->{-dos} ? $dtaM->{-dos} : []));
    $self->{-wgmnu}->Reread();
    $dta0 =$dtaM;
 }

 $self->{-wgmnu}->set(-dos=>(ref($dta1->{-dos}) ? $dta1->{-dos} : []));
 if   (!ref($dta1->{-cbcmd})) {}
 else                         {&{$dta1->{-cbcmd}}($dta1,'start','',$dta0)}

 if (ref($dtaM) && ref($dtaM->{-dos})) { foreach my $do (@{$dtaM->{-dos}}) { $do->Sleep('#dta') } }
 $self->{-wgmnu}->set(-dos=>(ref($dta1->{-dos}) ? $dta1->{-dos} : []));
 $self->configure(-title=>($self->{-title} .' - ' .$dta1->{-label} .($dta1->{-title} ne '' ? ' - ' .$dta1->{-title} : '')));
 $PathOpen =$pth1
}


#######################
sub Start {
 my $self  =shift;
 my @chld  =$self->{-wglst}->info('children');
 $PathOpen =$chld[0];
 my $dta   =$self->{-wglst}->info('data',$PathOpen);
 my $sub   =$dta->{-cbcmd};
 &$sub($dta,'start','');
 $self->{-wgmnu}->set(-dos=>(ref($dta->{-dos}) ? $dta->{-dos} : []));
 $self->configure(-title=>($self->{-title} .' - ' .$dta->{-label} .($dta->{-title} ne '' ? ' - ' .$dta->{-title} : '')));
}


#######################
sub DBILogin {
 print "DBILogin(",join(', ',map {defined($_) ? $_ : 'null'} @_),")\n" if $Tk::TM::Common::Debug;
 my ($self, $cmd) =@_;

 my $scr  =$self->{-wgscr};
 my $opt  =$self->{-opt};
 my $dsn  =$opt->{-dsn};
 my $usr  =$opt->{-usr};
 my $psw  =$opt->{-psw};
 my $dbopt=$opt->{-dbopt};
 my $rsp  ='';
 my $dbh  =undef;

 return($Tk::TM::Common::DBH) if $cmd !~/start/;

 eval('use DBI');
 my $dsnlb =$scr->Label(-text=>Tk::TM::Lang::txtMsg('Database'))
                ->grid(-row=>0, -column=>0, -sticky=>'w');
 my $dsnfd =$scr->Entry(-textvariable=>\$dsn)
                ->grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'we');
            $dsnfd->configure(-state=>'disabled', -bg=>$scr->cget(-bg)) if !$opt->{-edit};
 my $usrlb =$scr->Label(-text=>Tk::TM::Lang::txtMsg('User'))
                ->grid(-row=>1, -column=>0, -sticky=>'w');
 my $usrfd =$scr->Entry(-textvariable=>\$usr)
                ->grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'we');
 my $pswlb =$scr->Label(-text=>Tk::TM::Lang::txtMsg('Password'))
                ->grid(-row=>2, -column=>0, -sticky=>'w');
 my $pswfd =$scr->Entry(-textvariable=>\$psw,-show=>'*')
                ->grid(-row=>2, -column=>1, -columnspan=>2, -sticky=>'we');
 my $rspfd =$scr->Entry(-textvariable=>\$rsp, -state=>'disabled', -bg=>$scr->cget(-bg))
                ->grid(-row=>3, -column=>0, -columnspan=>3, -sticky=>'we');
 my $btnok =$scr->Button(-text=>Tk::TM::Lang::txtMsg('Ok')
                        ,-command=>
                           sub{$self->{-wgmnu}->CursorWait;
                               $rsp ='Connecting...';
                               if (eval{$dbh =DBI->connect($dsn,$usr,$psw,$dbopt)}) 
                                    {$rsp ='Connected'; 
                                     eval {$opt->{-dsn} =$dsn};
                                     eval {$opt->{-usr} =$usr};
                                     eval {$opt->{-psw} =$psw};
                                     $Tk::TM::Common::DBH =$dbh;
                                    }
                               else {$rsp =$DBI::errstr}
                              }
                        )
                ->grid(-row=>4, -column=>1, -sticky=>'we');
 my $btncn =$scr->Button(-text=>Tk::TM::Lang::txtMsg('Cancel')
                        ,-command=>sub{exit})
                ->grid(-row=>4, -column=>2, -sticky=>'we');
# $scr->bind('<Key-Return>',sub{$btnok->invoke});
# $scr->bind('<Key-Escape>',sub{$btncn->invoke});

 $self->{-dos} =[];
}