-- Create Database
CREATE DATABASE IF NOT EXISTS LFG;
USE LFG;

-- Users Table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Games Table
CREATE TABLE IF NOT EXISTS games (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  platform VARCHAR(50),
  genre VARCHAR(50),
  release_year INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Games Table (Many-to-Many)
CREATE TABLE IF NOT EXISTS user_games (
  user_id INT NOT NULL,
  game_id INT NOT NULL,
  completion_status VARCHAR(20),
  PRIMARY KEY(user_id, game_id),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
);

-- Friends Table
CREATE TABLE IF NOT EXISTS friends (
  user1_id INT NOT NULL,
  user2_id INT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(user1_id, user2_id),
  FOREIGN KEY(user1_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(user2_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Sessions Table
CREATE TABLE IF NOT EXISTS sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  creator_id INT NOT NULL,
  game_id INT NOT NULL,
  session_datetime DATETIME NOT NULL,
  location VARCHAR(255),
  max_players INT DEFAULT 4,
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(creator_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
);

-- Session Attendees Table
CREATE TABLE IF NOT EXISTS session_attendees (
  session_id INT NOT NULL,
  user_id INT NOT NULL,
  rsvp_status VARCHAR(20) DEFAULT 'pending',
  attended BOOLEAN DEFAULT FALSE,
  PRIMARY KEY(session_id, user_id),
  FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);
