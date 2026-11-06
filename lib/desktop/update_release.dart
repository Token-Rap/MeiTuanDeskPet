import 'dart:io';

import 'package:crypto/crypto.dart';

class AppVersion implements Comparable<AppVersion> {
  AppVersion(this.parts, this.build);
  final List<int> parts;
  final int build;

  factory AppVersion.parse(String version, int build) {
    if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) || build < 0) {
      throw const FormatException('Invalid update version');
    }
    return AppVersion(version.split('.').map(int.parse).toList(), build);
  }

  @override
  int compareTo(AppVersion other) {
    for (var i = 0; i < 3; i++) {
      final result = parts[i].compareTo(other.parts[i]);
      if (result != 0) return result;
    }
    return build.compareTo(other.build);
  }
}

class UpdateRelease {
  UpdateRelease(this.version, this.build, this.url, this.sha256, this.size);
  final String version;
  final int build;
  final Uri url;
  final String sha256;
  final int size;

  AppVersion get identity => AppVersion.parse(version, build);

  factory UpdateRelease.fromJson(Map<String, dynamic> json) {
    final version = json['version'] as String;
    final build = json['build'] as int;
    AppVersion.parse(version, build);
    final url = Uri.parse(json['url'] as String);
    final hash = json['sha256'] as String;
    final size = json['size'] as int;
    if (url.scheme != 'https' || url.host != 'github.com' ||
        !url.path.startsWith('/Token-Rap/MeiTuanDeskPet/releases/download/') ||
        !url.path.endsWith('.exe') || url.userInfo.isNotEmpty ||
        url.hasQuery || url.hasFragment ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) || size < 1 || size > 256 * 1024 * 1024) {
      throw const FormatException('Invalid update installer');
    }
    return UpdateRelease(version, build, url, hash, size);
  }
}

Future<bool> installerMatches(File file, UpdateRelease release) async {
  if (await file.length() != release.size) return false;
  final digest = await sha256.bind(file.openRead()).first;
  return digest.toString() == release.sha256;
}
