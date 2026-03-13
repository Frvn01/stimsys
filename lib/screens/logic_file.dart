import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentManagement extends ChangeNotifier{
 int _usn = 0;
 String _lastName = '-';
 String _firstName = '-';
 String _middleName = '-';
 String _phone = '-';
 String _date = '-';
 String _course = '-';
 int _year = 0;
 String _section  = '-';
 String _profilePicLoc = '';
 final String apiLink = 'http://150.0.0.15/STIMSYS-API'; //always check ip address and change


  int get usn => _usn;
  String get lastName => _lastName;
  String get firstName => _firstName;
  String get middleName => _middleName;
  String get phone => _phone;
  String get date => _date;
  String get course => _course;
  int get year => _year;
  String get section => _section;
  String get profilePicLoc => _profilePicLoc;

  void setUsn(int newUsn) {
    _usn = newUsn;
    notifyListeners();
  }

  Future<void> getStudentInfo(int inputUsn) async {
    Uri uri = Uri.parse('$apiLink/get-student-info-api.php');
    Map<String, dynamic> data = {
      'usn': inputUsn.toString(),
    };

    http.Response response = await http.post(uri, body: data);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body); // ← decode JSON

      if (json['error'] != null) {
        // handle error
      } else {
        _usn        = json['usn'];
        _lastName   = json['last_name'];
        _firstName  = json['first_name'];
        _middleName = json['middle_name'];
        _phone      = json['phone'];
        _date       = json['date_created'];
        _profilePicLoc = json['profile_pic_loc'];
        notifyListeners();
      }
    }
  }
  Future<void> getStudentCourseInfo(int inputUsn) async {
    Uri uri = Uri.parse('$apiLink/get-student-section-api.php');
    Map<String, dynamic> data = {
      'usn': inputUsn.toString(),
    };

    http.Response response = await http.post(uri, body: data);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body); // ← decode JSON

      if (json['error'] != null) {
        // handle error
      } else {
        _usn        = json['usn'];
        _course   = json['student_course'];
        _year  = json['student_year'];
        _section = json['student_section'];
        notifyListeners();
      }
    }
  }
}