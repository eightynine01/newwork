import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import '../models/local_session.dart';
import '../models/local_template.dart';
import '../models/local_skill.dart';
import '../models/local_workspace.dart';

/// SQLite database provider for local data persistence
///
/// Manages CRUD operations for sessions, templates, skills, and workspaces
/// stored locally on the device using SQLite.
class LocalDbProvider {
  static final LocalDbProvider _instance = LocalDbProvider._internal();
  factory LocalDbProvider() => _instance;
  LocalDbProvider._internal();

  Database? _database;
  static const String _databaseName = 'openwork.db';
  static const int _databaseVersion = 1;

  bool get _initialized => _database != null;

  /// Initialize the database and create tables
  Future<Database> get database async {
    if (_initialized) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables on first run
  Future<void> _onCreate(Database db, int version) async {
    // Sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        messages TEXT NOT NULL,
        todos TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        workspace_id TEXT
      )
    ''');

    // Templates table
    await db.execute('''
      CREATE TABLE templates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        prompt TEXT NOT NULL,
        scope TEXT NOT NULL,
        skills TEXT,
        created_at INTEGER NOT NULL,
        workspace_id TEXT
      )
    ''');

    // Skills table
    await db.execute('''
      CREATE TABLE skills (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        config TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');

    // Workspaces table
    await db.execute('''
      CREATE TABLE workspaces (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        path TEXT NOT NULL UNIQUE,
        description TEXT,
        created_at INTEGER NOT NULL,
        is_active INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better query performance
    await db.execute(
        'CREATE INDEX idx_sessions_workspace ON sessions(workspace_id)');
    await db.execute(
        'CREATE INDEX idx_templates_workspace ON templates(workspace_id)');
    await db
        .execute('CREATE INDEX idx_workspaces_active ON workspaces(is_active)');
  }

  /// Handle database upgrades for future migrations
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Add migration logic here when version changes
    // Example:
    // if (oldVersion < 2) {
    //   await db.execute('ALTER TABLE sessions ADD COLUMN new_column TEXT');
    // }
  }

  // ==================== SESSION OPERATIONS ====================

  /// Insert a new session
  Future<void> insertSession(LocalSession session) async {
    final db = await database;
    await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a session by ID
  Future<LocalSession?> getSession(String id) async {
    final db = await database;
    final maps = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalSession.fromMap(maps.first);
  }

  /// Get all sessions, optionally filtered by workspace
  Future<List<LocalSession>> getSessions({String? workspaceId}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      where: workspaceId != null ? 'workspace_id = ?' : null,
      whereArgs: workspaceId != null ? [workspaceId] : null,
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => LocalSession.fromMap(map)).toList();
  }

  /// Update a session
  Future<void> updateSession(LocalSession session) async {
    final db = await database;
    await db.update(
      'sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  /// Delete a session
  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== TEMPLATE OPERATIONS ====================

  /// Insert a new template
  Future<void> insertTemplate(LocalTemplate template) async {
    final db = await database;
    await db.insert(
      'templates',
      template.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a template by ID
  Future<LocalTemplate?> getTemplate(String id) async {
    final db = await database;
    final maps = await db.query(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalTemplate.fromMap(maps.first);
  }

  /// Get all templates, optionally filtered by workspace or scope
  Future<List<LocalTemplate>> getTemplates({
    String? workspaceId,
    String? scope,
  }) async {
    final db = await database;

    String? where;
    List<dynamic>? whereArgs;

    if (workspaceId != null && scope != null) {
      where = 'workspace_id = ? AND scope = ?';
      whereArgs = [workspaceId, scope];
    } else if (workspaceId != null) {
      where = 'workspace_id = ?';
      whereArgs = [workspaceId];
    } else if (scope != null) {
      where = 'scope = ?';
      whereArgs = [scope];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      'templates',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LocalTemplate.fromMap(map)).toList();
  }

  /// Update a template
  Future<void> updateTemplate(LocalTemplate template) async {
    final db = await database;
    await db.update(
      'templates',
      template.toMap(),
      where: 'id = ?',
      whereArgs: [template.id],
    );
  }

  /// Delete a template
  Future<void> deleteTemplate(String id) async {
    final db = await database;
    await db.delete(
      'templates',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== SKILL OPERATIONS ====================

  /// Insert a new skill
  Future<void> insertSkill(LocalSkill skill) async {
    final db = await database;
    await db.insert(
      'skills',
      skill.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a skill by ID
  Future<LocalSkill?> getSkill(String id) async {
    final db = await database;
    final maps = await db.query(
      'skills',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalSkill.fromMap(maps.first);
  }

  /// Get all skills
  Future<List<LocalSkill>> getSkills() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'skills',
      orderBy: 'name ASC',
    );
    return maps.map((map) => LocalSkill.fromMap(map)).toList();
  }

  /// Update a skill
  Future<void> updateSkill(LocalSkill skill) async {
    final db = await database;
    await db.update(
      'skills',
      skill.toMap(),
      where: 'id = ?',
      whereArgs: [skill.id],
    );
  }

  /// Delete a skill
  Future<void> deleteSkill(String id) async {
    final db = await database;
    await db.delete(
      'skills',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== WORKSPACE OPERATIONS ====================

  /// Insert a new workspace
  Future<void> insertWorkspace(LocalWorkspace workspace) async {
    final db = await database;
    await db.insert(
      'workspaces',
      workspace.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get a workspace by ID
  Future<LocalWorkspace?> getWorkspace(String id) async {
    final db = await database;
    final maps = await db.query(
      'workspaces',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return LocalWorkspace.fromMap(maps.first);
  }

  /// Get all workspaces
  Future<List<LocalWorkspace>> getWorkspaces() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'workspaces',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => LocalWorkspace.fromMap(map)).toList();
  }

  /// Get active workspace
  Future<LocalWorkspace?> getActiveWorkspace() async {
    final db = await database;
    final maps = await db.query(
      'workspaces',
      where: 'is_active = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return LocalWorkspace.fromMap(maps.first);
  }

  /// Update a workspace
  Future<void> updateWorkspace(LocalWorkspace workspace) async {
    final db = await database;
    await db.update(
      'workspaces',
      workspace.toMap(),
      where: 'id = ?',
      whereArgs: [workspace.id],
    );
  }

  /// Set workspace as active (deactivates all others)
  Future<void> setActiveWorkspace(String id) async {
    final db = await database;

    // Deactivate all workspaces
    await db.update(
      'workspaces',
      {'is_active': 0},
    );

    // Activate the specified workspace
    await db.update(
      'workspaces',
      {'is_active': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete a workspace
  Future<void> deleteWorkspace(String id) async {
    final db = await database;
    await db.delete(
      'workspaces',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Delete all data from all tables
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('sessions');
    await db.delete('templates');
    await db.delete('skills');
    await db.delete('workspaces');
  }

  /// Close database connection
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete database file (for testing/reset purposes)
  Future<void> deleteDatabaseFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
    _database = null;
  }
}
