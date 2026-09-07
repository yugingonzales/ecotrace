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
    required this.staffId,
    required this.staffNumber,
    required this.passwordHash,
    required this.staffType,
  });

  final String staffId;
  final String staffNumber;
  final String passwordHash;
  final StaffType staffType;
}
