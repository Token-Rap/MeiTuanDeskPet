import hashlib
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/windows_update_manifest.py'

class ManifestTest(unittest.TestCase):
    def test_hash_size_and_download_match_actual_installer(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            dist = root / 'dist/windows'
            dist.mkdir(parents=True)
            installer = dist / 'MeiTuanDeskPet-windows-x64-setup.exe'
            installer.write_bytes(b'packaged installer bytes')
            subprocess.run([sys.executable, str(SCRIPT), '--version', '0.2.0', '--build', '6', '--tag', 'v0.2.0-preview.6'], cwd=root, check=True)
            manifest = json.loads((dist / 'windows-update.json').read_text())
            self.assertEqual(manifest['size'], installer.stat().st_size)
            self.assertEqual(manifest['sha256'], hashlib.sha256(installer.read_bytes()).hexdigest())
            self.assertTrue(manifest['url'].endswith('/v0.2.0-preview.6/' + installer.name))

if __name__ == '__main__':
    unittest.main()
