unit LauncherMethod;

interface

uses
  SysUtils, Classes, Windows, IOUtils, StrUtils, JSON, Zip, Forms, IniFiles;

function GetMCRealPath(path, suffix: string): String;
function GetMCInheritsFrom(selpath, inheritsorjar: String): String;
function ReplaceMCInheritsFrom(yuanjson, gaijson: String): String;
function ConvertNameToPath(name: String): String;
function Unzip(zippath, extpath: String): Boolean;
function JudgeIsolation: String;

implementation

uses
  MainMethod, MainForm;
function JudgeIsolation: String;
begin
  var ret: Boolean;
  var mcsc := strtoint(LLLini.ReadString('MC', 'SelectMC', '')) - 1;
  var mcct := GetFile(Concat(ExtractFileDir(Application.ExeName), '\LLLauncher\configs\', 'MCJson.json'));
  { ��ΪMCδ��·�� }var mccp := (((TJsonObject.ParseJSONValue(mcct) as TJsonObject).GetValue('mc') as TJsonArray)[mcsc] as TJsonObject).GetValue('path').Value;
  var mcsn := strtoint(LLLini.ReadString('MC', 'SelectVer', '')) - 1;
  var mcnt := GetFile(Concat(ExtractFileDir(Application.ExeName), '\LLLauncher\configs\', 'MCSelJson.json'));
  { ��ΪMC����·�� }var msph := (((TJsonObject.ParseJSONValue(mcnt) as TJsonObject).GetValue('mcsel') as TJsonArray)[mcsn] as TJsonObject).GetValue('path').Value;
  var mcyj := GetFile(GetMCRealPath(msph, '.json'));
  var iii := LLLini.ReadString('Version', 'SelectIsolation', ''); //����Ϊ�ж�ԭ�棬�����ԭ�棬�򷵻�true����������򷵻�false��
  var pand: Boolean := (mcyj.IndexOf('com.mumfrey:liteloader:') <> -1) or (mcyj.IndexOf('org.quiltmc:quilt-loader:') <> -1) or (mcyj.IndexOf('net.fabricmc:fabric-loader:') <> -1) or (mcyj.IndexOf('forge') <> -1);
  if iii = '4' then ret := true
  else if iii = '2' then begin
    if not pand then ret := true
    else ret := false;
  end else if iii = '3' then begin
    if pand then ret := true
    else ret := false;
  end else ret := false;
  var IltIni := TIniFile.Create(Concat(msph, '\LLLauncher.ini'));
  if IltIni.ReadString('Isolation', 'IsIsolation', '').ToLower = 'true' then
    if IltIni.ReadString('Isolation', 'Partition', '').ToLower = 'true' then
      ret := true;
  if ret then result := msph else result := mccp;
end;
//��ѹZip
function Unzip(zippath, extpath: String): Boolean;
begin
  result := false;
  if not DirectoryExists(extpath) then ForceDirectories(extpath);
  if not FileExists(zippath) then begin result := false; exit; end;
  var zp := TZipFile.Create;
  try
    try
      zp.Open(zippath, zmRead); //��ѹ����
      zp.ExtractAll(extpath); //��ѹѹ����
      result := true;
    except end;
  finally
    zp.Free;
  end;
end;
// ������ת����·�� ���˷�����ƣ���json�е�name�ļ�ת����path�ĸ�ʽ����
function ConvertNameToPath(name: String): String;
begin //������������дһ�顣��
  var all := TStringList.Create;
  var sb := TStringBuilder.Create;
  try
    var hou: TArray<String> := SplitString(name, '@'); //�Ȱ���@�и�һ��
    name := hou[0];
    var n1 := name.Substring(0, name.IndexOf(':'));
    var n2 := name.Substring(name.IndexOf(':') + 1, name.Length);
    var c1 := SplitString(n1, '.');
    for var I in c1 do all.Add(Concat(I, '\'));
    var c2: TArray<String> := SplitString(n2, ':');
    for var I := 0 to Length(c2) - 1 do begin
      if Length(c2) >= 3 then begin
        if I < Length(c2) - 1 then begin
          all.Add(Concat(c2[I], '\'));
        end;
      end else all.Add(Concat(c2[I], '\'));
    end;
    for var I := 0 to Length(c2) - 1 do begin
      if I < Length(c2) - 1 then begin
        all.Add(Concat(c2[I], '-'));
      end else begin
        try
          all.Add(Concat(c2[I], '.', hou[1]))
        except
          all.Add(Concat(c2[I], '.jar'));
        end;
      end;
    end;
    for var I in all do sb.Append(I);
    result := sb.ToString;
  finally
    all.Free;
    sb.Free;
  end;
end;
//���������򡪡���ԭ����MCJson������InheritsFrom����JSON���ϲ�֮���ٷ��ء�
function ReplaceMCInheritsFrom(yuanjson, gaijson: String): String;
begin
  if yuanjson = '' then begin result := ''; exit; end;  //�������һ��jsonΪ�գ��򷵻ؿա�
  if gaijson = '' then begin result := ''; exit; end;
  if yuanjson = gaijson then begin result := yuanjson; exit; end; //�������jsonһ�����򷵻�ԭֵ��
  yuanjson := yuanjson.Replace('\', '');
  gaijson := gaijson.Replace('\', '');
  var Rty := TJsonObject.ParseJSONValue(yuanjson) as TJsonObject;
  var Rtg := TJsonObject.ParseJSONValue(gaijson) as TJsonObject;
  Rtg.RemovePair('mainClass');
  Rtg.AddPair('mainClass', Rty.GetValue('mainClass').Value);
  Rtg.RemovePair('id');
  Rtg.AddPair('id', Rty.GetValue('id').Value);
  try
    for var I in (Rty.GetValue('libraries') as TJsonArray) do
      (Rtg.GetValue('libraries') as TJsonArray).Add(I as TJsonObject);
  except end;
  try
    for var I in ((Rty.GetValue('arguments') as TJsonObject).GetValue('jvm') as TJsonArray) do
      ((Rtg.GetValue('arguments') as TJsonObject).GetValue('jvm') as TJsonArray).Add(I.Value);
  except end;
  try
    for var I in ((Rty.GetValue('arguments') as TJsonObject).GetValue('game') as TJsonArray) do begin
      ((Rtg.GetValue('arguments') as TJsonObject).GetValue('game') as TJsonArray).Add(I.Value);
    end;
  except end;
  try
    var ma := Rty.GetValue('minecraftArguments').Value;
    Rtg.RemovePair('minecraftArguments');
    Rtg.AddPair('minecraftArguments', ma);
  except end;
  result := Rtg.ToString;
end;
// ��ȡMC����ʵ�ļ�·����
function GetMCRealPath(path, suffix: string): String;
var
  Files: TArray<String>;
begin
  result := '';
  if DirectoryExists(path) then begin // �ж��ļ����Ƿ����
    Files := TDirectory.GetFiles(path); // �ҵ������ļ�
    for var I in Files do begin // �����ļ�
      if I.IndexOf(suffix) <> -1 then begin // �Ƿ��������
        if suffix = '.json' then begin
          var god := GetFile(I);
          try
            var Root := TJsonObject.ParseJSONValue(god) as TJsonObject;
            var tmp := Root.GetValue('libraries').ToString;
            var ttt := Root.GetValue('mainClass').Value;
            result := I;
            exit;
          except
            continue;
          end;
        end else begin
          result := I;
          exit;
        end;
      end;
    end;
  end;
end;
//��ȡMC��InheritsFrom��jar��������Ӧ��MC�ļ��С������MC������InheritsFrom��jar�����򷵻�ԭ������ֵ������Ҳ���Json�ļ����򷵻ؿա�����ҵ���InheritsFrom������ȴ�Ҳ���ԭ�����ļ��У���Ҳͬ�����ؿա���һ�ж������ʱ���򷵻��ҵ����Json�ļ���ַ����
function GetMCInheritsFrom(selpath, inheritsorjar: String): String;
var
  Dirs: TArray<String>;
  Files: TArray<String>;
begin
  result := '';
  if DirectoryExists(selpath) then begin
    var ph := GetMCRealPath(selpath, '.json');
    if FileExists(ph) then begin
      var Rt := TJsonObject.ParseJSONValue(GetFile(ph)) as TJsonObject;
      try
        var ihtf := Rt.GetValue(inheritsorjar).Value;
        if ihtf = '' then raise Exception.Create('Judge Json Error');
        var vdir := ExtractFileDir(selpath);
        Dirs := TDirectory.GetDirectories(vdir);
        for var I in Dirs do begin
          Files := TDirectory.GetFiles(I);
          for var J in Files do begin
            if RightStr(J, 5) = '.json' then begin
              try
                var Rt2 := TJsonObject.ParseJSONValue(GetFile(J)) as TJsonObject;
                var jid := Rt2.GetValue('id').Value;
                var tmp := Rt2.GetValue('libraries').ToString;
                var ttt := Rt2.GetValue('mainClass').Value;
                if jid = ihtf then begin
                  result := I;
                  exit;
                end;
                continue;
              except
                continue;
              end;
            end;
          end;
        end;
      except
        result := selpath;
        if inheritsorjar = 'jar' then result := '';
      end;
    end;
  end;
end;
end.

