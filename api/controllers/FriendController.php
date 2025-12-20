<?php
require_once __DIR__ . '/../config/database.php';

class FriendController {
    private $pdo;
    private $user;

    public function __construct($pdo, $user) {
        $this->pdo = $pdo;
        $this->user = $user;
    }

    public function addFriend() {
        if (!$this->user) {
            http_response_code(401);
            die(json_encode(['error' => 'Unauthorized']));
        }

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data || !isset($data['friendEmail'])) {
            http_response_code(400);
            return json_encode(['error' => 'Friend email required']);
        }

        try {
            $stmt = $this->pdo->prepare('SELECT id FROM users WHERE email = ?');
            $stmt->execute([$data['friendEmail']]);
            $friend = $stmt->fetch();

            if (!$friend) {
                http_response_code(404);
                return json_encode(['error' => 'User not found']);
            }

            $friendId = $friend['id'];

            if ($friendId === $this->user['id']) {
                http_response_code(400);
                return json_encode(['error' => 'Cannot add yourself as friend']);
            }

            try {
                $stmt = $this->pdo->prepare('INSERT INTO friends (user1_id, user2_id, status) VALUES (?, ?, ?)');
                $stmt->execute([$this->user['id'], $friendId, 'accepted']);
            } catch (Exception $e) {
            }

            http_response_code(201);
            return json_encode([
                'message' => 'Friend added successfully',
                'friendId' => $friendId,
                'friendEmail' => $data['friendEmail']
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to add friend: ' . $e->getMessage()]);
        }
    }

    public function getFriends($userId) {
        try {
            $stmt = $this->pdo->prepare('SELECT u.id, u.username, u.email, f.status
                                        FROM friends f
                                        JOIN users u ON (
                                            (f.user1_id = ? AND f.user2_id = u.id) OR
                                            (f.user2_id = ? AND f.user1_id = u.id)
                                        )
                                        WHERE f.status = "accepted"');
            $stmt->execute([$userId, $userId]);
            $friends = $stmt->fetchAll();

            return json_encode($friends);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to fetch friends: ' . $e->getMessage()]);
        }
    }

    public function getFriendGames($userId, $friendId) {
        try {
            $stmt = $this->pdo->prepare('SELECT g.id, g.title, g.platform, g.genre, g.release_year
                                        FROM user_games ug
                                        JOIN games g ON ug.game_id = g.id
                                        WHERE ug.user_id = ?');
            $stmt->execute([$friendId]);
            $games = $stmt->fetchAll();

            return json_encode($games);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to fetch friend games: ' . $e->getMessage()]);
        }
    }
}

