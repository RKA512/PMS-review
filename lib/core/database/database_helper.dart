/// Why the file exists:
/// Central SQLite database service managing schemas, connections, and migrations.
/// Implements [Database Principles DB-005 (Foreign Keys Enabled)], [Development Rules DR-123 (In-Memory database representation flag)], and exact [Database Schema Design].
library;

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  bool useInMemoryDatabase = false;

  Future<DatabaseExecutor> get executor async {
    final txn = Zone.current[#sqlite_txn];
    if (txn != null && txn is DatabaseExecutor) {
      return txn;
    }
    return await database;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB(useInMemoryDatabase ? ':memory:' : 'property_management_system.db');
    await _ensureSeeds(_database!);
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = useInMemoryDatabase ? filePath : await getDatabasesPath();
    final path = useInMemoryDatabase ? filePath : join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: _onConfigure,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateV1toV2(db);
    }
  }

  Future<void> _migrateV1toV2(Database db) async {
    final tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table' AND name='booking_notes'");
    if (tables.isNotEmpty) {
      final cols = await db.rawQuery("PRAGMA table_info(booking_notes)");
      final hasUpdatedAt = cols.any((c) => c['name'] == 'updated_at');
      if (!hasUpdatedAt) {
        await db.execute("ALTER TABLE booking_notes ADD COLUMN updated_at TEXT NOT NULL DEFAULT (datetime('now'))");
      }
    }
  }

  Future<void> _createDB(Database db, int version) async {
    // 1. Accounts Table
    await db.execute('''
      CREATE TABLE accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 2. Roles Table
    await db.execute('''
      CREATE TABLE roles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 3. Permissions Table
    await db.execute('''
      CREATE TABLE permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 4. Role Permissions Table
    await db.execute('''
      CREATE TABLE role_permissions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id INTEGER NOT NULL,
        permission_id INTEGER NOT NULL,
        UNIQUE(role_id, permission_id),
        FOREIGN KEY (role_id) REFERENCES roles (id) ON DELETE CASCADE,
        FOREIGN KEY (permission_id) REFERENCES permissions (id) ON DELETE CASCADE
      )
    ''');

    // 5. Users Table (Password is hashed)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        account_id INTEGER NOT NULL,
        role_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (role_id) REFERENCES roles (id)
      )
    ''');

    // 6. Property Types Table
    await db.execute('''
      CREATE TABLE property_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    // 7. Properties Table
    await db.execute('''
      CREATE TABLE properties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        account_id INTEGER NOT NULL,
        property_type_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        address TEXT,
        city TEXT,
        country TEXT,
        phone TEXT,
        email TEXT,
        currency_code TEXT NOT NULL,
        use_business_days INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (property_type_id) REFERENCES property_types (id)
      )
    ''');

    // 8. Property Settings Table
    await db.execute('''
      CREATE TABLE property_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        property_id INTEGER NOT NULL,
        setting_key TEXT NOT NULL,
        setting_value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    // 9. User Property Access Table
    await db.execute('''
      CREATE TABLE user_property_access (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        property_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(user_id, property_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    // 10. Unit Types Table
    await db.execute('''
      CREATE TABLE unit_types (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    // 11. Units Table
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        unit_type_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        unit_number TEXT NOT NULL,
        floor_number INTEGER,
        capacity INTEGER NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_type_id) REFERENCES unit_types (id)
      )
    ''');

    // Index creation for performance on frequent query paths (Table Units)
    await db.execute('CREATE INDEX idx_units_property ON units (property_id);');
    await db.execute('CREATE INDEX idx_units_number ON units (unit_number);');
    await db.execute('CREATE INDEX idx_units_status ON units (status);');

    // 12. Guests Table (Shared Directory)
    await db.execute('''
      CREATE TABLE guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        account_id INTEGER NOT NULL,
        full_name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        nationality TEXT,
        document_type TEXT,
        document_number TEXT,
        date_of_birth TEXT,
        address TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('CREATE INDEX idx_guests_account ON guests (account_id);');
    await db.execute('CREATE INDEX idx_guests_phone ON guests (phone);');
    await db.execute('CREATE INDEX idx_guests_document ON guests (document_number);');

    // 13. Guest Contacts Table
    await db.execute('''
      CREATE TABLE guest_contacts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        guest_id INTEGER NOT NULL,
        contact_type TEXT NOT NULL,
        contact_value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (guest_id) REFERENCES guests (id) ON DELETE CASCADE
      )
    ''');

    // 14. Guest Credit Accounts Table
    await db.execute('''
      CREATE TABLE guest_credit_accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        guest_id INTEGER NOT NULL UNIQUE,
        cached_balance INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (guest_id) REFERENCES guests (id) ON DELETE CASCADE
      )
    ''');

    // 15. Guest Credit Transactions Table
    await db.execute('''
      CREATE TABLE guest_credit_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        guest_credit_account_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        transaction_type TEXT NOT NULL, -- credit_created, credit_used, credit_adjustment
        reference_type TEXT,
        reference_id INTEGER,
        notes TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (guest_credit_account_id) REFERENCES guest_credit_accounts (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 16. Bookings Table
    await db.execute('''
      CREATE TABLE bookings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        primary_guest_id INTEGER NOT NULL,
        booking_number TEXT NOT NULL UNIQUE,
        status TEXT NOT NULL,
        check_in_date TEXT NOT NULL,
        check_out_date TEXT NOT NULL,
        actual_check_in TEXT,
        actual_check_out TEXT,
        source TEXT,
        notes TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (primary_guest_id) REFERENCES guests (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 17. Booking Guests Table
    await db.execute('''
      CREATE TABLE booking_guests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        guest_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
        FOREIGN KEY (guest_id) REFERENCES guests (id) ON DELETE CASCADE
      )
    ''');

    // 18. Booking Units Table
    await db.execute('''
      CREATE TABLE booking_units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        booking_id INTEGER NOT NULL,
        unit_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        nightly_rate INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
        FOREIGN KEY (unit_id) REFERENCES units (id)
      )
    ''');

    // 19. Booking Unit Transfers Table
    await db.execute('''
      CREATE TABLE booking_unit_transfers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        booking_id INTEGER NOT NULL,
        from_booking_unit_id INTEGER NOT NULL,
        to_booking_unit_id INTEGER NOT NULL,
        transfer_date TEXT NOT NULL,
        reason TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
        FOREIGN KEY (from_booking_unit_id) REFERENCES booking_units (id),
        FOREIGN KEY (to_booking_unit_id) REFERENCES booking_units (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 20. Booking Notes Table
    await db.execute('''
      CREATE TABLE booking_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        booking_id INTEGER NOT NULL,
        note TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL DEFAULT (datetime('now')),
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 21. Invoices Table
    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        booking_id INTEGER NOT NULL,
        invoice_number TEXT NOT NULL UNIQUE,
        total_amount INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL,
        issued_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (booking_id) REFERENCES bookings (id) ON DELETE CASCADE
      )
    ''');

    // 22. Invoice Lines Table
    await db.execute('''
      CREATE TABLE invoice_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        description TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price INTEGER NOT NULL,
        line_total INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 23. Invoice Adjustments Table
    await db.execute('''
      CREATE TABLE invoice_adjustments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        adjustment_type TEXT NOT NULL, -- discount, manual_adjustment, correction
        amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
      )
    ''');

    // 24. Payments Table
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        booking_id INTEGER NOT NULL,
        invoice_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        payment_type TEXT NOT NULL, -- incoming, refund, adjustment
        reference_number TEXT,
        notes TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (booking_id) REFERENCES bookings (id),
        FOREIGN KEY (invoice_id) REFERENCES invoices (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 25. Settlements Table
    await db.execute('''
      CREATE TABLE settlements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        booking_id INTEGER NOT NULL,
        settlement_type TEXT NOT NULL, -- overpayment, underpayment
        status TEXT NOT NULL,
        difference_amount INTEGER NOT NULL,
        reason TEXT,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (booking_id) REFERENCES bookings (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 26. Settlement Corrections Table
    await db.execute('''
      CREATE TABLE settlement_corrections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        settlement_id INTEGER NOT NULL,
        correction_amount INTEGER NOT NULL,
        reason TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (settlement_id) REFERENCES settlements (id) ON DELETE CASCADE,
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 27. Expense Categories Table
    await db.execute('''
      CREATE TABLE expense_categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 28. Expenses Table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        expense_category_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        description TEXT,
        expense_date TEXT NOT NULL,
        created_by INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        deleted_at TEXT,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (expense_category_id) REFERENCES expense_categories (id),
        FOREIGN KEY (created_by) REFERENCES users (id)
      )
    ''');

    // 29. Business Days Table
    await db.execute('''
      CREATE TABLE business_days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        business_date TEXT NOT NULL,
        status TEXT NOT NULL, -- open, closed
        opened_by INTEGER NOT NULL,
        closed_by INTEGER,
        opened_at TEXT NOT NULL,
        closed_at TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE,
        FOREIGN KEY (opened_by) REFERENCES users (id),
        FOREIGN KEY (closed_by) REFERENCES users (id)
      )
    ''');

    // 30. Business Day Transactions Table
    await db.execute('''
      CREATE TABLE business_day_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        business_day_id INTEGER NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (business_day_id) REFERENCES business_days (id) ON DELETE CASCADE
      )
    ''');

    // 31. Notifications Table (In-app notifications)
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    // 32. Audit Logs Table (Strictly Immutable, as per AP-003 / AP-004)
    await db.execute('''
      CREATE TABLE audit_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        property_id INTEGER,
        user_id INTEGER NOT NULL,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        description TEXT NOT NULL,
        old_values TEXT,
        new_values TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (property_id) REFERENCES properties (id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // 33. Currencies Table (Post-MVP structures)
    await db.execute('''
      CREATE TABLE currencies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        symbol TEXT NOT NULL,
        is_default INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // 34. Currency Rates Table
    await db.execute('''
      CREATE TABLE currency_rates (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        from_currency TEXT NOT NULL,
        to_currency TEXT NOT NULL,
        rate REAL NOT NULL,
        effective_date TEXT NOT NULL
      )
    ''');

    // 35. App Settings Table
    await db.execute('''
      CREATE TABLE app_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        setting_key TEXT NOT NULL UNIQUE,
        setting_value TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 36. Sync Queue Table (Post-MVP preparation)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        uuid TEXT NOT NULL UNIQUE,
        entity_type TEXT NOT NULL,
        entity_id INTEGER NOT NULL,
        operation_type TEXT NOT NULL,
        payload TEXT,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        processed_at TEXT
      )
    ''');

    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now().toIso8601String();

    // Seed default Accounts to satisfy property account_id foreign key constraint
    await db.rawInsert('''
      INSERT INTO accounts (id, uuid, name, email, phone, status, created_at, updated_at)
      VALUES 
        (1, 'acc-system', 'System Default Account', 'system@example.com', '0000000000', 'Active', '$now', '$now')
    ''');

    // Seed default Roles
    await db.rawInsert('''
      INSERT INTO roles (uuid, name, description, created_at, updated_at)
      VALUES 
        ('r1-owner', 'Owner', 'Complete system control and ownership', '$now', '$now'),
        ('r2-manager', 'Manager', 'Property operations and configuration management', '$now', '$now'),
        ('r3-receptionist', 'Receptionist', 'Checks, reservations, guest registry and billing operations', '$now', '$now'),
        ('r4-accountant', 'Accountant', 'Financial reporting, ledger verification, payments and expenses', '$now', '$now'),
        ('r5-housekeeping', 'Housekeeping', 'Unit service, maintenance and room cleanliness status updates', '$now', '$now')
    ''');

    // Seed default Users to satisfy audit log user_id foreign key constraint
    await db.rawInsert('''
      INSERT INTO users (id, uuid, account_id, role_id, name, email, password_hash, status, created_at, updated_at)
      VALUES 
        (1, 'usr-system', 1, 1, 'System Administrator', 'admin@example.com', 'system-default-hash', 'Active', '$now', '$now')
    ''');

    // Seed default Property Types
    await db.rawInsert('''
      INSERT INTO property_types (name, description)
      VALUES 
        ('Hotel', 'Standard hotel properties with multi-room setups'),
        ('Apartments', 'Furnished rooms and luxury suites'),
        ('Resort', 'Leisure resort and facilities setups'),
        ('Guest House', 'Boutique hospitality and home stay buildings')
    ''');

    // Seed default Unit Types
    await db.rawInsert('''
      INSERT INTO unit_types (name, description)
      VALUES 
        ('Single Room', 'Standard single bed room'),
        ('Double Room', 'Two beds standard room'),
        ('Suite', 'Luxury living suite room with premium amenities'),
        ('Studio', 'Modern self-contained studio room')
    ''');

    // Seed default Expense Categories
    await db.rawInsert('''
      INSERT INTO expense_categories (uuid, name, description, created_at, updated_at)
      VALUES 
        ('ec-maint', 'Maintenance & Repair', 'Building and fixture maintenance expenses', '$now', '$now'),
        ('ec-clean', 'Cleaning Products', 'Housekeeping supplies, laundry and cleaning products', '$now', '$now'),
        ('ec-utils', 'Utilities', 'Water, electricity, gas and internet utilities bills', '$now', '$now'),
        ('ec-supp', 'Operational Supplies', 'Office and lobby operational products', '$now', '$now'),
        ('ec-sal', 'Salaries & Wages', 'Staff core compensation and benefits', '$now', '$now'),
        ('ec-other', 'Other Expenses', 'Miscellaneous operational expenses', '$now', '$now')
    ''');

    // Seed base Currencies
    await db.rawInsert('''
      INSERT INTO currencies (code, name, symbol, is_default)
      VALUES 
        ('SAR', 'Saudi Riyal', 'ر.س', 1),
        ('USD', 'United States Dollar', '\$', 0),
        ('EUR', 'Euro', '€', 0)
    ''');
  }

  Future<void> _ensureSeeds(Database db) async {
    final accounts = await db.rawQuery('SELECT COUNT(*) as count FROM accounts');
    final accountCount = Sqflite.firstIntValue(accounts) ?? 0;
    if (accountCount == 0) {
      final now = DateTime.now().toIso8601String();
      await db.rawInsert('''
        INSERT INTO accounts (id, uuid, name, email, phone, status, created_at, updated_at)
        VALUES (1, 'acc-system', 'System Default Account', 'system@example.com', '0000000000', 'Active', '$now', '$now')
      ''');
    }

    final roles = await db.rawQuery('SELECT COUNT(*) as count FROM roles');
    final roleCount = Sqflite.firstIntValue(roles) ?? 0;
    if (roleCount == 0) {
      final now = DateTime.now().toIso8601String();
      await db.rawInsert('''
        INSERT INTO roles (uuid, name, description, created_at, updated_at)
        VALUES 
          ('r1-owner', 'Owner', 'Complete system control and ownership', '$now', '$now'),
          ('r2-manager', 'Manager', 'Property operations and configuration management', '$now', '$now'),
          ('r3-receptionist', 'Receptionist', 'Checks, reservations, guest registry and billing operations', '$now', '$now'),
          ('r4-accountant', 'Accountant', 'Financial reporting, ledger verification, payments and expenses', '$now', '$now'),
          ('r5-housekeeping', 'Housekeeping', 'Unit service, maintenance and room cleanliness status updates', '$now', '$now')
      ''');
    }

    final users = await db.rawQuery('SELECT COUNT(*) as count FROM users');
    final userCount = Sqflite.firstIntValue(users) ?? 0;
    if (userCount == 0) {
      final now = DateTime.now().toIso8601String();
      await db.rawInsert('''
        INSERT INTO users (id, uuid, account_id, role_id, name, email, password_hash, status, created_at, updated_at)
        VALUES (1, 'usr-system', 1, 1, 'System Administrator', 'admin@example.com', 'system-default-hash', 'Active', '$now', '$now')
      ''');
    }

    final pTypes = await db.rawQuery('SELECT COUNT(*) as count FROM property_types');
    final pTypeCount = Sqflite.firstIntValue(pTypes) ?? 0;
    if (pTypeCount == 0) {
      await db.rawInsert('''
        INSERT INTO property_types (name, description)
        VALUES 
          ('Hotel', 'Standard hotel properties with multi-room setups'),
          ('Apartments', 'Furnished rooms and luxury suites'),
          ('Resort', 'Leisure resort and facilities setups'),
          ('Guest House', 'Boutique hospitality and home stay buildings')
      ''');
    }
  }

  Future<int> getActiveUnitsCount(int propertyId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM units WHERE property_id = ? AND status = \'Active\'',
      [propertyId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getActiveBookingsCount(int propertyId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM bookings WHERE property_id = ? AND status NOT IN ('checkedOut', 'cancelled')",
      [propertyId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getAuditLogsCount(int propertyId) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM audit_logs WHERE property_id = ?',
      [propertyId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // --- Reports Aggregates ---
  Future<Map<String, dynamic>> getFinancialSummary(int propertyId,
      {DateTime? from, DateTime? to}) async {
    final db = await instance.database;
    final dateFilter = from != null && to != null
        ? "AND created_at BETWEEN '${from.toIso8601String()}' AND '${to.toIso8601String()}'"
        : '';
    final revenue = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) FROM payments WHERE property_id = ? AND payment_type = 'incoming' $dateFilter",
      [propertyId]));
    final expenses = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) FROM expenses WHERE property_id = ? AND deleted_at IS NULL $dateFilter",
      [propertyId]));
    final refunds = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COALESCE(SUM(amount),0) FROM payments WHERE property_id = ? AND payment_type = 'refund' $dateFilter",
      [propertyId]));
    final bookingCount = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM bookings WHERE property_id = ? $dateFilter", [propertyId]));
    final occupancy = Sqflite.firstIntValue(await db.rawQuery(
      "SELECT COUNT(*) FROM booking_units bu JOIN bookings b ON bu.booking_id = b.id WHERE b.property_id = ? AND b.status NOT IN ('cancelled','checkedOut') $dateFilter",
      [propertyId]));
    return {
      'revenue': revenue ?? 0,
      'expenses': expenses ?? 0,
      'refunds': refunds ?? 0,
      'bookingCount': bookingCount ?? 0,
      'occupiedUnits': occupancy ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getMonthlyRevenue(int propertyId, {int months = 12}) async {
    final db = await instance.database;
    return await db.rawQuery(
      "SELECT strftime('%Y-%m', created_at) as month, SUM(amount) as total FROM payments "
      "WHERE property_id = ? AND payment_type = 'incoming' AND created_at >= date('now', '-$months months') "
      "GROUP BY month ORDER BY month ASC",
      [propertyId]);
  }

  // --- App Settings ---
  Future<String?> getAppSetting(String key) async {
    final db = await instance.database;
    final result = await db.query('app_settings', where: 'setting_key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['setting_value'] as String?;
  }

  Future<void> setAppSetting(String key, String value) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    final existing = await db.query('app_settings', where: 'setting_key = ?', whereArgs: [key]);
    if (existing.isEmpty) {
      await db.insert('app_settings', {
        'setting_key': key,
        'setting_value': value,
        'created_at': now,
        'updated_at': now,
      });
    } else {
      await db.update('app_settings', {'setting_value': value, 'updated_at': now},
          where: 'setting_key = ?', whereArgs: [key]);
    }
  }

  // --- User Management ---
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await instance.database;
    return await db.rawQuery(
      'SELECT u.*, r.name as role_name FROM users u LEFT JOIN roles r ON u.role_id = r.id WHERE u.deleted_at IS NULL ORDER BY u.id');
  }

  Future<int> createUser(Map<String, dynamic> userMap) async {
    final db = await instance.database;
    return await db.insert('users', userMap);
  }

  Future<void> updateUser(int id, Map<String, dynamic> userMap) async {
    final db = await instance.database;
    await db.update('users', userMap, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUser(int id) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update('users', {'deleted_at': now}, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getUserById(int id) async {
    final db = await instance.database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return result.isNotEmpty ? result.first : null;
  }

  Future<bool> verifyPassword(int userId, String password) async {
    final db = await instance.database;
    final result = await db.query('users',
        columns: ['password_hash'], where: 'id = ?', whereArgs: [userId]);
    if (result.isEmpty) return false;
    return result.first['password_hash'] == password;
  }

  Future<void> updatePassword(int userId, String newHash) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();
    await db.update('users', {'password_hash': newHash, 'updated_at': now},
        where: 'id = ?', whereArgs: [userId]);
  }

  // --- Factory Reset ---
  Future<void> factoryReset() async {
    final db = await instance.database;
    await db.execute('PRAGMA foreign_keys = OFF');
    final tables = [
      'sync_queue', 'app_settings', 'currency_rates', 'currencies',
      'audit_logs', 'notifications', 'business_day_transactions', 'business_days',
      'expenses', 'expense_categories', 'settlement_corrections', 'settlements',
      'payments', 'invoice_adjustments', 'invoice_lines', 'invoices',
      'booking_notes', 'booking_unit_transfers', 'booking_units', 'booking_guests',
      'bookings', 'guest_credit_transactions', 'guest_credit_accounts',
      'guest_contacts', 'guests', 'user_property_access', 'property_settings',
      'units', 'unit_types', 'users', 'role_permissions', 'permissions',
      'roles', 'properties', 'property_types', 'accounts',
    ];
    for (final table in tables) {
      await db.delete(table);
    }
    await db.execute('PRAGMA foreign_keys = ON');
    await _seedInitialData(db);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
