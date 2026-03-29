sealed class Result<T> {
  const Result();

  bool get isSuccess => this is Success<T>;

  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failure() => null,
  };

  String? get errorOrNull => switch (this) {
    Success() => null,
    Failure(message: final message) => message,
  };

  Result<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      Success(data: final data) => Success(transform(data)),
      Failure(message: final msg, exception: final ex) => Failure(msg, ex),
    };
  }

  Result<T> onSuccess(void Function(T data) callback) {
    if (this case Success(data: final data)) {
      callback(data);
    }
    return this;
  }

  Result<T> onFailure(void Function(String message) callback) {
    if (this case Failure(message: final message)) {
      callback(message);
    }
    return this;
  }

  T getOrThrow() {
    return switch (this) {
      Success(data: final data) => data,
      Failure(message: final msg, exception: final ex) =>
        throw ex ?? Exception(msg),
    };
  }

  T getOrDefault(T defaultValue) {
    return switch (this) {
      Success(data: final data) => data,
      Failure() => defaultValue,
    };
  }

  T getOrElse(T Function(String error) onError) {
    return switch (this) {
      Success(data: final data) => data,
      Failure(message: final msg) => onError(msg),
    };
  }
}

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

extension FutureResultExtension<T> on Future<Result<T>> {
  Future<Result<R>> mapAsync<R>(R Function(T data) transform) async {
    final result = await this;
    return result.map(transform);
  }

  Future<Result<T>> onSuccessAsync(
    Future<void> Function(T data) callback,
  ) async {
    final result = await this;
    if (result case Success(data: final data)) {
      await callback(data);
    }
    return result;
  }

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

Result<T> resultOf<T>(T Function() computation) {
  try {
    return Success(computation());
  } catch (e) {
    return Failure(e.toString(), e is Exception ? e : Exception(e.toString()));
  }
}

Future<Result<T>> asyncResultOf<T>(Future<T> Function() computation) async {
  try {
    final data = await computation();
    return Success(data);
  } catch (e) {
    return Failure(e.toString(), e is Exception ? e : Exception(e.toString()));
  }
}
