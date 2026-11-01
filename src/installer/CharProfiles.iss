; Compile with Inno Setup 6. This package contains only the TBC Classic adapter.
#include "ClientDefinitions.iss"

#define AddonVersion "0.1.0-dev"

[Setup]
AppId={{E3B3D2D2-4C6F-49E6-9E6F-2AE84FC8D702}
AppName=CharProfiles ({#TargetClientName})
AppVersion={#AddonVersion}
AppPublisher=CharProfiles
DefaultDirName={autopf}\CharProfiles Installer Support
DisableProgramGroupPage=yes
DisableDirPage=yes
UninstallDisplayName=CharProfiles ({#TargetClientName})
OutputBaseFilename=CharProfiles-TBC-Classic-Setup
Compression=lzma2
SolidCompression=yes
PrivilegesRequired=lowest
CloseApplications=no

[Files]
Source: "..\CharProfiles\*"; DestDir: "{code:GetAddonDir}"; Flags: ignoreversion recursesubdirs createallsubdirs; BeforeInstall: PrepareAddonDirectory

[Registry]
Root: HKCU; Subkey: "Software\CharProfiles\{#TargetClientId}"; ValueType: string; ValueName: "GameDir"; ValueData: "{code:GetGameDir}"; Flags: uninsdeletekey

[UninstallDelete]
Type: filesandordirs; Name: "{code:GetAddonDir}"
Type: files; Name: "{code:GetGameDir}\WTF\Account\*\SavedVariables\CharProfiles.lua"; Check: RemovePersonalProfiles
Type: files; Name: "{code:GetGameDir}\WTF\Account\*\SavedVariables\CharProfilesBackup.lua"; Check: RemovePersonalProfiles

[Code]
var
  GameDirPage: TInputDirWizardPage;
  GameDir: String;
  AddonBackupDir: String;
  UpdatePrepared: Boolean;
  RemoveProfilesOnUninstall: Boolean;

function CandidateIsValid(const Candidate: String): Boolean;
begin
  Result := DirExists(AddBackslash(Candidate) + 'Interface') and
    (FileExists(AddBackslash(Candidate) + 'Wow.exe') or
     FileExists(AddBackslash(Candidate) + 'WowClassic.exe') or
     FileExists(AddBackslash(Candidate) + 'WowT.exe'));
end;

function DetectGameDir(): String;
var
  Candidates: TArrayOfString;
  I: Integer;
begin
  SetArrayLength(Candidates, 4);
  Candidates[0] := ExpandConstant('{#CandidatePath1}');
  Candidates[1] := ExpandConstant('{#CandidatePath2}');
  Candidates[2] := ExpandConstant('{#CandidatePath3}');
  Candidates[3] := ExpandConstant('{#CandidatePath4}');
  Result := '';
  for I := 0 to GetArrayLength(Candidates) - 1 do
    if CandidateIsValid(Candidates[I]) then begin
      Result := Candidates[I];
      exit;
    end;
end;

procedure InitializeWizard;
begin
  GameDirPage := CreateInputDirPage(wpWelcome,
    'WoW-Ordner auswählen',
    'Ziel für CharProfiles festlegen',
    'Wähle den WoW-Clientordner. Der Installer legt das Addon ausschließlich unter Interface\AddOns\CharProfiles ab.',
    False, False);
  GameDirPage.Add('WoW-Clientordner:');
  GameDirPage.Values[0] := DetectGameDir();
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if CurPageID = GameDirPage.ID then begin
    GameDir := RemoveBackslashUnlessRoot(GameDirPage.Values[0]);
    if not CandidateIsValid(GameDir) then begin
      MsgBox('Der gewählte Ordner sieht nicht wie ein unterstützter WoW-Clientordner aus. Wähle den Ordner mit Interface und Wow.exe.', mbError, MB_OK);
      Result := False;
      exit;
    end;
    if MsgBox('CharProfiles wird hier installiert:'#13#10 + AddBackslash(GameDir) + '{#TargetAddonRelativePath}', mbConfirmation, MB_OKCANCEL) <> IDOK then begin
      Result := False;
      exit;
    end;
  end;
end;

function GetGameDir(Param: String): String;
var
  Stored: String;
begin
  if GameDir <> '' then begin
    Result := GameDir;
    exit;
  end;
  if RegQueryStringValue(HKCU, 'Software\CharProfiles\{#TargetClientId}', 'GameDir', Stored) then
    Result := Stored
  else
    Result := '';
end;

function GetAddonDir(Param: String): String;
begin
  Result := AddBackslash(GetGameDir('')) + '{#TargetAddonRelativePath}';
end;

function PrepareAddonDirectory(): Boolean;
var
  SourceDir: String;
begin
  Result := True;
  if UpdatePrepared then exit;
  UpdatePrepared := True;
  SourceDir := GetAddonDir('');
  if not DirExists(SourceDir) then exit;

  AddonBackupDir := AddBackslash(ExpandConstant('{tmp}')) + 'CharProfilesAddonBackup';
  DelTree(AddonBackupDir, True, True, True);
  if not ForceDirectories(AddonBackupDir) then begin
    MsgBox('Die vorhandene CharProfiles-Installation konnte nicht gesichert werden.', mbError, MB_OK);
    Result := False;
    exit;
  end;
  if not CopyDir(SourceDir, AddonBackupDir, True) then begin
    MsgBox('Die vorhandene CharProfiles-Installation konnte nicht gesichert werden.', mbError, MB_OK);
    Result := False;
    exit;
  end;
  { Never touch sibling AddOns or files outside this one add-on folder. }
  if not DelTree(SourceDir, True, True, True) then begin
    MsgBox('Die alte CharProfiles-Installation konnte nicht ersetzt werden.', mbError, MB_OK);
    Result := False;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  TargetToc: String;
begin
  if CurStep <> ssPostInstall then exit;
  TargetToc := AddBackslash(GetAddonDir('')) + 'CharProfiles.toc';
  if not FileExists(TargetToc) then begin
    if AddonBackupDir <> '' and DirExists(AddonBackupDir) then begin
      DelTree(GetAddonDir(''), True, True, True);
      CopyDir(AddonBackupDir, GetAddonDir(''), True);
    end;
    MsgBox('Die Installation ist unvollständig. Der vorherige Addon-Zustand wurde wiederhergestellt, soweit möglich.', mbError, MB_OK);
  end;
end;

function InitializeUninstall(): Boolean;
begin
  RemoveProfilesOnUninstall :=
    MsgBox('Auch persönliche CharProfiles-Profile und Sicherungen entfernen?' + #13#10 +
      'Mit "Nein" bleiben sie für eine spätere Neuinstallation erhalten.',
      mbConfirmation, MB_YESNO) = IDYES;
  if RemoveProfilesOnUninstall then
    Result := MsgBox('Persönliche Profile werden endgültig entfernt. Fortfahren?', mbConfirmation, MB_YESNO) = IDYES
  else
    Result := True;
end;

function RemovePersonalProfiles(): Boolean;
begin
  Result := RemoveProfilesOnUninstall;
end;
