"""Create the release updater manifest from the actual packaged EXE bytes."""
import argparse
import hashlib
import json
import re
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--version', required=True)
parser.add_argument('--build', required=True, type=int)
parser.add_argument('--tag', required=True)
parser.add_argument('--repo', default='Token-Rap/MeiTuanDeskPet')
args = parser.parse_args()
version = args.version.removeprefix('v')
if not re.fullmatch(r'\d+\.\d+\.\d+', version) or args.build < 0:
    parser.error('version must be numeric major.minor.patch')
installers = list(Path('dist/windows').glob('*setup*.exe'))
if len(installers) != 1:
    raise RuntimeError('Expected exactly one installer')
installer = installers[0]
manifest = dict(version=version, build=args.build,
                url=f'https://github.com/{args.repo}/releases/download/{args.tag}/{installer.name}',
                size=installer.stat().st_size,
                sha256=hashlib.sha256(installer.read_bytes()).hexdigest())
Path('dist/windows/windows-update.json').write_text(json.dumps(manifest, indent=2)+'\n', encoding='utf-8')
