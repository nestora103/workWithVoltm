unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs,Visa_h, StdCtrls,IniFiles;

type
  TForm1 = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;
  //инициализируем генератор
  m_defaultRM_usbtmc, m_instr_usbtmc:array[0..3] of LongWord;
  //переменная для хранения идентификатора генератора
  RigolDg1022:string;
  //переменная для сязывания ini-файла
  iniFile:TIniFile;
  viAttr:Longword =  $3FFF001A;
  Timeout: integer = 1000; //7000
implementation

{$R *.dfm}

function SetConf(m_instr_usbtmc_loc:Longword; command:string):integer;
var
  pStrout:pointerchar;
  i:integer;
  nWritten:LongWord;
begin
  setlength(pStrout,64);
  for i:=0 to length(command) do  pStrout[i]:=command[i+1];
	result:= viWrite(m_instr_usbtmc_loc, pStrout, length(command), @nWritten);
	Sleep(30);
end;

//==============================================================================
//Функции для работы с генератором и вольтметром
//==============================================================================

//функция для проверки подключен ли генератор или вольтметр
function TestConnect(Name:string; var m_defaultRM_usbtmc_loc, m_instr_usbtmc_loc:Longword; vAtr:Longword; m_Timeout: integer):integer;
var
  status:integer;
  viAttr:Longword;
  i:integer;
  m_findList_usbtmc: LongWord;
  m_nCount: LongWord;
  instrDescriptor:pointerchar;
begin
setlength(instrDescriptor,255);
result:=0;
status:= viOpenDefaultRM(@m_defaultRM_usbtmc_loc);
if (status < 0) then
  //генератор
	begin
		viClose(m_defaultRM_usbtmc_loc);
		m_defaultRM_usbtmc_loc:= 0;
    result:=-1;
    showmessage('       Генератор сигналов не найден!');
  end
else
  //вольтметр
	begin
		status:= viFindRsrc(m_defaultRM_usbtmc_loc, name, @m_findList_usbtmc, @m_nCount, instrDescriptor);
 		if (status < 0) then
      begin
			  status:= viFindRsrc (m_defaultRM_usbtmc_loc, 'USB[0-9]*::0x1AB1::0x0588::?*INSTR', @m_findList_usbtmc, @m_nCount, instrDescriptor);
			  if (status < 0) then
			    begin
				    viClose(m_defaultRM_usbtmc_loc);
            result:=-1;
            showmessage('       Вольтметр не найден!');
				    m_defaultRM_usbtmc_loc:= 0;
            exit;
			    end
			  else
			    begin
				    viOpen(m_defaultRM_usbtmc_loc, instrDescriptor, 0, 0, @m_instr_usbtmc_loc);
				    status:= viSetAttribute(m_instr_usbtmc_loc, vatr, m_Timeout);
			    end
		  end
		else
		  begin
			  status:= viOpen(m_defaultRM_usbtmc_loc, instrDescriptor, 0, 0, @m_instr_usbtmc_loc);
  		  status:= viSetAttribute(m_instr_usbtmc_loc, viAttr, m_Timeout);
		  end
	end;

result:=status;
end;


procedure SetFrequencyOnGenerator(Freq:integer;Ampl:real);
begin
  SetConf(m_instr_usbtmc[1],'VOLT:UNIT VPP');
  SetConf(m_instr_usbtmc[1],'APPL:SIN '+ inttostr(Freq)+','+floattostr(Ampl)+',0.0');
  SetConf(m_instr_usbtmc[1],'PHAS 0');
  SetConf(m_instr_usbtmc[1],'OUTP ON');
end;

procedure TForm1.Button1Click(Sender: TObject);
begin
SetFrequencyOnGenerator(StrToInt(form1.Edit1.text),StrToFloat(form1.Edit2.text));

end;

procedure TForm1.Button2Click(Sender: TObject);
begin
RigolDg1022:=IniFile.ReadString('Generator','Serial_number','USB[0-9]*::0x1AB1::0x0588::?*INSTR');
if (TestConnect(RigolDg1022,m_defaultRM_usbtmc[1],m_instr_usbtmc[1],viAttr,Timeout)=-1) then
  begin
    showmessage('Генератор не подключен!');    //Инициализация генератора
    Application.Terminate; //плавное закрытие программы
  end;
IniFile.Free;  
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
//связываем переменную ini-файла с конфигурационным файлом
IniFile:=TIniFile.Create(ExtractFileDir(ParamStr(0))+'/ConfigDir/conf.ini');
end;

end.
