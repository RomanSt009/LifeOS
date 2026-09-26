import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/application/ai/lifeos_local_ai_availability.dart';
import 'package:lifeos/application/use_cases/check_lifeos_local_ai_availability.dart';

void main() {
  test('returns the typed availability from the Application port', () async {
    final reader = _FakeAvailabilityReader(
      LifeOsLocalAiAvailability.runtimeAvailableModelAvailable,
    );
    final checkAvailability = CheckLifeOsLocalAiAvailability(reader);

    await expectLater(
      checkAvailability(),
      completion(LifeOsLocalAiAvailability.runtimeAvailableModelAvailable),
    );
    expect(reader.readCount, 1);
  });
}

final class _FakeAvailabilityReader implements LifeOsLocalAiAvailabilityReader {
  _FakeAvailabilityReader(this.result);

  final LifeOsLocalAiAvailability result;
  var readCount = 0;

  @override
  Future<LifeOsLocalAiAvailability> read() async {
    readCount += 1;
    return result;
  }
}
