#!perl -w

use Tk::TM::Lib;
$Tk::TM::Common::Debug =1;
#$Tk::TM::Common::Edit =0;
#$Tk::TM::Lang::Lang ='ru';

my $mw  =new Tk::MainWindow;

#my $mnu =$mw->tmActionBar()->form;
my $mnu =$mw->tmMenu(-mdmnu=>'button');
$mnu->setActions('x1','x2','x3');

my $tbl =$mw->tmTable(-rowcount=>3, -colspecs=>
                       [['col1','Entry']
                       ,['col2','Entry']
                       ,['col3','Entry']]
                     )->form(-t=>$mnu);

my $bln =$mw->tmBlank(-wgspecs=>
                       [['col1','Entry']
                       ,["col2",'Entry']
                       ,['col3',"Entry",-width=>30]]
                    )->form(-t=>$tbl);

#my $e0 =$mw->Entry()->form(-t=>$bln);
#my $e1 =$mw->Entry()->form(-t=>$e0);
#my $e2 =$mw->Entry()->form(-t=>$e1);

my $sub =sub{$_[0]->dsRowFeedAll(
                 [['r1c1', 'r1c2', 'r1c3']
                 ,['r2c1', 'r2c2', 'r2c3']
                 ,['r3c1', 'r3c2', 'r3c3']
                 ,['r4c1', 'r4c2', 'r4c3']
                 ,['r5c1', 'r5c2', 'r5c3']
                 ]);
            };

#$mnu->set(-dos=>[new Tk::TM::DataObject(-cbdbRead=>$sub, -wgarr=>[$e0, $e1, $e2], -wgtbl=>$tbl)]);
#$mnu->set(-dos=>[new Tk::TM::DataObject(-cbdbRead=>$sub, -wgbln=>$bln, -wgtbl=>$tbl)]);
new Tk::TM::DataObject(-cbdbRead=>$sub, -wgbln=>$bln, -wgtbl=>$tbl);

$mnu->Retrieve();

Tk::MainLoop;
