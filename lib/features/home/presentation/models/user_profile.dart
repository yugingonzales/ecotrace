import '../../../auth/domain/monitoring_staff.dart';

class UserProfile {
  const UserProfile({
    required this.username,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.staffType,
    required this.staffId,
    required this.staffNumber,
    required this.email,
    required this.homeAddress,
    required this.contactNumber,
  });

  final String username;
  final String firstName;
  final String middleName;
  final String lastName;
  final StaffType staffType;
  final String staffId;
  final String staffNumber;
  final String email;
  final String homeAddress;
  final String contactNumber;

  String get displayName => [
    firstName,
    middleName,
    lastName,
  ].where((part) => part.trim().isNotEmpty).join(' ');

  String get initials => [firstName, lastName]
      .where((part) => part.trim().isNotEmpty)
      .map((part) => part[0].toUpperCase())
      .join();

  UserProfile copyWith({
    String? email,
    String? homeAddress,
    String? contactNumber,
  }) => UserProfile(
    username: username,
    firstName: firstName,
    middleName: middleName,
    lastName: lastName,
    staffType: staffType,
    staffId: staffId,
    staffNumber: staffNumber,
    email: email ?? this.email,
    homeAddress: homeAddress ?? this.homeAddress,
    contactNumber: contactNumber ?? this.contactNumber,
  );
}

const currentUserProfile = UserProfile(
  username: 'monitoring.staff',
  firstName: 'Monitoring',
  middleName: '',
  lastName: 'Staff',
  staffType: StaffType.staff,
  staffId: 'STAFF-00042',
  staffNumber: '239038',
  email: 'monitoring.staff@ecotrace.local',
  homeAddress: 'UEP Catarman, Northern Samar',
  contactNumber: '+63 917 000 0042',
);
