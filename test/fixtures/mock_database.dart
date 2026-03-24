import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:to_do/Utils/keys.dart';

/// TestDatabaseHelper provides in-memory SQLite database for testing
/// This ensures tests don't affect the real app database
class TestDatabaseHelper {
  static Database? _testDatabase;
  static bool _databaseFactoryInitialized = false;

  /// Initialize in-memory database for tests
  /// Returns the same instance if already initialized
  static Future<Database> getTestDatabase() async {
    if (_testDatabase != null) {
      return _testDatabase!;
    }

    // Initialize FFI factory once
    if (!_databaseFactoryInitialized) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      _databaseFactoryInitialized = true;
    }

    // Open in-memory database
    _testDatabase = await databaseFactory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );

    return _testDatabase!;
  }

  /// Create initial database schema
  static Future<void> _onCreate(Database db, int version) async {
    // Create todo_lists table
    await db.execute('''
      CREATE TABLE todo_lists(
        id TEXT PRIMARY KEY,
        userID TEXT,
        title TEXT,
        creationDate TEXT,
        deadline TEXT,
        hasDeadline INTEGER,
        totalItems INTEGER,
        accomplishedItems INTEGER
      )
    ''');

    // Create todo_items table
    await db.execute('''
      CREATE TABLE todo_items(
        id TEXT PRIMARY KEY, 
        listId TEXT, 
        title TEXT, 
        content TEXT, 
        done INTEGER, 
        itemIndex INTEGER
      )
    ''');

    // Create notifications table
    await db.execute('''
      CREATE TABLE notifications(
        id TEXT PRIMARY KEY,
        listId TEXT,
        notificationIndex INTEGER,
        notificationDateTime TEXT,
        disabled INTEGER
      )
    ''');
  }

  /// Handle database upgrades
  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migration from version 1 to 2 (if needed)
      // Currently no changes required for test schema
    }
  }

  /// Clear all tables to start with clean state for each test
  static Future<void> clearAllTables() async {
    final db = await getTestDatabase();
    await db.delete('todo_lists');
    await db.delete('todo_items');
    await db.delete('notifications');
  }

  /// Delete a specific table
  static Future<void> clearTable(String tableName) async {
    final db = await getTestDatabase();
    await db.delete(tableName);
  }

  /// Close the test database connection
  static Future<void> closeTestDatabase() async {
    if (_testDatabase != null) {
      await _testDatabase!.close();
      _testDatabase = null;
    }
  }

  /// Get database instance (for testing purposes)
  static Future<Database> get database async {
    return getTestDatabase();
  }

  /// Insert a row into a table (for test setup)
  static Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await getTestDatabase();
    return db.insert(table, values);
  }

  /// Query a table
  static Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await getTestDatabase();
    return db.query(table, where: where, whereArgs: whereArgs);
  }

  /// Get row count for a table
  static Future<int> getCount(String table) async {
    final db = await getTestDatabase();
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
    return (result.first['count'] as int?) ?? 0;
  }

  /// Reset database to initial state
  static Future<void> resetDatabase() async {
    await closeTestDatabase();
    _databaseFactoryInitialized = false;
    await getTestDatabase();
  }
}
