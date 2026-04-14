class Student {
  final String? id;
  final String usn;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String course;
  final String yearLevel;
  final String section;
  final String? phone;
  final String? profileImageUrl;
  final bool isConfirmed;
  final DateTime? createdAt;

  Student({
    this.id,
    required this.usn,
    required this.lastName,
    required this.firstName,
    this.middleName,
    required this.course,
    required this.yearLevel,
    required this.section,
    this.phone,
    this.profileImageUrl,
    this.isConfirmed = false,
    this.createdAt,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get yearSection => '$yearLevel-$section';

  Map<String, dynamic> toSupabase() {
    return {
      'usn': usn,
      'last_name': lastName,
      'first_name': firstName,
      'middle_name': middleName,
      'course': course,
      'year_level': yearLevel,
      'section': section,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'is_confirmed': isConfirmed,
    };
  }

  factory Student.fromSupabase(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      usn: map['usn'] ?? '',
      lastName: map['last_name'] ?? '',
      firstName: map['first_name'] ?? '',
      middleName: map['middle_name'],
      course: map['course'] ?? '',
      yearLevel: map['year_level'] ?? '',
      section: map['section'] ?? '',
      phone: map['phone'],
      profileImageUrl: map['profile_image_url'],
      isConfirmed: map['is_confirmed'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }

  Student copyWith({
    String? id,
    String? usn,
    String? lastName,
    String? firstName,
    String? middleName,
    String? course,
    String? yearLevel,
    String? section,
    String? phone,
    String? profileImageUrl,
    bool? isConfirmed,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      usn: usn ?? this.usn,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section ?? this.section,
      phone: phone ?? this.phone,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class StudentConstants {
  static const List<String> courses = ['BSIT', 'BSCS', 'BSBA', 'BSA', 'WAD'];
  static const List<String> years = ['1', '2', '3', '4'];
  static const List<String> sections = ['A', 'B', 'C', 'D', 'E', 'F', 'AB', 'CD', 'EF'];
}