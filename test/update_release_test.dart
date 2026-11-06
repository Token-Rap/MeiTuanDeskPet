import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meituan_desk_pet/desktop/update_release.dart';

void main() {
  test('release comparison supports build updates and never downgrades', () {
    expect(AppVersion.parse('0.2.0', 7).compareTo(AppVersion.parse('0.2.0', 6)), greaterThan(0));
    expect(AppVersion.parse('0.2.1', 1).compareTo(AppVersion.parse('0.2.0', 99)), greaterThan(0));
    expect(AppVersion.parse('0.1.9', 999).compareTo(AppVersion.parse('0.2.0', 1)), lessThan(0));
    expect(AppVersion.parse('0.2.0', 6).compareTo(AppVersion.parse('0.2.0', 6)), 0);
  });
  Map<String, dynamic> manifest() => {
    'version': '0.2.0', 'build': 7, 'size': 100,
    'url': 'https://github.com/Token-Rap/MeiTuanDeskPet/releases/download/v0.2.0-preview.7/setup.exe',
    'sha256': 'a' * 64,
  };
  test('accepts checksummed installers belonging to this project', () {
    expect(UpdateRelease.fromJson(manifest()).build, 7);
  });
  test('rejects wrong project, HTTP, malformed hashes and excessive downloads', () {
    for (final patch in [
      {'url': 'https://github.com/another/project/releases/download/v1/setup.exe'},
      {'url': 'http://github.com/Token-Rap/MeiTuanDeskPet/releases/download/v1/setup.exe'},
      {'sha256': 'invalid'}, {'size': 999999999}, {'version': 'latest'},
    ]) {
      expect(() => UpdateRelease.fromJson({...manifest(), ...patch}), throwsFormatException);
    }
  });
  test('installer must match both release length and SHA-256 before execution', () async {
    final folder = await Directory.systemTemp.createTemp('meituan-update-test-');
    addTearDown(() => folder.delete(recursive: true));
    final file = File('${folder.path}/setup.exe');
    final bytes = [1, 2, 3, 4];
    await file.writeAsBytes(bytes);
    final release = UpdateRelease('0.2.0', 6, Uri.parse(manifest()['url'] as String),
        sha256.convert(bytes).toString(), bytes.length);
    expect(await installerMatches(file, release), isTrue);
    await file.writeAsBytes([1, 2, 3, 5]);
    expect(await installerMatches(file, release), isFalse);
    await file.writeAsBytes([1, 2]);
    expect(await installerMatches(file, release), isFalse);
  });

}
