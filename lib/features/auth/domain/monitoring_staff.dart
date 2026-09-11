enum StaffType { intern, paidVolunteer, staff }

extension StaffTypeLabel on StaffType {
  String get label {
    switch (this) {
      case StaffType.intern:
        return 'Intern';
      case StaffType.paidVolunteer:
        return 'Paid volunteer';
      case StaffType.staff:
        return 'Staff';
    }
  }
}

class MonitoringStaff {
  const MonitoringStaff({
    required this.username,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.passwordHash,
    required this.staffType,
  });

  final String username;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String passwordHash;
  final StaffType staffType;
}
