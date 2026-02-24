import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'models.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'stimsys.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createDb,
    );
  }

  Future<void> _createDb(Database db, int version) async {
    await db.execute('''
      CREATE TABLE quiz_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseName TEXT NOT NULL,
        email TEXT NOT NULL,
        score INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        completedAt TEXT NOT NULL,
        qrCode TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE attendance_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        courseName TEXT NOT NULL,
        email TEXT NOT NULL,
        markedAt TEXT NOT NULL,
        qrCode TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE event_records (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        eventDate TEXT NOT NULL,
        courseName TEXT NOT NULL,
        type TEXT NOT NULL
      )
    ''');

    // Insert default events
    await _insertDefaultEvents(db);
  }

  Future<void> _insertDefaultEvents(Database db) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final in3Days = now.add(const Duration(days: 3));
    final in5Days = now.add(const Duration(days: 5));
    final in7Days = now.add(const Duration(days: 7));

    await db.insert('event_records', {
      'title': 'Mathematics Quiz',
      'description': 'Chapter 1-3 Quiz',
      'eventDate': tomorrow.toIso8601String(),
      'courseName': 'Mathematics',
      'type': 'quiz',
    });

    await db.insert('event_records', {
      'title': 'Physics Assignment Due',
      'description': 'Problem Set 5 Due',
      'eventDate': in3Days.toIso8601String(),
      'courseName': 'Physics',
      'type': 'assignment',
    });

    await db.insert('event_records', {
      'title': 'Chemistry Lab',
      'description': 'Lab Experiment 3',
      'eventDate': in5Days.toIso8601String(),
      'courseName': 'Chemistry',
      'type': 'lab',
    });

    await db.insert('event_records', {
      'title': 'Computer Science Exam',
      'description': 'Midterm Exam',
      'eventDate': in7Days.toIso8601String(),
      'courseName': 'Computer Science',
      'type': 'exam',
    });
  }

  // QUIZ OPERATIONS
  Future<int> insertQuizRecord(QuizRecord record) async {
    final db = await database;
    return await db.insert('quiz_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<QuizRecord>> getQuizRecords() async {
    final db = await database;
    final maps = await db.query('quiz_records');
    return List.generate(maps.length, (i) => QuizRecord.fromMap(maps[i]));
  }

  Future<List<QuizRecord>> getQuizRecordsByCourse(String courseName) async {
    final db = await database;
    final maps = await db.query(
      'quiz_records',
      where: 'courseName = ?',
      whereArgs: [courseName],
    );
    return List.generate(maps.length, (i) => QuizRecord.fromMap(maps[i]));
  }

  Future<QuizRecord?> getLatestQuizRecord(String courseName) async {
    final db = await database;
    final maps = await db.query(
      'quiz_records',
      where: 'courseName = ?',
      whereArgs: [courseName],
      orderBy: 'completedAt DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return QuizRecord.fromMap(maps.first);
    }
    return null;
  }

  // ATTENDANCE OPERATIONS
  Future<int> insertAttendanceRecord(AttendanceRecord record) async {
    final db = await database;
    return await db.insert('attendance_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AttendanceRecord>> getAttendanceRecords() async {
    final db = await database;
    final maps = await db.query('attendance_records');
    return List.generate(maps.length, (i) => AttendanceRecord.fromMap(maps[i]));
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsByCourse(
      String courseName) async {
    final db = await database;
    final maps = await db.query(
      'attendance_records',
      where: 'courseName = ?',
      whereArgs: [courseName],
    );
    return List.generate(maps.length, (i) => AttendanceRecord.fromMap(maps[i]));
  }

  Future<int> getAttendanceCount(String courseName) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM attendance_records WHERE courseName = ?',
      [courseName],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // EVENT OPERATIONS
  Future<int> insertEventRecord(EventRecord record) async {
    final db = await database;
    return await db.insert('event_records', record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<EventRecord>> getEventRecords() async {
    final db = await database;
    final maps = await db.query('event_records');
    return List.generate(maps.length, (i) => EventRecord.fromMap(maps[i]));
  }

  Future<List<EventRecord>> getUpcomingEvents() async {
    final db = await database;
    final now = DateTime.now();
    final maps = await db.query(
      'event_records',
      where: 'eventDate > ?',
      whereArgs: [now.toIso8601String()],
      orderBy: 'eventDate ASC',
    );
    return List.generate(maps.length, (i) => EventRecord.fromMap(maps[i]));
  }

  Future<List<EventRecord>> getEventsByDate(DateTime date) async {
    final db = await database;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay =
        DateTime(date.year, date.month, date.day, 23, 59, 59);
    final maps = await db.query(
      'event_records',
      where: 'eventDate >= ? AND eventDate <= ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
    );
    return List.generate(maps.length, (i) => EventRecord.fromMap(maps[i]));
  }

  Future<List<EventRecord>> getEventsByCourse(String courseName) async {
    final db = await database;
    final maps = await db.query(
      'event_records',
      where: 'courseName = ?',
      whereArgs: [courseName],
      orderBy: 'eventDate DESC',
    );
    return List.generate(maps.length, (i) => EventRecord.fromMap(maps[i]));
  }

  Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('event_records', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> clear() async {
    final db = await database;
    await db.delete('quiz_records');
    await db.delete('attendance_records');
    await db.delete('event_records');
  }
}
