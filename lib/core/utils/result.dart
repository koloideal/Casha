/// Result type for handling success and failure cases
/// Uses sealed classes for exhaustive pattern matching
sealed class Result<T> {
  const Result();

  /// Check if result is success
  bool get isSuccess => this is Success<T>;

  /// Check if result is failure
  bool get isFailure => this is Failure<T>;

  /// Get data if success, null otherwise
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  /// Get error if failure, null otherwise
  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(message: final message) => message,
  };

  /// Transform success value
  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      Failure(message: final msg, exception: final ex) => Failure(msg, ex),
    };
  }

  /// Execute callback on success
  Result<T> onSuccess(void Function(T data) callback) {
    if (this case Success(data: final data)) {
      callback(data);
    }
    return this;
  }

  /// Execute callback on failure
  Result<T> onFailure(void Function(String message) callback) {
    if (this case Failure(message: final message)) {
      callback(message);
    }
    return this;
  }

  /// Get data or throw exception
  T getOrThrow() {
    return switch (this) {
      Success(data: final data) => data,
      Failure(message: final msg, exception: final ex) =>
        throw ex ?? Exception(msg),
    };
  }

  /// Get data or return default value
  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Failure() => defaultValue,
    };
  }

  /// Get data or compute from error
  T getOrElse(T Function(String error) onError) {
    return switch (this) {
      Success(data: final data) => data,
      Failure(message: final msg) => onError(msg),
    };
  }
}

/// Success result containing data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  String toString() => 'Success($data)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;
}

/// Failure result containing error message and optional exception
class Failure<T> extends Result<T> {
  final String message;
  final Exception? exception;

  const Failure(this.message, [this.exception]);

  @override
  String toString() =>
      'Failure($message${exception != null ? ', $exception' : ''})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          exception == other.exception;

  @override
  int get hashCode => message.hashCode ^ exception.hashCode;
}

/// Extension for Future<Result<T>>
extension FutureResultExtension<T> on Future<Result<T>> {
  /// Map async result
  Future<Result<R>> mapAsync<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  /// Execute callback on success
  Future<Result<T>> onSuccessAsync(
    Future<void> Function(T data) callback,
  ) async {
    final result = await this;
    if (result case Success(data: final data)) {
      await callback(data);
    }
    return result;
  }

  /// Execute callback on failure
  Future<Result<T>> onFailureAsync(
    Future<void> Function(String message) callback,
  ) async {
    final result = await this;
    if (result case Failure(message: final message)) {
      await callback(message);
    }
    return result;
  }
}

/// Helper to wrap try-catch blocks
Result<T> resultOf<T>(T Function() computation) {
  try {
    return Success(computation());
  } catch (e) {
    return Failure(e.toString(), e is Exception ? e : Exception(e.toString()));
  }
}

/// Helper to wrap async try-catch blocks
Future<Result<T>> asyncResultOf<T>(Future<T> Function() computation) async {
  try {
    final data = await computation();
    return Success(data);
  } catch (e) {
    return Failure(e.toString(), e is Exception ? e : Exception(e.toString()));
  }
}
