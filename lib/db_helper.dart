import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class SQLHelper {
  static Future<sql.Database> database() async {
    final dbPath = await sql.getDatabasesPath();
    return sql.openDatabase(
      path.join(dbPath, 'database_name.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE data(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            desc TEXT,
            image TEXT,
            createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
      version: 1,
    );
  }
  static Future<int> createData(String title, String? desc,String image) async {
    final db = await SQLHelper.database();
    final data = {'title': title, 'desc': desc,'image' :image};
    final id = await db.insert('data', data);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllData() async {
    final db = await SQLHelper.database();
    return db.query('data', orderBy: 'createdAt DESC');
  }

  static Future<int> updateData(int id, String title, String? desc, String image) async {
    final db = await SQLHelper.database();
    final data = {'title': title, 'desc': desc,'image':image};
    final result = await db.update('data', data, where: 'id = ?', whereArgs: [id]);
    return result;
  }

  static Future<void> deleteData(int id) async {
    final db = await SQLHelper.database();
    await db.delete('data', where: 'id = ?', whereArgs: [id]);
  }
}
