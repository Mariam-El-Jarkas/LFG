<?php
require_once __DIR__ . '/../config/database.php';

class GameController {
    private $pdo;
    private $user;

    public function __construct($pdo, $user) {
        $this->pdo = $pdo;
        $this->user = $user;
    }

    public function addGame() {
        if (!$this->user) {
            http_response_code(401);
            die(json_encode(['error' => 'Unauthorized']));
        }

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data || !isset($data['title'])) {
            http_response_code(400);
            return json_encode(['error' => 'Game title required']);
        }

        try {
            $stmt = $this->pdo->prepare('SELECT id FROM games WHERE title = ? AND platform = ?');
            $stmt->execute([$data['title'], $data['platform'] ?? null]);
            $game = $stmt->fetch();

            if ($game) {
                $gameId = $game['id'];
            } else {
                $stmt = $this->pdo->prepare('INSERT INTO games (title, platform, genre, release_year) VALUES (?, ?, ?, ?)');
                $stmt->execute([
                    $data['title'],
                    $data['platform'] ?? null,
                    $data['genre'] ?? null,
                    $data['release_year'] ?? null
                ]);
                $gameId = $this->pdo->lastInsertId();
            }

            $stmt = $this->pdo->prepare('INSERT INTO user_games (user_id, game_id, completion_status) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE completion_status = ?');
            $stmt->execute([$this->user['id'], $gameId, 'not_started', 'not_started']);

            http_response_code(201);
            return json_encode([
                'message' => 'Game added to collection',
                'gameId' => $gameId,
                'title' => $data['title'],
                'platform' => $data['platform'] ?? null
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to add game: ' . $e->getMessage()]);
        }
    }

    public function getUserGames($userId) {
        try {
            $query = 'SELECT g.id, g.title, g.platform, g.genre, g.release_year, ug.completion_status
                     FROM user_games ug
                     JOIN games g ON ug.game_id = g.id
                     WHERE ug.user_id = ?';
            $params = [$userId];

            if (isset($_GET['platform'])) {
                $query .= ' AND g.platform = ?';
                $params[] = $_GET['platform'];
            }
            if (isset($_GET['genre'])) {
                $query .= ' AND g.genre = ?';
                $params[] = $_GET['genre'];
            }
            if (isset($_GET['search'])) {
                $query .= ' AND g.title LIKE ?';
                $params[] = '%' . $_GET['search'] . '%';
            }

            $stmt = $this->pdo->prepare($query);
            $stmt->execute($params);
            $games = $stmt->fetchAll();

            return json_encode($games);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to fetch games: ' . $e->getMessage()]);
        }
    }

    public function deleteGame($gameId) {
        if (!$this->user) {
            http_response_code(401);
            die(json_encode(['error' => 'Unauthorized']));
        }

        try {
            $stmt = $this->pdo->prepare('DELETE FROM user_games WHERE user_id = ? AND game_id = ?');
            $stmt->execute([$this->user['id'], $gameId]);

            return json_encode(['message' => 'Game removed from collection']);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to delete game: ' . $e->getMessage()]);
        }
    }
}
