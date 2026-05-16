import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/order_model.dart';
import '../models/client_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('qubico.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE vehicles (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              patente TEXT NOT NULL,
              max_weight REAL NOT NULL,
              driver_name TEXT NOT NULL
            )
          ''');
        } else if (oldVersion == 2) {
          await db.execute('ALTER TABLE vehicles ADD COLUMN patente TEXT NOT NULL DEFAULT ""');
        }
      },
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE vehicles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        patente TEXT NOT NULL,
        max_weight REAL NOT NULL,
        driver_name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        full_name TEXT NOT NULL,
        email TEXT NOT NULL,
        role TEXT NOT NULL,
        is_active INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        rut TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        email TEXT NOT NULL,
        billing_address TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_id TEXT NOT NULL,
        weight REAL NOT NULL,
        height REAL NOT NULL,
        length REAL NOT NULL,
        width REAL NOT NULL,
        load_type TEXT NOT NULL,
        time_window TEXT NOT NULL,
        address TEXT NOT NULL,
        status TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        driver_id TEXT,
        evidence_path TEXT,
        signature_path TEXT,
        incident_reason TEXT,
        delivery_time TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (rut),
        FOREIGN KEY (driver_id) REFERENCES users (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        action TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        old_value TEXT,
        new_value TEXT
      )
    ''');
  }

  // Generic methods for CRUD
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await instance.database;
    return await db.insert(table, data, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> update(String table, Map<String, dynamic> data, String idColumn, dynamic idValue) async {
    final db = await instance.database;
    return await db.update(
      table,
      data,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
  }

  Future<int> delete(String table, String idColumn, dynamic idValue) async {
    final db = await instance.database;
    return await db.delete(
      table,
      where: '$idColumn = ?',
      whereArgs: [idValue],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
