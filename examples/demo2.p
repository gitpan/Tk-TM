#!perl -w

use Tk::TM::wApp;
use DBI;
#$Tk::TM::Common::Debug =1;
#$Tk::TM::Lang::Lang ='ru';

my $mw  =new Tk::TM::wApp();

# $mw->setscr(0,'Login',undef,{-dsn=>'DBI:XBase:.',-edit=>1});
$mw->setscr(0,'Drivers',\&Drivers);
$mw->setscr(1,'Data Sources',\&DataSources);
$mw->setscr(2,'Login',\&Login, {-edit=>1});
$mw->setscr(3,'Tables',\&Tables);
$mw->setscr(4,'Data',\&Datas);
$mw->setscr(4,'Description',\&Descriptions);
$mw->setscr(0,'Exit!',sub{exit});
$mw->Start();

Tk::MainLoop;



sub Drivers {
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['Name','Entry']]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 $do->set(-wgtbl=>$wgt
         ,-mdedt=>0
         ,-cbdbRead=>sub{
                      foreach my $v (DBI->available_drivers) {
                        $_[0]->dsRowFeed([$v]);
                      }; 1
                     }
         );
 
 $do->Retrieve('#reread')
}



sub DataSources {
 my ($self, $cmd, $opt, $row, $fld, $wg, $dta, $new) =(shift, shift, @_);

 if    ($cmd eq 'stop')   {
       return(1)
 }
 elsif ($cmd eq 'start')  {

       my $wgt=$self->{-wgscr}->tmTable(
            -rowcount=>10
           ,-colspecs=>[['Name','Entry']]
           )->pack;

       my $do;
       if (!$self->{-dos}) {
          $do =new Tk::TM::DataObject();
          $self->{-dos} =[$do];
       }
       else {
          $do =$self->{-dos}->[0];
       }

       my $rwm =$row->{-dos}->[0]->dsRowDta();
       $do->{-parm}->{dsn} =$rwm->[0];
       $self->{-title} =$do->{-parm}->{dsn};

       $do->set(-wgtbl=>$wgt
           #   ,-mdedt=>0
               ,-cbcmd=>\&DataSources
               );
       $do->Retrieve('#reread')
 }
 elsif ($cmd eq 'dbRead') {
       foreach my $v (DBI->data_sources($self->{-parm}->{dsn})) {
         $self->dsRowFeed([$v]);
       }; 1
 }
 else  {return $self->doDefault($cmd, @_)}
 }



sub Login {
 my ($self, $cmd, $opt, $mst) =@_;

 if ($cmd =~/start/) {
    my $rwm =$mst->{-dos}->[0]->dsRowDta();
    $self->{-opt}->{-dsn} =$rwm->[0];
 }

 Tk::TM::wApp::DBILogin($self, $cmd, $opt, $mst)
}



sub Tables {
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['Qualifier','Entry']
                     ,['Owner'    ,'Entry']
                     ,['Name'     ,'Entry']
                     ,['Remarks'  ,'Entry']]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 $do->set(-wgtbl=>$wgt
#         ,-mdedt=>0
         ,-cbdbRead=>sub{
                     $_[0]->dsRowFeedAll($_[0]->DBICmd('table_info')->fetchall_arrayref)
                    }
         );
 
 $do->Retrieve('#reread')
}



sub Datas {
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['Col1' ,'Entry']
                     ,['Col2' ,'Entry']
                     ,['Col3' ,'Entry']
                     ,['Col4' ,'Entry']]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 my $rwm =$mst->{-dos}->[0]->dsRowDta();
 my $tbl =(defined($rwm->[1]) ? $rwm->[1] .'.' : '') .($rwm->[2] ||'');
 if ($tbl) {$self->{-wgapp}->{-parm}->{table} =$tbl}
 else      {$tbl =$self->{-wgapp}->{-parm}->{table}}
 $self->{-title} =$tbl;

 $do->set(-wgtbl=>$wgt
         ,-mdedt=>0
         ,-cbdbRead=>sub{$_[0]->DBICmd("select * from $tbl")}
         );
 
 $do->Retrieve('#reread')
}


sub Descriptions {
 my ($self, $cmd, $opt, $mst) =@_;
 return(1) if $cmd =~/stop/;

 my $wgt=$self->{-wgscr}->tmTable(
          -rowcount=>10
         ,-colspecs=>[['NAME'      ,'Entry']
                     ,['TYPE'      ,'Entry',-width=>5]
                     ,['SCALE'     ,'Entry',-width=>5]
                     ,['PRECIS'    ,'Entry',-width=>5]
                     ,['NULLABLE'  ,'Entry',-width=>5]]
         )->pack;

 my $do;
 if (!$self->{-dos}) {
    $do =new Tk::TM::DataObject();
    $self->{-dos} =[$do];
 }
 else {
    $do =$self->{-dos}->[0];
 }

 my $rwm =$mst->{-dos}->[0]->dsRowDta();
 my $tbl =(defined($rwm->[1]) ? $rwm->[1] .'.' : '') .($rwm->[2] ||'');
 if ($tbl) {$self->{-wgapp}->{-parm}->{table} =$tbl}
 else      {$tbl =$self->{-wgapp}->{-parm}->{table}}
 $self->{-title} =$tbl;

 $do->set(-wgtbl=>$wgt
         ,-mdedt=>0
         ,-cbdbRead=>sub{
            my $dbs =$Tk::TM::Common::DBH->prepare("select * from $tbl");
               $dbs->execute;
            eval {
              for (my $i =$[; $i <$dbs->{NUM_OF_FIELDS} +$[; $i++) {
                 my $dsc ={};
                 eval {$dsc->{NAME}      =$dbs->{NAME}->[$i]};
                 eval {$dsc->{TYPE}      =$dbs->{TYPE}->[$i]};
                 eval {$dsc->{SCALE}     =$dbs->{SCALE}->[$i]};
                 eval {$dsc->{PRECISION} =$dbs->{PRECISION}->[$i]};
                 eval {$dsc->{NULLABLE}  =$dbs->{NULLABLE}->[$i]};
                 $_[0]->dsRowFeed([$dsc->{NAME},$dsc->{TYPE},$dsc->{SCALE},$dsc->{PRECISION},$dsc->{NULLABLE}]);
              }
            };
            $dbs->finish; 1;
           }
         );
 
 $do->Retrieve('#reread')
}