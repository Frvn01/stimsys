class Student {
  final String? id;
  final String lastName;
  final String firstName;
  final String? middleName;
  final String usn;
  final String course;
  final String year;
  final String section;
  final String? phone;
  final String? imagePath;
  final DateTime? enrollmentDate;

  Student({
    this.id,
    required this.lastName,
    required this.firstName,
    this.middleName,
    required this.usn,
    required this.course,
    required this.year,
    required this.section,
    this.phone,
    this.imagePath,
    this.enrollmentDate,
  });

  String get fullName {
    if (middleName != null && middleName!.isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  String get yearSection => '$year-$section';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'usn': usn,
      'course': course,
      'year': year,
      'section': section,
      'phone': phone,
      'imagePath': imagePath,
      'enrollmentDate': enrollmentDate?.toIso8601String(),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      lastName: map['lastName'] ?? '',
      firstName: map['firstName'] ?? '',
      middleName: map['middleName'],
      usn: map['usn'] ?? '',
      course: map['course'] ?? '',
      year: map['year'] ?? '',
      section: map['section'] ?? '',
      phone: map['phone'],
      imagePath: map['imagePath'],
      enrollmentDate: map['enrollmentDate'] != null
          ? DateTime.parse(map['enrollmentDate'])
          : null,
    );
  }

  Student copyWith({
    String? id,
    String? lastName,
    String? firstName,
    String? middleName,
    String? usn,
    String? course,
    String? year,
    String? section,
    String? phone,
    String? imagePath,
    DateTime? enrollmentDate,
  }) {
    return Student(
      id: id ?? this.id,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      usn: usn ?? this.usn,
      course: course ?? this.course,
      year: year ?? this.year,
      section: section ?? this.section,
      phone: phone ?? this.phone,
      imagePath: imagePath ?? this.imagePath,
      enrollmentDate: enrollmentDate ?? this.enrollmentDate,
    );
  }
}

// Constants for dropdowns
class StudentConstants {
  static const List<String> courses = ['BSIT', 'BSCS', 'BSBA', 'BSA', 'WAD'];
  static const List<String> years = ['1', '2', '3', '4'];
  static const List<String> sections = ['A', 'B', 'C', 'D', 'E', 'F', 'AB', 'CD', 'EF'];
}