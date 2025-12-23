<?php
require_once __DIR__ . '/../config/database.php';

class AuthController {
    private $pdo;

    public function __construct($pdo) {
        $this->pdo = $pdo;
    }

    public function register() {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data || !isset($data['username'], $data['email'], $data['password'])) {
            http_response_code(400);
            return json_encode(['error' => 'Username, email, and password required']);
        }

        try {
            $stmt = $this->pdo->prepare('SELECT id FROM users WHERE email = ? OR username = ?');
            $stmt->execute([$data['email'], $data['username']]);
            
            if ($stmt->fetch()) {
                http_response_code(409);
                return json_encode(['error' => 'User already exists']);
            }

    
            $plainPassword = $data['password'];
            
    
            $stmt = $this->pdo->prepare('INSERT INTO users (username, email, password) VALUES (?, ?, ?)');
            $stmt->execute([$data['username'], $data['email'], $plainPassword]);
            
            $userId = $this->pdo->lastInsertId();
            
            $stmt = $this->pdo->prepare('SELECT id, username, email, created_at FROM users WHERE id = ?');
            $stmt->execute([$userId]);
            $user = $stmt->fetch();
            
            http_response_code(201);
            return json_encode([
                'message' => 'User registered successfully',
                'user' => $user
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Registration failed: ' . $e->getMessage()]);
        }
    }

    public function login() {
        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data || !isset($data['email'], $data['password'])) {
            http_response_code(400);
            return json_encode(['error' => 'Email and password required']);
        }

        try {
          
            $stmt = $this->pdo->prepare('SELECT id, username, email, password, created_at FROM users WHERE email = ?');
            $stmt->execute([$data['email']]);
            $user = $stmt->fetch();

      
            if (!$user || $user['password'] !== $data['password']) {
                http_response_code(401);
                return json_encode(['error' => 'Invalid credentials']);
            }

            unset($user['password']);
            
            return json_encode([
                'message' => 'Login successful',
                'user' => $user
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Login failed: ' . $e->getMessage()]);
        }
    }

    public function getUser($userId) {
        try {
            $stmt = $this->pdo->prepare('SELECT id, username, email, created_at FROM users WHERE id = ?');
            $stmt->execute([$userId]);
            $user = $stmt->fetch();

            if (!$user) {
                http_response_code(404);
                return json_encode(['error' => 'User not found']);
            }

            return json_encode($user);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to fetch user: ' . $e->getMessage()]);
        }
    }
}