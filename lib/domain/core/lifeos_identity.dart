class LifeOsIdentity {
  const LifeOsIdentity({
    required this.applicationName,
    required this.applicationDescription,
  });

  final String applicationName;
  final String applicationDescription;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LifeOsIdentity &&
            applicationName == other.applicationName &&
            applicationDescription == other.applicationDescription;
  }

  @override
  int get hashCode => Object.hash(applicationName, applicationDescription);
}
