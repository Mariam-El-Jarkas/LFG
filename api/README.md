# LFG Connect - PHP Backend API

## Setup

1. Update `config/database.php` with your MySQL credentials
2. Create the database manually in MySQL (or copy the SQL schema below)

## MySQL Schema

Create database and tables:

```sql
CREATE DATABASE lfg_connect;

USE lfg_connect;

CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(50) UNIQUE NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE games (
  id INT AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(100) NOT NULL,
  platform VARCHAR(50),
  genre VARCHAR(50),
  release_year INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE user_games (
  user_id INT NOT NULL,
  game_id INT NOT NULL,
  completion_status VARCHAR(20),
  PRIMARY KEY(user_id, game_id),
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
);

CREATE TABLE friends (
  user1_id INT NOT NULL,
  user2_id INT NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(user1_id, user2_id),
  FOREIGN KEY(user1_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(user2_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE TABLE sessions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  creator_id INT NOT NULL,
  game_id INT NOT NULL,
  session_datetime TIMESTAMP NOT NULL,
  location VARCHAR(255),
  max_players INT DEFAULT 4,
  note TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(creator_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE
);

CREATE TABLE session_attendees (
  session_id INT NOT NULL,
  user_id INT NOT NULL,
  rsvp_status VARCHAR(20) DEFAULT 'pending',
  attended BOOLEAN DEFAULT FALSE,
  PRIMARY KEY(session_id, user_id),
  FOREIGN KEY(session_id) REFERENCES sessions(id) ON DELETE CASCADE,
  FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

## Running the API

With PHP built-in server:

```bash
php -S localhost:8000
```

The API will be available at `http://localhost:8000/api/`

Or use your Apache/Nginx setup to serve the `api/` directory.

## API Endpoints

All endpoints return JSON.

### Authentication
- `POST /api/auth/register` - Register user
- `POST /api/auth/login` - Login user (returns JWT token)
- `GET /api/auth/user/{id}` - Get user info

### Games
- `POST /api/games/add` - Add game to collection (requires auth)
- `GET /api/games/user/{userId}` - Get user's games
- `DELETE /api/games/{gameId}` - Delete game (requires auth)

### Friends
- `POST /api/friends/add` - Add friend (requires auth)
- `GET /api/friends/{userId}` - Get friends list
- `GET /api/friends/{userId}/games/{friendId}` - Get friend's games

### Sessions
- `POST /api/sessions/create` - Create session (requires auth)
- `GET /api/sessions/user/{userId}` - Get user's sessions
- `GET /api/sessions/{sessionId}` - Get session details
- `POST /api/sessions/{sessionId}/rsvp` - RSVP to session (requires auth)
- `POST /api/sessions/{sessionId}/attendance` - Mark attendance (requires auth)

## Authentication

Include JWT token in Authorization header:

```
Authorization: Bearer <token>
```

The token is obtained from the login endpoint.
