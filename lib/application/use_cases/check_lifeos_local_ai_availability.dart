import '../ai/lifeos_local_ai_availability.dart';

final class CheckLifeOsLocalAiAvailability {
  const CheckLifeOsLocalAiAvailability(this._reader);

  final LifeOsLocalAiAvailabilityReader _reader;

  Future<LifeOsLocalAiAvailability> call() => _reader.read();
}
