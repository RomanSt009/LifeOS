import '../../domain/core/lifeos_identity.dart';

class GetLifeOsIdentity {
  const GetLifeOsIdentity();

  LifeOsIdentity call() {
    return const LifeOsIdentity(
      applicationName: 'LifeOS',
      applicationDescription: 'Personal Operating System',
    );
  }
}
