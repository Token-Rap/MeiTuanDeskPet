import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'update_release.dart';

class DesktopShell {
  static final instance = DesktopShell();
  static const _channel = MethodChannel('meituan/desktop');
  VoidCallback? onSwitchCat;
  bool _busy = false;
  bool _installing = false;
  bool _automatic = true;
  late AppVersion _current;
  static const _preview = String.fromEnvironment('UPDATE_CHANNEL') == 'preview';

  Future<void> initialize() async {
    if (!Platform.isWindows) return;
    final info = await _channel.invokeMapMethod<String, dynamic>('initialize');
    _automatic = info!['automatic'] as bool;
    _current = AppVersion.parse(info['version'] as String, info['build'] as int);
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'switchCat': onSwitchCat?.call();
        case 'checkUpdate': unawaited(check(manual: true));
        case 'installFinished':
          _installing = false;
          if (call.arguments != 0) await _notify('安装未完成，可稍后重试更新。');
        case 'toggleAuto':
          _automatic = !_automatic;
          await _channel.invokeMethod<void>('setAutomatic', _automatic);
          if (_automatic) unawaited(check());
      }
    });
    Timer(const Duration(seconds: 15), () {
      unawaited(check());
      Timer.periodic(const Duration(hours: 4), (_) => unawaited(check()));
    });
  }

  Future<void> _notify(String message) =>
      _channel.invokeMethod<void>('notify', message);

  // Requests are bounded and only follow HTTPS GitHub asset redirects.
  Future<HttpClientResponse> _request(HttpClient client, Uri uri) async {
    for (var redirect = 0; redirect < 8; redirect++) {
      if (uri.scheme != 'https' || uri.userInfo.isNotEmpty ||
          !(uri.host == 'api.github.com' || uri.host == 'github.com' ||
            uri.host.endsWith('.githubusercontent.com'))) {
        throw const HttpException('Unexpected update host');
      }
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
      request.followRedirects = false;
      request.headers.set('User-Agent', 'MeiTuanDeskPet-Updater');
      final response = await request.close().timeout(const Duration(seconds: 30));
      if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
        final location = response.headers.value('location');
        await response.drain<void>();
        if (location == null) throw const HttpException('Missing redirect');
        uri = uri.resolve(location);
        continue;
      }
      if (response.statusCode != 200) {
        await response.drain<void>();
        throw HttpException('Update server returned ${response.statusCode}');
      }
      return response;
    }
    throw const HttpException('Too many update redirects');
  }

  Future<dynamic> _json(HttpClient client, Uri uri, int limit) async {
    final response = await _request(client, uri);
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 30))) {
      bytes.addAll(chunk);
      if (bytes.length > limit) throw const FormatException('Update metadata too large');
    }
    return jsonDecode(utf8.decode(bytes));
  }

  Future<void> check({bool manual = false}) async {
    if (_busy || _installing || (!manual && !_automatic)) return;
    _busy = true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    Directory? staging;
    try {
      final releases = await _json(client,
          Uri.https('api.github.com', '/repos/Token-Rap/MeiTuanDeskPet/releases',
              {'per_page': '20'}), 2 * 1024 * 1024) as List;
      UpdateRelease? latest;
      for (final release in releases) {
        if (release['draft'] == true || (!_preview && release['prerelease'] == true)) continue;
        final assets = release['assets'] as List;
        final manifests = assets.where((a) => a['name'] == 'windows-update.json');
        if (manifests.isEmpty) continue;
        final manifestUrl = Uri.parse(manifests.first['browser_download_url'] as String);
        final candidate = UpdateRelease.fromJson(Map<String, dynamic>.from(
            await _json(client, manifestUrl, 64 * 1024) as Map));
        if (latest == null || candidate.identity.compareTo(latest.identity) > 0) latest = candidate;
      }
      if (latest == null || latest.identity.compareTo(_current) <= 0) {
        if (manual) await _notify('当前已是最新版本。');
        return;
      }
      if (!manual && !_automatic) return;
      await _notify('发现新版 ${latest.version}（${latest.build}），正在下载安装。');
      staging = await Directory.systemTemp.createTemp('meituan-update-');
      final installer = File('${staging.path}${Platform.pathSeparator}setup.exe');
      final sink = installer.openWrite();
      var received = 0;
      try {
        final response = await _request(client, latest.url);
        await for (final chunk in response.timeout(const Duration(seconds: 30))) {
          received += chunk.length;
          if (received > latest.size) throw const FormatException('Installer size mismatch');
          sink.add(chunk);
        }
      } finally {
        await sink.close();
      }
      if (received != latest.size || !await installerMatches(installer, latest)) {
        throw const FormatException('Installer verification failed');
      }
      if (!manual && !_automatic) return;
      await _notify('下载校验完成，正在安装更新；完成后会自动启动。');
      _installing = true;
      final launched = await _channel.invokeMethod<bool>('install', installer.path);
      if (launched != true) {
        _installing = false;
        throw const FileSystemException('Installer did not start');
      }
      // The installer owns its file from now on; do not remove it while running.
      staging = null;
    } catch (error) {
      _installing = false;
      if (manual) await _notify('更新未完成，请稍后通过托盘“检查并安装更新”重试。');
      debugPrint('Update check failed: ${error.runtimeType}');
    } finally {
      client.close(force: true);
      if (staging != null && await staging.exists()) await staging.delete(recursive: true);
      _busy = false;
    }
  }
}
