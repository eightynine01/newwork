/// 앱 오류 카테고리
///
/// 오류 유형에 따라 다른 복구 전략을 적용합니다.
enum ErrorCategory {
  /// API 연결 오류 - HTTP 상태 코드, 타임아웃
  api,

  /// 백엔드 크래시 - 프로세스 종료, 헬스체크 실패
  backend,

  /// UI 렌더링 오류 - Widget 빌드 실패
  render,

  /// 런타임 오류 - 예상치 못한 예외
  runtime,
}

/// 오류 심각도
enum ErrorSeverity {
  /// 낮음 - 사용자에게 알리지 않고 자동 복구
  low,

  /// 중간 - 사용자에게 알림, 자동 복구 시도
  medium,

  /// 높음 - 사용자 개입 필요
  high,

  /// 치명적 - 앱 재시작 필요
  critical,
}

/// 앱 오류 모델
///
/// 모든 오류를 통합된 형식으로 관리합니다.
class AppError {
  final String id;
  final ErrorCategory category;
  final ErrorSeverity severity;
  final String message;
  final String? technicalDetails;
  final Object? originalError;
  final StackTrace? stackTrace;
  final DateTime timestamp;
  final int retryCount;
  final bool isRecoverable;

  AppError({
    required this.category,
    required this.message,
    this.severity = ErrorSeverity.medium,
    this.technicalDetails,
    this.originalError,
    this.stackTrace,
    this.retryCount = 0,
    this.isRecoverable = true,
  })  : id = _generateId(),
        timestamp = DateTime.now();

  static String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// API 오류 생성 팩토리
  factory AppError.api({
    required String message,
    int? statusCode,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    final severity = _getSeverityFromStatusCode(statusCode);
    return AppError(
      category: ErrorCategory.api,
      message: message,
      severity: severity,
      technicalDetails: statusCode != null ? 'HTTP $statusCode' : null,
      originalError: originalError,
      stackTrace: stackTrace,
      isRecoverable: statusCode == null || statusCode >= 500 || statusCode == 408,
    );
  }

  /// 백엔드 오류 생성 팩토리
  factory AppError.backend({
    required String message,
    int? exitCode,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      category: ErrorCategory.backend,
      message: message,
      severity: ErrorSeverity.high,
      technicalDetails: exitCode != null ? 'Exit code: $exitCode' : null,
      originalError: originalError,
      stackTrace: stackTrace,
      isRecoverable: true,
    );
  }

  /// UI 렌더링 오류 생성 팩토리
  factory AppError.render({
    required String message,
    Object? originalError,
    StackTrace? stackTrace,
  }) {
    return AppError(
      category: ErrorCategory.render,
      message: message,
      severity: ErrorSeverity.medium,
      originalError: originalError,
      stackTrace: stackTrace,
      isRecoverable: true,
    );
  }

  /// 런타임 오류 생성 팩토리
  factory AppError.runtime({
    required String message,
    Object? originalError,
    StackTrace? stackTrace,
    bool isRecoverable = true,
  }) {
    return AppError(
      category: ErrorCategory.runtime,
      message: message,
      severity: isRecoverable ? ErrorSeverity.medium : ErrorSeverity.critical,
      originalError: originalError,
      stackTrace: stackTrace,
      isRecoverable: isRecoverable,
    );
  }

  static ErrorSeverity _getSeverityFromStatusCode(int? statusCode) {
    if (statusCode == null) return ErrorSeverity.medium;
    if (statusCode >= 500) return ErrorSeverity.high;
    if (statusCode == 408) return ErrorSeverity.low; // Timeout
    if (statusCode >= 400) return ErrorSeverity.medium;
    return ErrorSeverity.low;
  }

  /// 재시도 횟수를 증가시킨 새 오류 반환
  AppError incrementRetry() {
    return AppError(
      category: category,
      message: message,
      severity: severity,
      technicalDetails: technicalDetails,
      originalError: originalError,
      stackTrace: stackTrace,
      retryCount: retryCount + 1,
      isRecoverable: isRecoverable,
    );
  }

  /// 사용자 친화적 메시지
  String get userMessage {
    switch (category) {
      case ErrorCategory.api:
        return '서버 연결에 문제가 있습니다. 잠시 후 다시 시도해주세요.';
      case ErrorCategory.backend:
        return '백엔드 서비스에 문제가 발생했습니다. 재시작을 시도합니다.';
      case ErrorCategory.render:
        return '화면 표시 중 문제가 발생했습니다.';
      case ErrorCategory.runtime:
        return '예상치 못한 오류가 발생했습니다.';
    }
  }

  @override
  String toString() {
    return 'AppError{id: $id, category: $category, severity: $severity, '
        'message: $message, retryCount: $retryCount}';
  }
}

/// API 예외
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? responseBody;

  ApiException(this.message, {this.statusCode, this.responseBody});

  @override
  String toString() => 'ApiException: $message (status: $statusCode)';

  /// AppError로 변환
  AppError toAppError() {
    return AppError.api(
      message: message,
      statusCode: statusCode,
      originalError: this,
    );
  }
}

/// 백엔드 크래시 예외
class BackendCrashException implements Exception {
  final String message;
  final int? exitCode;

  BackendCrashException(this.message, {this.exitCode});

  @override
  String toString() => 'BackendCrashException: $message (exit: $exitCode)';

  /// AppError로 변환
  AppError toAppError() {
    return AppError.backend(
      message: message,
      exitCode: exitCode,
      originalError: this,
    );
  }
}
