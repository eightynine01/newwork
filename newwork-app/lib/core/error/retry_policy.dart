import 'dart:math';

/// 재시도 정책 설정
///
/// Exponential backoff 알고리즘을 사용하여 재시도 간격을 관리합니다.
class RetryPolicy {
  /// 최대 재시도 횟수
  final int maxRetries;

  /// 기본 지연 시간 (밀리초)
  final int baseDelayMs;

  /// 최대 지연 시간 (밀리초)
  final int maxDelayMs;

  /// 지터(jitter) 사용 여부 - 동시 재시도 방지
  final bool useJitter;

  /// 지수 배율
  final double multiplier;

  const RetryPolicy({
    this.maxRetries = 3,
    this.baseDelayMs = 1000,
    this.maxDelayMs = 30000,
    this.useJitter = true,
    this.multiplier = 2.0,
  });

  /// API 요청용 기본 정책
  static const api = RetryPolicy(
    maxRetries: 3,
    baseDelayMs: 1000,
    maxDelayMs: 10000,
    useJitter: true,
  );

  /// 백엔드 재시작용 정책
  static const backend = RetryPolicy(
    maxRetries: 3,
    baseDelayMs: 2000,
    maxDelayMs: 30000,
    useJitter: false,
    multiplier: 1.5,
  );

  /// 헬스체크용 정책 (짧은 간격)
  static const healthCheck = RetryPolicy(
    maxRetries: 5,
    baseDelayMs: 500,
    maxDelayMs: 5000,
    useJitter: false,
  );

  /// WebSocket 재연결용 정책
  static const websocket = RetryPolicy(
    maxRetries: 10,
    baseDelayMs: 1000,
    maxDelayMs: 60000,
    useJitter: true,
    multiplier: 1.5,
  );

  /// 재시도 가능한지 확인
  bool canRetry(int currentAttempt) {
    return currentAttempt < maxRetries;
  }

  /// 다음 재시도까지 대기할 시간 계산 (밀리초)
  ///
  /// Exponential backoff: delay = baseDelay * (multiplier ^ attempt)
  /// Jitter를 사용하면 0~delay 사이의 랜덤 값 추가
  int getDelayMs(int attempt) {
    if (attempt <= 0) return baseDelayMs;

    // Exponential backoff 계산
    final exponentialDelay = baseDelayMs * pow(multiplier, attempt - 1);
    var delay = exponentialDelay.toInt();

    // 최대 지연 시간 제한
    delay = delay.clamp(baseDelayMs, maxDelayMs);

    // Jitter 추가 (선택적)
    if (useJitter) {
      final jitter = Random().nextInt((delay * 0.3).toInt());
      delay += jitter;
    }

    return delay;
  }

  /// 다음 재시도까지 대기할 Duration
  Duration getDelay(int attempt) {
    return Duration(milliseconds: getDelayMs(attempt));
  }

  /// 정책 복사본 생성
  RetryPolicy copyWith({
    int? maxRetries,
    int? baseDelayMs,
    int? maxDelayMs,
    bool? useJitter,
    double? multiplier,
  }) {
    return RetryPolicy(
      maxRetries: maxRetries ?? this.maxRetries,
      baseDelayMs: baseDelayMs ?? this.baseDelayMs,
      maxDelayMs: maxDelayMs ?? this.maxDelayMs,
      useJitter: useJitter ?? this.useJitter,
      multiplier: multiplier ?? this.multiplier,
    );
  }

  @override
  String toString() {
    return 'RetryPolicy{maxRetries: $maxRetries, baseDelayMs: $baseDelayMs, '
        'maxDelayMs: $maxDelayMs, useJitter: $useJitter, multiplier: $multiplier}';
  }
}

/// 재시도 실행기
///
/// 주어진 함수를 재시도 정책에 따라 실행합니다.
class RetryExecutor {
  final RetryPolicy policy;

  const RetryExecutor(this.policy);

  /// 함수 실행 및 재시도
  ///
  /// [operation] 실행할 함수
  /// [shouldRetry] 특정 오류에 대해 재시도할지 결정하는 함수 (기본: 모든 오류 재시도)
  /// [onRetry] 재시도 시 호출되는 콜백 (시도 횟수, 오류, 대기 시간)
  Future<T> execute<T>(
    Future<T> Function() operation, {
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    Object? lastError;
    StackTrace? lastStackTrace;

    while (true) {
      attempt++;
      try {
        return await operation();
      } catch (e, st) {
        lastError = e;
        lastStackTrace = st;

        // 재시도 가능 여부 확인
        final canRetryError = shouldRetry?.call(e) ?? true;
        final canRetryCount = policy.canRetry(attempt);

        if (!canRetryError || !canRetryCount) {
          // 재시도 불가 - 원본 오류 다시 던지기
          Error.throwWithStackTrace(e, st);
        }

        // 재시도 대기
        final delay = policy.getDelay(attempt);
        onRetry?.call(attempt, e, delay);

        await Future.delayed(delay);
      }
    }
  }
}

/// 재시도 제한 추적기
///
/// 특정 시간 내 재시도 횟수를 제한합니다.
/// 예: 5분 내 3회 재시작 제한
class RetryLimiter {
  final int maxAttempts;
  final Duration window;
  final List<DateTime> _attempts = [];

  RetryLimiter({
    required this.maxAttempts,
    required this.window,
  });

  /// 재시도 가능 여부 확인
  bool canAttempt() {
    _cleanupOldAttempts();
    return _attempts.length < maxAttempts;
  }

  /// 재시도 시도 기록
  void recordAttempt() {
    _cleanupOldAttempts();
    _attempts.add(DateTime.now());
  }

  /// 남은 재시도 횟수
  int get remainingAttempts {
    _cleanupOldAttempts();
    return maxAttempts - _attempts.length;
  }

  /// 다음 재시도까지 대기 시간 (제한에 걸린 경우)
  Duration? get waitTime {
    if (canAttempt()) return null;

    final oldestAttempt = _attempts.first;
    final resetTime = oldestAttempt.add(window);
    final now = DateTime.now();

    if (resetTime.isAfter(now)) {
      return resetTime.difference(now);
    }
    return null;
  }

  /// 오래된 시도 기록 정리
  void _cleanupOldAttempts() {
    final cutoff = DateTime.now().subtract(window);
    _attempts.removeWhere((attempt) => attempt.isBefore(cutoff));
  }

  /// 모든 기록 초기화
  void reset() {
    _attempts.clear();
  }
}
