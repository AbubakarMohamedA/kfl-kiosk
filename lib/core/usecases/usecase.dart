abstract class UseCase<T, Params> {
  Future<T> call(Params params);
}

abstract class UseCaseNoParams<T> {
  Future<T> call();
}

abstract class StreamUseCase<T, Params> {
  Stream<T> call(Params params);
}

abstract class StreamUseCaseNoParams<T> {
  Stream<T> call();
}

class NoParams {
  const NoParams();
}