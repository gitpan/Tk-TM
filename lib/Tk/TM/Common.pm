#!perl -w
#
# Tk Transaction Manager.
# Common.
#
# makarow, demed
#

package Tk::TM::Common;
require 5.000;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(DBILogin);

use vars qw($Debug $Edit $Echo $DBH $Help $About $CursorWait);
$Debug      =0;       # debug level or switch
$Echo       =1;       # echo printing
$Edit       =1;       # default edit mode enabled
$DBH        =undef;   # DBI database Handle
$Help       =undef;   # 'Help' array ref or sub ref
$About      =undef;   # 'About' array ref or sub ref
$CursorWait ='watch'; # Wait cursor type

1;


sub DBILogin {
 my ($dsn, $usr, $psw, $opt, $dbopt) =@_;
    $opt  =$opt   ||'';
    $dbopt=$dbopt || {};
 my $rsp ='';
 my $dbh;
 eval('use DBI');
 my $dlg   =new Tk::MainWindow(-title=>Tk::TM::Lang::txtMsg('Login')); 
 my $dsnlb =$dlg->Label(-text=>Tk::TM::Lang::txtMsg('Database'))
                ->grid(-row=>0, -column=>0, -sticky=>'w');
 my $dsnfd =$dlg->Entry(-textvariable=>\$dsn)
                ->grid(-row=>0, -column=>1, -columnspan=>2, -sticky=>'we');
            $dsnfd->configure(-state=>'disabled', -bg=>$dlg->cget(-bg)) if $opt !~/dsn/i;
 my $usrlb =$dlg->Label(-text=>Tk::TM::Lang::txtMsg('User'))
                ->grid(-row=>1, -column=>0, -sticky=>'w');
 my $usrfd =$dlg->Entry(-textvariable=>\$usr)
                ->grid(-row=>1, -column=>1, -columnspan=>2, -sticky=>'we');
 my $pswlb =$dlg->Label(-text=>Tk::TM::Lang::txtMsg('Password'))
                ->grid(-row=>2, -column=>0, -sticky=>'w');
 my $pswfd =$dlg->Entry(-textvariable=>\$psw,-show=>'*')
                ->grid(-row=>2, -column=>1, -columnspan=>2, -sticky=>'we');
 my $rspfd =$dlg->Entry(-textvariable=>\$rsp, -state=>'disabled', -bg=>$dlg->cget(-bg))
                ->grid(-row=>3, -column=>0, -columnspan=>3, -sticky=>'we');
 my $btnok =$dlg->Button(-text=>Tk::TM::Lang::txtMsg('Ok')
                        ,-command=>
                           sub{$rsp ='Connecting...';
                               my $curs =$dlg->cget(-cursor);
                               $dlg->configure(-cursor=>$CursorWait);
                               $dlg->update;
                               $dlg->configure(-cursor=>$curs);
                               if ($dbh =DBI->connect($dsn,$usr,$psw,$dbopt)) 
                                    {$rsp ='Connected'; 
                                     eval {$_[0] =$dsn};
                                     eval {$_[1] =$usr};
                                     eval {$_[2] =$psw};
                                     $dlg->destroy}
                               else {$rsp =$DBI::errstr}
                              }
                        )
                ->grid(-row=>4, -column=>1, -sticky=>'we');
 my $btncn =$dlg->Button(-text=>Tk::TM::Lang::txtMsg('Cancel')
                        ,-command=>sub{if($opt =~/return/i) {$dlg->destroy} else {exit}})
                ->grid(-row=>4, -column=>2, -sticky=>'we');
 $dlg->bind('<Key-Return>',sub{$btnok->invoke});
 $dlg->bind('<Key-Escape>',sub{$btncn->invoke});
 if ($opt =~/center/i) {
    $dlg->update;
    $dlg->geometry('+'.int(($dlg->screenwidth() -$dlg->width())/2.2) 
                  .'+'.int(($dlg->screenheight() -$dlg->height())/2.2));
 }
 $dlg->grab;
 $dlg->focusForce;
 $pswfd->focusForce;
 Tk::MainLoop();
 $opt =~/return/i ? $dbh : $DBH =$dbh;
}