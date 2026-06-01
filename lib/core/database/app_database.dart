





import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  
  static final AppDatabase _instance = AppDatabase._internal();
  static Database? _db; 

  factory AppDatabase() => _instance;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_db != null) return _db!; 
    _db = await _initDatabase();
    print('Database opened!');
    return _db!;
  }

  Future<Database> _initDatabase() async {
    
    final path = join(await getDatabasesPath(), 'database.db');
    return openDatabase(
      path,
      version: 4, 
      onCreate: (db, version) async {
        
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        
        await db.execute('DROP TABLE IF EXISTS users');
      },
    );
  }
}
