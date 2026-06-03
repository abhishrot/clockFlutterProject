import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Allow extending and mocking for testing
  DatabaseHelper();
  static DatabaseHelper instance = DatabaseHelper();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'user_credentials.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
          )
        ''');
      },
    );
  }

  /// Registers a new user. Returns `true` if successful, or `false` if the email is already registered.
  Future<bool> registerUser(String email, String password) async {
    final db = await database;
    try {
      await db.insert(
        'users',
        {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return true;
    } catch (e) {
      // Returns false if unique constraint fails (email already exists)
      return false;
    }
  }

  /// Verifies user credentials. Returns `true` if email and password match, `false` otherwise.
  Future<bool> verifyUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
    );
    return maps.isNotEmpty;
  }

  /// Checks if a user already exists with the given email.
  Future<bool> userExists(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    return maps.isNotEmpty;
  }
}
