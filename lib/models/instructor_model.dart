class Instructor {
  final String? id;
  final String fullName;
  final String? email;
  final DateTime? createdAt;

  Instructor({
    this.id,
    required this.fullName,
    this.email,
    this.createdAt,
  });

  factory Instructor.fromSupabase(Map<String, dynamic> map) {
    return Instructor(
      id: map['id'],
      fullName: map['full_name'] ?? '',
      email: map['email'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }
}
