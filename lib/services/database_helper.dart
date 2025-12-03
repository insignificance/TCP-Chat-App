import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 数据库帮助类（单例模式）
/// 负责数据库的初始化、创建和版本管理
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tcp_chat.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建会话表
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_type TEXT NOT NULL,
        remote_address TEXT NOT NULL,
        remote_port INTEGER NOT NULL,
        local_port INTEGER NOT NULL,
        start_time INTEGER NOT NULL,
        end_time INTEGER,
        status TEXT NOT NULL,
        message_count INTEGER DEFAULT 0,
        received_bytes INTEGER DEFAULT 0,
        sent_bytes INTEGER DEFAULT 0
      )
    ''');

    // 创建消息表
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        is_sent_by_me INTEGER NOT NULL,
        message_type TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        data_size INTEGER NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');

    // 创建索引以提升查询性能
    await db.execute('CREATE INDEX idx_session_type ON sessions(session_type)');
    await db.execute('CREATE INDEX idx_session_status ON sessions(status)');
    await db.execute('CREATE INDEX idx_message_session ON messages(session_id)');
    await db.execute('CREATE INDEX idx_message_timestamp ON messages(timestamp)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 未来版本升级时在此处理
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空所有数据（仅用于测试）
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('messages');
    await db.delete('sessions');
  }
}
