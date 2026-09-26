enum LifeOsLocalAiAvailability {
  runtimeUnavailable,
  runtimeAvailableModelMissing,
  runtimeAvailableModelAvailable,
}

enum LifeOsLocalAiAvailabilityFailure { malformedResponse, unexpectedTransport }

final class LifeOsLocalAiAvailabilityException implements Exception {
  const LifeOsLocalAiAvailabilityException(this.failure);

  final LifeOsLocalAiAvailabilityFailure failure;

  @override
  String toString() => 'LifeOsLocalAiAvailabilityException($failure)';
}

abstract interface class LifeOsLocalAiAvailabilityReader {
  Future<LifeOsLocalAiAvailability> read();
}
