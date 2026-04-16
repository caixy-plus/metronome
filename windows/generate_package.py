import os

source_dir = r'C:\Users\volun\OneDrive\Documents\project\metronome\build\windows\x64\runner\Release\data'
release_dir = r'C:\Users\volun\OneDrive\Documents\project\metronome\build\windows\x64\runner\Release'
files = []
for root, dirs, filenames in os.walk(source_dir):
    for f in filenames:
        full = os.path.join(root, f)
        rel = os.path.relpath(full, source_dir)
        files.append((rel.replace('\\', '/'), full.replace('\\', '/')))

# Scan all DLL files in Release directory (excluding data folder and already-hardcoded files)
hardcoded_files = {'metronome.exe', 'flutter_windows.dll'}
dll_files = []
for f in os.listdir(release_dir):
    if f.lower().endswith('.dll') and os.path.isfile(os.path.join(release_dir, f)) and f not in hardcoded_files:
        dll_files.append(f)

dirs = {'DataFolder': []}
component_ids = []

for rel, full in files:
    parts = rel.split('/')
    parent = 'DataFolder'
    for i, p in enumerate(parts[:-1]):
        path_prefix = '_'.join(parts[:i+1]).replace('-','_').replace(' ','_')
        dir_id = 'D_' + path_prefix
        found = False
        for item in dirs.get(parent, []):
            if item['type'] == 'dir' and item['id'] == dir_id:
                found = True
                break
        if not found:
            dirs.setdefault(parent, []).append({'type':'dir','name':p,'id':dir_id})
            dirs[dir_id] = []
        parent = dir_id
    cid = 'C_' + rel.replace('/','_').replace('.','_').replace('-','_')
    component_ids.append(cid)
    dirs[parent].append({'type':'file','rel':rel,'full':full,'cid':cid})

def gen_ref(dir_id, indent):
    out = ''
    for item in dirs.get(dir_id, []):
        if item['type'] == 'dir':
            out += f'{indent}<Directory Id="{item["id"]}" Name="{item["name"]}">\n'
            out += gen_ref(item['id'], indent + '  ')
            out += f'{indent}</Directory>\n'
        else:
            cid = item['cid']
            src = item['rel'].replace('\\', '/')
            out += f'{indent}<Component Id="{cid}" Guid="*"><File Id="F_{cid}" Source="$(var.SourceDir)/data/{src}" KeyPath="yes" /></Component>\n'
    return out

def gen_component_group():
    out = '    <ComponentGroup Id="DataComponents">\n'
    for cid in component_ids:
        out += f'      <ComponentRef Id="{cid}" />\n'
    out += '    </ComponentGroup>\n'
    return out

data_tree = gen_ref('DataFolder', '        ')
component_group = gen_component_group()

# Generate DLL components for AppComponents
app_components_dlls = ''
for dll in dll_files:
    cid = 'C_' + dll.replace('.', '_').replace('-', '_')
    app_components_dlls += f'      <Component Id="{cid}" Guid="*">\n'
    app_components_dlls += f'        <File Id="F_{cid}" Source="$(var.SourceDir)/{dll}" />\n'
    app_components_dlls += f'      </Component>\n'

pkg = f'''<?xml version="1.0" encoding="UTF-8"?>
<Wix xmlns="http://wixtoolset.org/schemas/v4/wxs">

  <Package Name="Metronome"
           Manufacturer="YourStudio"
           Version="1.0.0.0"
           UpgradeCode="7E579F21-E8A4-4A8E-9B3B-8C9B9A1A2B3C"
           Language="1033">

    <MajorUpgrade DowngradeErrorMessage="A newer version of [ProductName] is already installed." />

    <Icon Id="AppIcon" SourceFile="$(var.SourceDir)/app_icon.ico" />
    <Property Id="ARPPRODUCTICON" Value="AppIcon" />

    <Feature Id="Main">
      <ComponentGroupRef Id="AppComponents" />
      <ComponentGroupRef Id="DataComponents" />
      <ComponentRef Id="DesktopShortcutComponent" />
    </Feature>

    <StandardDirectory Id="ProgramFiles64Folder">
      <Directory Id="INSTALLFOLDER" Name="Metronome">
        <Directory Id="DataFolder" Name="data">
{data_tree}        </Directory>
      </Directory>
    </StandardDirectory>

    <StandardDirectory Id="DesktopFolder">
      <Component Id="DesktopShortcutComponent" Guid="A1B2C3D4-E5F6-4789-8C9D-EF1234567890">
        <Shortcut Id="DesktopShortcut"
                  Name="Metronome"
                  Description="Professional Metronome App"
                  Target="[!MetronomeExe]"
                  WorkingDirectory="INSTALLFOLDER"
                  Icon="AppIcon" />
        <RegistryValue Root="HKCU" Key="Software\\YourStudio\\Metronome" Name="installed" Type="integer" Value="1" KeyPath="yes" />
      </Component>
    </StandardDirectory>

    <ComponentGroup Id="AppComponents" Directory="INSTALLFOLDER">
      <Component Id="MainExecutable" Guid="*">
        <File Id="MetronomeExe" Source="$(var.SourceDir)/metronome.exe" KeyPath="yes" />
      </Component>
      <Component Id="FlutterEngine" Guid="*">
        <File Id="FlutterDll" Source="$(var.SourceDir)/flutter_windows.dll" />
      </Component>
{app_components_dlls}    </ComponentGroup>

{component_group}  </Package>
</Wix>
'''

with open('Package.wxs', 'w', encoding='utf-8') as f:
    f.write(pkg)
print(f'Generated Package.wxs with {len(files)} data files and {len(dll_files)} DLL files')
