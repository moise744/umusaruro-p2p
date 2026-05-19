import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to database...');
  final connection = await Connection.open(
    Endpoint(
      host: 'db.fcszxlufbuntqppkrgwl.supabase.co',
      port: 6543,
      database: 'postgres',
      username: 'postgres',
      password: r'Lgxg85mU4v&U5p$',
    ),
    settings: ConnectionSettings(sslMode: SslMode.require),
  );

  print('Connected! Running migrations...');

  try {
    // Drop existing tables for fresh start if any
    await connection.execute('''
      DROP TABLE IF EXISTS notifications CASCADE;
      DROP TABLE IF EXISTS farm_updates CASCADE;
      DROP TABLE IF EXISTS messages CASCADE;
      DROP TABLE IF EXISTS transactions CASCADE;
      DROP TABLE IF EXISTS investments CASCADE;
      DROP TABLE IF EXISTS projects CASCADE;
      DROP TABLE IF EXISTS users CASCADE;
    ''');

    // Users Table
    await connection.execute('''
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        phone VARCHAR(20),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        national_id VARCHAR(255),
        role VARCHAR(50) NOT NULL,
        profile_photo_url TEXT,
        wallet_balance DECIMAL(12, 2) DEFAULT 0,
        reputation_score INT DEFAULT 0,
        kyc_status VARCHAR(50) DEFAULT 'PENDING',
        cell_id VARCHAR(255),
        is_active BOOLEAN DEFAULT true,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
        last_login_at TIMESTAMP WITH TIME ZONE
      );
    ''');
    print('Users table created.');

    // Projects Table
    await connection.execute('''
      CREATE TABLE projects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
        cell_leader_id UUID REFERENCES users(id),
        title VARCHAR(255) NOT NULL,
        crop_type VARCHAR(100) NOT NULL,
        season VARCHAR(10),
        planting_date TIMESTAMP WITH TIME ZONE,
        expected_harvest_date TIMESTAMP WITH TIME ZONE,
        location_district VARCHAR(100),
        location_sector VARCHAR(100),
        location_cell VARCHAR(100),
        gps_lat DECIMAL(10, 8),
        gps_lng DECIMAL(11, 8),
        land_size_hectares DECIMAL(8, 2),
        funding_goal DECIMAL(12, 2) NOT NULL,
        funding_raised DECIMAL(12, 2) DEFAULT 0,
        min_investment DECIMAL(12, 2),
        max_investment DECIMAL(12, 2),
        expected_return_percent DECIMAL(5, 2) NOT NULL,
        photo_urls TEXT,
        document_urls TEXT,
        status VARCHAR(50) DEFAULT 'DRAFT',
        verification_note TEXT,
        verified_at TIMESTAMP WITH TIME ZONE,
        funding_deadline TIMESTAMP WITH TIME ZONE,
        harvest_yield_kg DECIMAL(10, 2),
        harvest_revenue DECIMAL(12, 2),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
        updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Projects table created.');

    // Investments Table
    await connection.execute('''
      CREATE TABLE investments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        investor_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount_invested DECIMAL(12, 2) NOT NULL,
        share_percent DECIMAL(5, 2),
        expected_return DECIMAL(12, 2),
        actual_return DECIMAL(12, 2),
        status VARCHAR(50) DEFAULT 'ACTIVE',
        invested_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
        returned_at TIMESTAMP WITH TIME ZONE
      );
    ''');
    print('Investments table created.');

    // Transactions Table
    await connection.execute('''
      CREATE TABLE transactions (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        type VARCHAR(50) NOT NULL,
        amount DECIMAL(12, 2) NOT NULL,
        fee DECIMAL(12, 2) DEFAULT 0,
        reference_id VARCHAR(255),
        project_id UUID REFERENCES projects(id) ON DELETE SET NULL,
        status VARCHAR(50) DEFAULT 'PENDING',
        payment_method VARCHAR(50),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
        completed_at TIMESTAMP WITH TIME ZONE
      );
    ''');
    print('Transactions table created.');

    // Messages Table
    await connection.execute('''
      CREATE TABLE messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        chat_thread_id VARCHAR(255) NOT NULL,
        sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
        receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
        content_type VARCHAR(50) DEFAULT 'TEXT',
        content TEXT NOT NULL,
        media_url TEXT,
        duration_seconds INT,
        status VARCHAR(50) DEFAULT 'SENT',
        sent_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Messages table created.');

    // FarmUpdates Table
    await connection.execute('''
      CREATE TABLE farm_updates (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
        text TEXT NOT NULL,
        photo_urls TEXT,
        posted_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('FarmUpdates table created.');

    // Notifications Table
    await connection.execute('''
      CREATE TABLE notifications (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        type VARCHAR(50),
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Notifications table created.');

    // Insert Dummy Data
    await connection.execute('''
      INSERT INTO users (id, email, password_hash, full_name, role, location_district, is_active, kyc_status) VALUES
      ('f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'farmer@example.com', 'password', 'Kagabo Jean', 'FARMER', 'Musanze', true, 'VERIFIED'),
      ('a2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7a', 'investor@example.com', 'password', 'Uwimana Alice', 'INVESTOR', 'Kigali', true, 'VERIFIED'),
      ('c2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7c', 'cell_leader@example.com', 'password', 'Habimana Pierre', 'CELL_LEADER', 'Musanze', true, 'VERIFIED');
    ''');
    
    await connection.execute('''
      INSERT INTO projects (id, farmer_id, title, crop_type, season, funding_goal, funding_raised, min_investment, expected_return_percent, status, location_district, gps_lat, gps_lng) VALUES
      ('p1c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'Maize Expansion 2024', 'MAIZE', 'A', 500000, 250000, 10000, 15.0, 'ACTIVE', 'Musanze', -1.503, 29.635),
      ('p2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'Coffee Plantation Renewal', 'COFFEE', 'B', 1200000, 1200000, 50000, 20.0, 'ACTIVE', 'Huye', -1.954, 30.061),
      ('p3c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'Potato Farm New Season', 'POTATOES', 'A', 800000, 0, 5000, 12.0, 'PENDING_VERIFICATION', 'Musanze', -1.501, 29.630);
    ''');
    
    await connection.execute('''
      INSERT INTO investments (id, project_id, investor_id, amount_invested, expected_return, status) VALUES
      ('i1c1b2c4-850d-4b8c-a1b4-1c9c45e82b7i', 'p1c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'a2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7a', 250000, 287500, 'ACTIVE'),
      ('i2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7i', 'p2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'a2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7a', 1200000, 1440000, 'ACTIVE');
    ''');
    
    print('Dummy data inserted.');
    print('Migration complete!');

  } catch (e) {
    print('Error during migration: \$e');
  } finally {
    await connection.close();
  }
}
