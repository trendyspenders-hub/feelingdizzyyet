#ifndef AppVersion
  #define AppVersion "0.8.0"
#endif
[Setup]
AppId={{990B90E0-5BC2-4F21-8D7B-634135D29F0F}
AppName=Feeling Dizzy Yet
AppVersion={#AppVersion}
AppPublisher=Feeling Dizzy Yet
DefaultDirName={localappdata}\Programs\Feeling Dizzy Yet
DefaultGroupName=Feeling Dizzy Yet
PrivilegesRequired=lowest
MinVersion=10.0
ArchitecturesAllowed=x64compatible
WizardStyle=modern
SetupIconFile=..\build\payload\brand\FeelingDizzyYet.ico
UninstallDisplayIcon={app}\brand\FeelingDizzyYet.ico
OutputDir=..\dist
OutputBaseFilename=FeelingDizzyYetSetup-{#AppVersion}-unsigned
Compression=lzma2
SolidCompression=yes
DisableWelcomePage=no
DisableProgramGroupPage=yes
AllowNoIcons=yes
CloseApplications=no
RestartApplications=no
LicenseFile=..\build\payload\LICENSE.txt
InfoBeforeFile=..\build\INSTALLER-NOTICE.txt
Uninstallable=yes
SetupLogging=yes
VersionInfoDescription=Feeling Dizzy Yet editing tools setup
VersionInfoProductName=Feeling Dizzy Yet
[Types]
Name: full; Description: "Editing tools and Premiere package/source"
Name: custom; Description: "Choose components"; Flags: iscustom
[Components]
Name: aftereffects; Description: "After Effects panel and 102 tools"; Types: full custom
#ifdef IncludeCCX
Name: premiere; Description: "Premiere plugin - Adobe CCX package"; Types: full custom
#else
Name: premiere; Description: "Premiere developer source - requires Adobe UXP Developer Tool"; Types: full custom
#endif
[Files]
Source: "..\build\payload\brand\*"; DestDir: "{app}\brand"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\payload\LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\NATIVE-INSTALL.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\NATIVE-INSTALL.html"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\build\payload\After Effects\*"; DestDir: "{app}\After Effects"; Components: aftereffects; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\payload\After Effects\Feeling Dizzy Yet.jsx"; DestDir: "{code:GetAEPanelDir}"; Components: aftereffects; Check: HasAETarget; Flags: ignoreversion
Source: "..\build\payload\After Effects\FeelingDizzyYet\*"; DestDir: "{code:GetAEPanelDir}\FeelingDizzyYet"; Components: aftereffects; Check: HasAETarget; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\payload\Premiere Edition\*"; DestDir: "{app}\Premiere Edition"; Components: premiere; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "..\build\Examples\*"; DestDir: "{app}\Examples"; Flags: ignoreversion recursesubdirs createallsubdirs
#ifdef IncludeCCX
Source: "..\packages\FeelingDizzyYet-Premiere.ccx"; DestDir: "{app}\Premiere Edition"; Components: premiere; Flags: ignoreversion
#endif
[Icons]
Name: "{group}\Installation instructions"; Filename: "{app}\NATIVE-INSTALL.html"
Name: "{group}\Installed editing tools"; Filename: "{app}"
Name: "{group}\Uninstall Feeling Dizzy Yet"; Filename: "{uninstallexe}"
[Run]
#ifdef IncludeCCX
Filename: "{app}\Premiere Edition\FeelingDizzyYet-Premiere.ccx"; Description: "Open Premiere package in Adobe Creative Cloud"; Components: premiere; Flags: postinstall shellexec skipifsilent unchecked
#endif
Filename: "{app}\NATIVE-INSTALL.html"; Description: "Read installation instructions"; Flags: postinstall shellexec skipifsilent unchecked
[Code]
const StateKey = 'Software\FeelingDizzyYet\NativeSetup';
var AEPage: TInputOptionWizardPage; AEVersions: TArrayOfString;
    RestorePath, InstalledTarget, PendingBackup, PendingTarget: String;
function IsVersion(const S: String): Boolean;
var I, Dots: Integer;
begin
  Result := False; Dots := 0;
  if Length(S) < 3 then exit;
  for I := 1 to Length(S) do
    if S[I] = '.' then Dots := Dots + 1
    else if (S[I] < '0') or (S[I] > '9') then exit;
  Result := (Dots >= 1) and (Dots <= 2) and (S[1] <> '.') and (S[Length(S)] <> '.') and (Pos('..', S) = 0);
end;
function CopyTree(const Source, Dest: String): Boolean;
var F: TFindRec; Good: Boolean;
begin
  Result := ForceDirectories(Dest);
  if not Result then exit;
  if FindFirst(Source + '\*', F) then begin
    try
      repeat
        if (F.Name <> '.') and (F.Name <> '..') then begin
          if (F.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0 then
            Good := CopyTree(Source + '\' + F.Name, Dest + '\' + F.Name)
          else Good := FileCopy(Source + '\' + F.Name, Dest + '\' + F.Name, False);
          if not Good then Result := False;
        end;
      until not FindNext(F);
    finally FindClose(F); end;
  end;
end;
procedure InitializeWizard;
var F: TFindRec; V, Requested, Previous: String; N: Integer;
begin
  AEPage := CreateInputOptionPage(wpSelectComponents, 'After Effects version',
    'Choose the existing preferences version for this Windows user',
    'Close After Effects before installing. Skip keeps a manual-install copy in the application folder.', False, False);
  AEPage.Add('Skip panel registration - keep manual-install files');
  SetArrayLength(AEVersions, 1); AEVersions[0] := ''; AEPage.SelectedValueIndex := 0;
  Requested := ExpandConstant('{param:AEVERSION|}');
  RegQueryStringValue(HKCU, StateKey, 'AEPanelDir', Previous);
  if FindFirst(ExpandConstant('{userappdata}\Adobe\After Effects\*'), F) then begin
    try
      repeat
        V := F.Name;
        if ((F.Attributes and FILE_ATTRIBUTE_DIRECTORY) <> 0) and IsVersion(V) then begin
          N := GetArrayLength(AEVersions); SetArrayLength(AEVersions, N+1); AEVersions[N] := V;
          AEPage.Add('After Effects ' + V);
          if (V = Requested) or (Previous = ExpandConstant('{userappdata}\Adobe\After Effects\') + V + '\Scripts\ScriptUI Panels') then AEPage.SelectedValueIndex := N;
        end;
      until not FindNext(F);
    finally FindClose(F); end;
  end;
end;
function GetAEPanelDir(Param: String): String;
begin
  Result := ExpandConstant('{app}\Manual Panel');
  if AEPage.SelectedValueIndex > 0 then Result := ExpandConstant('{userappdata}\Adobe\After Effects\') + AEVersions[AEPage.SelectedValueIndex] + '\Scripts\ScriptUI Panels';
end;
function HasAETarget: Boolean;
begin
  Result := WizardIsComponentSelected('aftereffects') and (AEPage.SelectedValueIndex > 0);
end;
function ShouldSkipPage(PageID: Integer): Boolean;
begin Result := (PageID = AEPage.ID) and not WizardIsComponentSelected('aftereffects'); end;
function PrepareToInstall(var NeedsRestart: Boolean): String;
var Target, OldTarget, Backup, PriorBackup: String; Good: Boolean;
begin
  Result := '';
  if (ExpandConstant('{param:AEVERSION|}') <> '') and (AEPage.SelectedValueIndex = 0) then begin Result := 'Requested After Effects preferences version was not found.'; exit; end;
  if not HasAETarget then exit;
  Target := GetAEPanelDir('');
  RegQueryStringValue(HKCU, StateKey, 'AEPanelDir', OldTarget);
  if (OldTarget <> '') and (CompareText(OldTarget, Target) <> 0) then begin Result := 'Uninstall the existing native setup before choosing a different AE version. Backups will be retained.'; exit; end;
  Backup := ExpandConstant('{localappdata}\FeelingDizzyYetBackups\') + GetDateTimeString('yyyymmdd-hhnnss', '-', ':');
  while DirExists(Backup) do Backup := Backup + '-next';
  Good := ForceDirectories(Backup);
  if FileExists(Target + '\Feeling Dizzy Yet.jsx') then Good := FileCopy(Target + '\Feeling Dizzy Yet.jsx', Backup + '\Feeling Dizzy Yet.jsx', False) and Good;
  if DirExists(Target + '\FeelingDizzyYet') then Good := CopyTree(Target + '\FeelingDizzyYet', Backup + '\FeelingDizzyYet') and Good;
  if not Good then begin Result := 'Could not back up existing AE panel files. Installation stopped.'; exit; end;
  RegQueryStringValue(HKCU, StateKey, 'OriginalBackup', PriorBackup);
  if PriorBackup = '' then PendingBackup := Backup else PendingBackup := PriorBackup;
  PendingTarget := Target;
  Log('AE backup created: ' + Backup);
end;
procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep = ssPostInstall) and (PendingTarget <> '') then begin
    RegWriteStringValue(HKCU, StateKey, 'OriginalBackup', PendingBackup);
    RegWriteStringValue(HKCU, StateKey, 'AEPanelDir', PendingTarget);
  end;
end;
function InitializeUninstall: Boolean;
begin
  RegQueryStringValue(HKCU, StateKey, 'OriginalBackup', RestorePath);
  RegQueryStringValue(HKCU, StateKey, 'AEPanelDir', InstalledTarget);
  Result := True;
end;
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var Saved: String; Good: Boolean;
begin
  if (CurUninstallStep = usUninstall) and (InstalledTarget <> '') then begin
    Saved := ExpandConstant('{localappdata}\FeelingDizzyYetBackups\removed-') + GetDateTimeString('yyyymmdd-hhnnss', '-', ':');
    while DirExists(Saved) do Saved := Saved + '-next';
    Good := ForceDirectories(Saved);
    if FileExists(InstalledTarget + '\Feeling Dizzy Yet.jsx') then Good := FileCopy(InstalledTarget + '\Feeling Dizzy Yet.jsx', Saved + '\Feeling Dizzy Yet.jsx', False) and Good;
    if DirExists(InstalledTarget + '\FeelingDizzyYet') then Good := CopyTree(InstalledTarget + '\FeelingDizzyYet', Saved + '\FeelingDizzyYet') and Good;
    if not Good then RaiseException('Could not preserve AE files before uninstall. Uninstall stopped.');
  end;
  if CurUninstallStep = usPostUninstall then begin
    Good := True;
    if (RestorePath <> '') and (InstalledTarget <> '') then begin
      Good := ForceDirectories(InstalledTarget);
      if FileExists(RestorePath + '\Feeling Dizzy Yet.jsx') then Good := FileCopy(RestorePath + '\Feeling Dizzy Yet.jsx', InstalledTarget + '\Feeling Dizzy Yet.jsx', False) and Good;
      if DirExists(RestorePath + '\FeelingDizzyYet') then Good := CopyTree(RestorePath + '\FeelingDizzyYet', InstalledTarget + '\FeelingDizzyYet') and Good;
    end;
    if Good then RegDeleteKeyIncludingSubkeys(HKCU, StateKey)
    else Log('Previous AE files could not be fully restored. Inspect backups: ' + RestorePath);
  end;
end;
