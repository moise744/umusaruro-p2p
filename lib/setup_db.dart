import 'package:postgres/postgres.dart';

void main() async {
  print('Connecting to database...');
  final connection = await Connection.open(
    Endpoint(
      host: 'db.fcszxlufbuntqppkrgwl.supabase.co',
      port: 5432,
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
      DROP TABLE IF EXISTS messages CASCADE;
      DROP TABLE IF EXISTS investments CASCADE;
      DROP TABLE IF EXISTS projects CASCADE;
      DROP TABLE IF EXISTS users CASCADE;
    ''');

    // Users Table
    await connection.execute('''
      CREATE TABLE users (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        full_name VARCHAR(255) NOT NULL,
        role VARCHAR(50) NOT NULL,
        location VARCHAR(255),
        is_verified BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Users table created.');

    // Projects Table
    await connection.execute('''
      CREATE TABLE projects (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        farmer_id UUID REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        category VARCHAR(100) NOT NULL,
        target_amount DECIMAL(12, 2) NOT NULL,
        current_amount DECIMAL(12, 2) DEFAULT 0,
        status VARCHAR(50) DEFAULT 'funding',
        return_rate DECIMAL(5, 2) NOT NULL,
        duration_months INT NOT NULL,
        risk_level VARCHAR(50) NOT NULL,
        image_url TEXT,
        latitude DECIMAL(10, 8),
        longitude DECIMAL(11, 8),
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Projects table created.');

    // Investments Table
    await connection.execute('''
      CREATE TABLE investments (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
        investor_id UUID REFERENCES users(id) ON DELETE CASCADE,
        amount DECIMAL(12, 2) NOT NULL,
        status VARCHAR(50) DEFAULT 'active',
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Investments table created.');

    // Messages Table
    await connection.execute('''
      CREATE TABLE messages (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        sender_id UUID REFERENCES users(id) ON DELETE CASCADE,
        receiver_id UUID REFERENCES users(id) ON DELETE CASCADE,
        content TEXT NOT NULL,
        is_read BOOLEAN DEFAULT false,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
      );
    ''');
    print('Messages table created.');

    // Insert Dummy Data
    await connection.execute('''
      INSERT INTO users (id, email, password_hash, full_name, role, location, is_verified) VALUES
      ('f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'farmer@example.com', 'password', 'Kagabo Jean', 'farmer', 'Musanze', true),
      ('a2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7a', 'investor@example.com', 'password', 'Uwimana Alice', 'investor', 'Kigali', true);
    ''');
    
    await connection.execute('''
      INSERT INTO projects (id, farmer_id, title, description, category, target_amount, current_amount, status, return_rate, duration_months, risk_level, image_url, latitude, longitude) VALUES
      ('p1c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'Maize Expansion 2024', 'Expanding maize production in Musanze with modern irrigation.', 'Cereals', 500000, 250000, 'funding', 15.0, 6, 'Medium', 'https://images.unsplash.com/photo-1599930113854-d6d7fd521f10', -1.503, 29.635),
      ('p2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7p', 'f2c1b2c4-850d-4b8c-a1b4-1c9c45e82b7f', 'Coffee Plantation Renewal', 'Renewing coffee plants to increase yield.', 'Coffee', 1200000, 1200000, 'active', 20.0, 12, 'Low', 'https://images.unsplash.com/photo-1511556820780-d912e42b4980', -1.954, 30.061);
    ''');
    
    print('Dummy data inserted.');
    print('Migration complete!');

  } catch (e) {
    print('Error during migration: \$e');
  } finally {
    await connection.close();
  }
}
