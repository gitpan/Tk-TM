#!perl -w
#
# Tk Transaction Manager.
# Language localization
#
# makarow, demed
#

package Tk::TM::Lang;
require 5.000;
use strict;
require Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = '0.50';
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw(txtMenu txtHelp txtMsg);

use vars qw($Lang);
$Lang   ='';      # set localization

1;


sub txtHelp {
my $txt;
$txt =
  ["-------- 'File' - File operations --------"
  ,"'Save', [S], [Shift+F2], [Ctrl+S] - save modified data."
  ,"'Reread', [<>], [F5] - reread data to screen, refresh view. Same as 'Query' but keeps current position."
  ,"'Print...', [Ctrl+P] - print data."
  ,"'Export...' - export data to file shoosen."
  ,"'Import...' - import data from file choosen."
  ,"'Close', [Alt+F4] - close window."
  ,"'Exit', [Shift+F3] - exit application."
  ,"-------- 'Edit' - Editing data --------"
  ,"'New record', [+], [Ctrl+N] - create (append) new record of data."
  ,"'Delete record', [-], [Ctrl+Y] - delete the current record of data."
  ,"'Undo edit' - undo changes made in current record."
  ,"'Prompt...', [F4] - entry help screen to choose value to enter into field."
  ,"'Cut' - cut selected text from field onto clipboard."
  ,"'Copy' - copy selected text from field onto clipboard."
  ,"'Paste' - paste text from clipboard to cursor position."
  ,"'Delete' - delete selected text."
  ,"-------- 'Actions', [..] - Actions of application --------"
  ,"Contains available application actions."
  ,"-------- 'Search' - Search, Query, Navigation --------"
  ,"'Query', [Q] - read data onto screen (query database)."
  ,"'Reread', [F5] - reread data onto screen, see this in 'File' menu above."
  ,"'Clear', [C] - clear current data on screen, new records may be entered."
  ,"'Find...', [F], [Ctrl+F] - find value in current column with regilar expression entered."
  ,"'Find Next', [Ctrl+G], [Ctrl+L] - find next value with serch entered above."
  ,"'Top', [<<], [Ctrl+Home] - go to the first record of data."
  ,"'Previos', [<], [PageUp] - go to the previos page or record of data."
  ,"'Next', [>], [PageDn] - go to the next page or record of data."
  ,"'Bottom', [>>], [Ctrl+End] - go to the last record of data."
  ,"-------- 'Help' - Help on application --------"
  ,"'Help...', [?], [F1] - info on using application."
  ,"'About...' - general info on application."
  ] if !$Lang;

$txt =
  ["-------- '����' - �������� �������� --------"
  ,"'���������', [S], [Shift+F2], [Ctrl+S] - ��������� ���������� ������."
  ,"'����������', [<>], [F5] - ���������� ������ �� �����, �������� �����. ���������� 'Query' �� ��������� ������� �������."
  ,"'��������...', [Ctrl+P] - �������� ������."
  ,"'�������...' - �������������� ������ � ��������� ����."
  ,"'������...' - ������������� ������ �� ���������� �����."
  ,"'�������', [Alt+F4] - ������� ����."
  ,"'�����', [Shift+F3] - ��������� ����������."
  ,"-------- '�������������' - �������� �������������� --------"
  ,"'����� ������', [+], [Ctrl+N] - ������� (��������) ����� ������ ������."
  ,"'������� ������', [-], [Ctrl+Y] - ������� ������� ������ ������."
  ,"'�������� ��������������' - �������� ��������� ������� ������."
  ,"'���������...', [F4] - ������� ����� ��������� ���������� �������� ����."
  ,"'��������' - �������� ��������� ����� �� ���� � ����� ������."
  ,"'����������' - ����������� ��������� ����� �� ���� � ����� ������."
  ,"'��������' - �������� ����� �� ������ ������ � ������� �������."
  ,"'�������' - ������� ��������� �����."
  ,"-------- '��������', [..] - ���������� �������� --------"
  ,"�������� ��������� ���������� ��������."
  ,"-------- '�����' - �����, �������, ��������� --------"
  ,"'������', [Q] - ��������� ������ �� ����� (������ � ���� ������)."
  ,"'����������', [F5] - ���������� ������ �� �����, �������� �����. ��. ����� ���� '����'."
  ,"'��������', [C] - ������ ������� ������ � ������, ����� ��������� ����� ������."
  ,"'�����...', [F], [Ctrl+F] - ����� �������� � ������� �������, ��������������� ��������� ����������� ���������."
  ,"'����� �����', [Ctrl+G], [Ctrl+L] - ����� ��������� �������� � ��������� ���� ������."
  ,"'������', [<<], [Ctrl+Home] - ������� � ������ ������ ������."
  ,"'����������', [<], [PageUp] - ������� � ���������� �������� ��� ������ ������."
  ,"'���������', [>], [PageDn] - ������� � ��������� �������� ��� ������ ������."
  ,"'���������', [>>], [Ctrl+End] - ������� � ��������� ������ ������."
  ,"-------- '�������' - ��������� ������� --------"
  ,"'�������...', [?], [F1] - �������� �� ������������� ����������."
  ,"'� ����������...' - �������� �������� � ����������."
  ] if $Lang;

  return($txt)
}


sub txtMenu {
  return(
  ['File','~Save','~Reread','~Print...','~Export...','~Import...','~Close','~Exit'
  ,'Edit','~New record','~Delete record','~Undo record','~Prompt...','~Undo','Cu~t','~Copy','~Paste','De~lete','Select ~All'
  ,'Actions'
  ,'Search','~Query','~Reread','~Clear','~Find...','Find ~Next','~Top','~Previos','Ne~xt','~Bottom'
  ,'Help','~Help...','~About...'
  ]
  ) if !$Lang;

  return(
  ['����','~���������','~����������','~��������...','~�������...','~������...','~�������','~�����'
  ,'�������������','~����� ������','~������� ������','~�������� ��������������','~���������...','~Undo','~��������','~����������','���~�����','~�������','Select ~All'
  ,'��������'
  ,'�����','~������','~����������','~��������','~�����...','~����� �����','~������','~����������','~���������','~���������'
  ,'�������','~�������...','~� ����������...'
  ]
  ) if $Lang;
}


sub txtMsg {
 return($_[0]) if !$Lang;
 my %msg =(
  'About application' => '� ����������'
 ,'Cancel' => '��������'
 ,'Choose' => '�������'
 ,'Close' => '�������'
 ,'Closing' => '��������'
 ,'Data was modified' => '������ ���� ��������'
 ,'Database' => '���� ������'
 ,'Error' => '������'
 ,'Find' => '�����'
 ,'Function not released' => '������� �� �����������'
 ,'Help' => '�������'
 ,'Load data from file' => '��������� ������ �� �����'
 ,'Login' => '�����������'
 ,'Ok' => '���������'
 ,'Opening' => '��������'
 ,'Operation' => '������������'
 ,'Pardon' => '��������'
 ,'Password' => '������'
 ,'Save changes?' => '��������� ���������?'
 ,'Save data into file' => '��������� ������ � ����'
 ,'User' => '������������'
 ,'Writing' => '������'
 );
 return($msg{$_[0]} || $_[0]);
}

