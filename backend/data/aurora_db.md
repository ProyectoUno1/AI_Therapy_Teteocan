Query for Aurora Database Creation

SET "TimeZone" TO 'America/Mexico_City';
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    auth_id VARCHAR(128) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL CHECK (role IN ('user', 'therapist', 'admin')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE therapist_profiles (
    user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    license_number VARCHAR(50) NOT NULL,
    specialty VARCHAR(100),
    bio TEXT,
    available BOOLEAN DEFAULT TRUE,
    validated BOOLEAN DEFAULT FALSE
);

CREATE TABLE therapy_sessions (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    therapist_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    scheduled_at TIMESTAMP NOT NULL,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'cancelled', 'completed')),
    mode VARCHAR(20) NOT NULL CHECK (mode IN ('chat', 'call', 'video')),
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE payments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_id INTEGER REFERENCES therapy_sessions(id) ON DELETE SET NULL,
    amount_usd NUMERIC(6, 2) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('pending', 'paid', 'failed')),
    method VARCHAR(20) CHECK (method IN ('stripe', 'mercado_pago')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE ai_messages (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    response TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE feedback (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(20) NOT NULL CHECK (source IN ('ai', 'therapist')),
    target_id INTEGER NOT NULL,
    rating INTEGER CHECK (rating BETWEEN 1 AND 5),
    comments TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_user_auth_id ON users(auth_id);
CREATE INDEX idx_sessions_user ON therapy_sessions(user_id);
CREATE INDEX idx_sessions_therapist ON therapy_sessions(therapist_id);
CREATE INDEX idx_feedback_user ON feedback(user_id);
CREATE INDEX idx_ai_messages_user ON ai_messages(user_id);
