import 'package:flutter/foundation.dart';

class Instructor {
  final String? id;
  final String fullName;
  final String? email;
  final String? department;
  final String? phone;
  final String? qrToken;
  final bool qrUsed;
  final String? sessionToken;
  final bool isActive;
  final DateTime? createdAt;

  Instructor({
    this.id,
    required this.fullName,
    this.email,
    this.department,
    this.phone,
    this.qrToken,
    this.qrUsed = false,
    this.sessionToken,
    this.isActive = true,
    this.createdAt,
  });

  factory Instructor.fromSupabase(Map<String, dynamic> map) {
    return Instructor(
      id: map['id']?.toString(),
      fullName: map['full_name'] ?? '',
      email: map['email'],
      department: map['department'],
      phone: map['phone'],
      qrToken: map['qr_token'],
      qrUsed: map['qr_used'] ?? false,
      sessionToken: map['session_token'],
      isActive: map['is_active'] ?? true,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'full_name': fullName,
      if (email != null) 'email': email,
      if (department != null) 'department': department,
      if (phone != null) 'phone': phone,
      if (qrToken != null) 'qr_token': qrToken,
      'qr_used': qrUsed,
      if (sessionToken != null) 'session_token': sessionToken,
      'is_active': isActive,
    };
  }

  Instructor copyWith({
    String? id,
    String? fullName,
    String? email,
    String? department,
    String? phone,
    String? qrToken,
    bool? qrUsed,
    String? sessionToken,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Instructor(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      department: department ?? this.department,
      phone: phone ?? this.phone,
      qrToken: qrToken ?? this.qrToken,
      qrUsed: qrUsed ?? this.qrUsed,
      sessionToken: sessionToken ?? this.sessionToken,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
