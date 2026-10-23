"""Local structural checks. These do not compile or execute Windows setup."""
from pathlib import Path
import hashlib,json,zipfile,re,yaml
r=Path(__file__).resolve().parents[1]
c=json.loads((r/'build-config.json').read_text())
archive=r/c['sourceArchive']
assert hashlib.sha256(archive.read_bytes()).hexdigest()==c['sourceSHA256']
with zipfile.ZipFile(archive) as z:
 assert z.testzip() is None
 required=['payload/brand/FeelingDizzyYet.ico','payload/LICENSE.txt','payload/After Effects/Feeling Dizzy Yet.jsx','payload/After Effects/FeelingDizzyYet/scripts/102_Automatic_Multicam_Editor.jsx','payload/Premiere Edition/plugin/manifest.json','Verification/run-tests.js','Examples/microphone-1.wav']
 for name in required:assert 'Feeling Dizzy Yet Windows/'+name in z.namelist(),name
w=yaml.load((r/'.github/workflows/windows-installer.yml').read_text(),Loader=yaml.BaseLoader)
assert 'workflow_dispatch' in w['on']
assert w['permissions']=={'contents':'read'}
assert 'pull_request_target' not in w['on']
j=w['jobs']['installer'];assert j['runs-on']=='windows-2022'
assert [s.get('run') for s in j['steps'] if s.get('run','').startswith('./scripts/')]==['./scripts/Build-Windows.ps1','./scripts/Test-Installer.ps1']
assert next(s for s in j['steps'] if s.get('name')=='Publish tested installer')['if']=='success()'
assert (r/'windows-installer.yml').read_bytes()==(r/'.github/workflows/windows-installer.yml').read_bytes()
s=(r/'installer/FeelingDizzyYet.iss').read_text()
assert 'PrivilegesRequired=lowest' in s and 'MinVersion=10.0' in s
assert 'CurUninstallStepChanged' in s and 'OriginalBackup' in s
assert '.vbs' not in s and 'powershell.exe' not in s and 'ExecutionPolicy' not in s
assert 'Source: "..\\packages\\FeelingDizzyYet-Premiere.ccx"' in s
assert '#ifdef IncludeCCX' in s and 'skipifsilent unchecked' in s
assert re.search(r'AppId=\{\{[0-9A-F-]+\}',s)
for src in re.findall(r'^Source: "([^"]+)"',s,re.M):
 assert src.startswith(('..\\build\\','..\\packages\\')),src
for f in ['scripts/Build-Windows.ps1','scripts/Test-Installer.ps1','README.md','NATIVE-INSTALL.md']:assert (r/f).is_file()
print('PASS source archive checksum/integrity and required runtime files')
print('PASS workflow YAML, Windows runner, restricted permissions and success-gated installer artifact')
print('PASS native installer source boundaries, CCX optionality and backup/restore hooks')
try:
 import tree_sitter,tree_sitter_powershell
 parser=tree_sitter.Parser(tree_sitter.Language(tree_sitter_powershell.language()))
 for p in (r/'scripts').glob('*.ps1'):assert not parser.parse(p.read_bytes()).root_node.has_error,p
 print('PASS PowerShell grammar checks (tree-sitter; no Windows execution)')
except ImportError:
 print('SKIPPED optional PowerShell grammar checks; install tree-sitter and tree-sitter-powershell')
print('PENDING: real Inno compilation and installer smoke tests on a GitHub Windows runner')
print('PENDING: Adobe loading/editing/rendering and production Premiere CCX installation')
