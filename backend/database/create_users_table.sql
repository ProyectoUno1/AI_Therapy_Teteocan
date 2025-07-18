-- Verificar la estructura de la base de datos existente
-- Este archivo es para referencia, la base de datos ya fue creada según backend/data/aurora_db.md

-- Verificar que las tablas existan
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
ORDER BY table_name;

-- Verificar estructura de la tabla users
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'users'
ORDER BY ordinal_position;

-- Verificar cantidad de usuarios registrados
SELECT COUNT(*) as total_users FROM users;

-- Verificar usuarios por rol
SELECT role, COUNT(*) as count
FROM users
GROUP BY role;

-- Verificar índices existentes
SELECT indexname, tablename 
FROM pg_indexes 
WHERE tablename IN ('users', 'therapy_sessions', 'ai_messages', 'feedback')
ORDER BY tablename, indexname;
