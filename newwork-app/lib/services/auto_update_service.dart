import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// 업데이트 정보
class UpdateInfo {
  final String latestVersion;
  final String currentVersion;
  final bool updateAvailable;
  final String? releaseNotes;
  final String? downloadUrl;
  final DateTime? releaseDate;

  UpdateInfo({
    required this.latestVersion,
    required this.currentVersion,
    required this.updateAvailable,
    this.releaseNotes,
    this.downloadUrl,
    this.releaseDate,
  });
}

/// 자동 업데이트 설정
class AutoUpdateSettings {
  final bool enabled;
  final Duration checkInterval;
  final bool autoDownload;
  final bool notifyOnUpdate;

  const AutoUpdateSettings({
    this.enabled = true,
    this.checkInterval = const Duration(hours: 24),
    this.autoDownload = false,
    this.notifyOnUpdate = true,
  });
}

/// 자동 업데이트 서비스
///
/// GitHub Releases를 사용하여 새 버전을 확인하고 업데이트를 관리합니다.
class AutoUpdateService {
  static const String _githubRepo = 'your-org/newwork';
  static const String _githubApiBase = 'https://api.github.com';

  Timer? _checkTimer;
  AutoUpdateSettings _settings;
  UpdateInfo? _cachedUpdateInfo;
  DateTime? _lastCheckTime;

  // 콜백
  void Function(UpdateInfo info)? onUpdateAvailable;
  void Function(String error)? onCheckError;
  void Function()? onUpToDate;

  // 스트림
  final StreamController<UpdateInfo?> _updateController =
      StreamController<UpdateInfo?>.broadcast();

  AutoUpdateService({
    AutoUpdateSettings? settings,
  }) : _settings = settings ?? const AutoUpdateSettings();

  /// 업데이트 정보 스트림
  Stream<UpdateInfo?> get updateStream => _updateController.stream;

  /// 현재 설정
  AutoUpdateSettings get settings => _settings;

  /// 마지막 확인 시간
  DateTime? get lastCheckTime => _lastCheckTime;

  /// 캐시된 업데이트 정보
  UpdateInfo? get cachedUpdateInfo => _cachedUpdateInfo;

  /// 자동 업데이트 확인 시작
  void startAutoCheck() {
    if (!_settings.enabled) return;

    // 즉시 한 번 확인
    checkForUpdates();

    // 주기적 확인 타이머 시작
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(_settings.checkInterval, (_) {
      checkForUpdates();
    });

    print('[AutoUpdate] 자동 업데이트 확인 시작 (간격: ${_settings.checkInterval.inHours}시간)');
  }

  /// 자동 업데이트 확인 중지
  void stopAutoCheck() {
    _checkTimer?.cancel();
    _checkTimer = null;
    print('[AutoUpdate] 자동 업데이트 확인 중지');
  }

  /// 설정 업데이트
  void updateSettings(AutoUpdateSettings newSettings) {
    final wasEnabled = _settings.enabled;
    _settings = newSettings;

    if (newSettings.enabled && !wasEnabled) {
      startAutoCheck();
    } else if (!newSettings.enabled && wasEnabled) {
      stopAutoCheck();
    } else if (newSettings.enabled) {
      // 간격이 변경되었을 수 있으므로 타이머 재시작
      stopAutoCheck();
      startAutoCheck();
    }
  }

  /// 업데이트 확인
  Future<UpdateInfo?> checkForUpdates({bool force = false}) async {
    // 캐시 확인 (강제 확인이 아닌 경우)
    if (!force && _cachedUpdateInfo != null && _lastCheckTime != null) {
      final cacheAge = DateTime.now().difference(_lastCheckTime!);
      if (cacheAge < const Duration(minutes: 5)) {
        return _cachedUpdateInfo;
      }
    }

    try {
      print('[AutoUpdate] 업데이트 확인 중...');

      final currentVersion = await _getCurrentVersion();
      final latestRelease = await _fetchLatestRelease();

      if (latestRelease == null) {
        print('[AutoUpdate] 최신 릴리스 정보를 가져올 수 없습니다');
        return null;
      }

      final latestVersion = latestRelease['tag_name']?.toString().replaceFirst('v', '') ?? '';
      final updateAvailable = _isNewerVersion(latestVersion, currentVersion);

      _cachedUpdateInfo = UpdateInfo(
        latestVersion: latestVersion,
        currentVersion: currentVersion,
        updateAvailable: updateAvailable,
        releaseNotes: latestRelease['body'] as String?,
        downloadUrl: _getDownloadUrl(latestRelease),
        releaseDate: latestRelease['published_at'] != null
            ? DateTime.parse(latestRelease['published_at'] as String)
            : null,
      );

      _lastCheckTime = DateTime.now();

      // 스트림에 전파
      if (!_updateController.isClosed) {
        _updateController.add(_cachedUpdateInfo);
      }

      // 콜백 호출
      if (updateAvailable) {
        print('[AutoUpdate] 새 버전 발견: $latestVersion (현재: $currentVersion)');
        onUpdateAvailable?.call(_cachedUpdateInfo!);
      } else {
        print('[AutoUpdate] 최신 버전입니다: $currentVersion');
        onUpToDate?.call();
      }

      return _cachedUpdateInfo;

    } catch (e) {
      print('[AutoUpdate] 업데이트 확인 실패: $e');
      onCheckError?.call(e.toString());
      return null;
    }
  }

  /// 현재 버전 가져오기
  Future<String> _getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }

  /// GitHub에서 최신 릴리스 가져오기
  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    try {
      final response = await http.get(
        Uri.parse('$_githubApiBase/repos/$_githubRepo/releases/latest'),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      // 릴리스가 없는 경우 (개발 중)
      if (response.statusCode == 404) {
        return null;
      }

      print('[AutoUpdate] GitHub API 오류: ${response.statusCode}');
      return null;

    } catch (e) {
      print('[AutoUpdate] GitHub API 요청 실패: $e');
      return null;
    }
  }

  /// 버전 비교 (newer > current인지 확인)
  bool _isNewerVersion(String newer, String current) {
    try {
      final newerParts = newer.split('.').map(int.parse).toList();
      final currentParts = current.split('.').map(int.parse).toList();

      for (int i = 0; i < newerParts.length && i < currentParts.length; i++) {
        if (newerParts[i] > currentParts[i]) return true;
        if (newerParts[i] < currentParts[i]) return false;
      }

      return newerParts.length > currentParts.length;
    } catch (e) {
      // 버전 파싱 실패 시 문자열 비교
      return newer.compareTo(current) > 0;
    }
  }

  /// 플랫폼별 다운로드 URL 가져오기
  String? _getDownloadUrl(Map<String, dynamic> release) {
    final assets = release['assets'] as List<dynamic>?;
    if (assets == null || assets.isEmpty) {
      return release['html_url'] as String?;
    }

    String? downloadUrl;

    for (final asset in assets) {
      final name = asset['name']?.toString().toLowerCase() ?? '';

      if (Platform.isMacOS && name.contains('.dmg')) {
        downloadUrl = asset['browser_download_url'] as String?;
        break;
      } else if (Platform.isWindows && name.contains('.exe')) {
        downloadUrl = asset['browser_download_url'] as String?;
        break;
      } else if (Platform.isLinux && name.contains('.appimage')) {
        downloadUrl = asset['browser_download_url'] as String?;
        break;
      }
    }

    return downloadUrl ?? release['html_url'] as String?;
  }

  /// 다운로드 페이지 열기
  Future<void> openDownloadPage() async {
    final url = _cachedUpdateInfo?.downloadUrl;
    if (url == null) {
      print('[AutoUpdate] 다운로드 URL이 없습니다');
      return;
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      print('[AutoUpdate] URL을 열 수 없습니다: $url');
    }
  }

  /// 릴리스 노트 페이지 열기
  Future<void> openReleaseNotes() async {
    final url = 'https://github.com/$_githubRepo/releases';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// 리소스 정리
  void dispose() {
    stopAutoCheck();
    _updateController.close();
  }
}
