<?php
class SessionController {
    private $pdo;
    private $user;

    public function __construct($pdo, $user) {
        $this->pdo = $pdo;
        $this->user = $user;
    }

    public function createSession() {
        if (!$this->user) {
            http_response_code(401);
            return json_encode(['error' => 'Unauthorized']);
        }

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data || !isset($data['gameId'], $data['session_datetime'])) {
            http_response_code(400);
            return json_encode(['error' => 'Game ID and datetime required']);
        }

        try {
            $stmt = $this->pdo->prepare('INSERT INTO sessions (creator_id, game_id, session_datetime, location, max_players, note) 
                                        VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute([
                $this->user['id'],
                $data['gameId'],
                $data['session_datetime'],
                $data['location'] ?? null,
                $data['max_players'] ?? 4,
                $data['note'] ?? null
            ]);
            
            $sessionId = $this->pdo->lastInsertId();

            // Add creator as attendee
            $stmt = $this->pdo->prepare('INSERT INTO session_attendees (session_id, user_id, rsvp_status) VALUES (?, ?, ?)');
            $stmt->execute([$sessionId, $this->user['id'], 'going']);

            http_response_code(201);
            return json_encode([
                'message' => 'Session created successfully',
                'sessionId' => $sessionId,
                'gameId' => $data['gameId'],
                'session_datetime' => $data['session_datetime'],
                'location' => $data['location'] ?? null
            ]);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to create session: ' . $e->getMessage()]);
        }
    }

    public function getUserSessions($userId) {
        try {
            $query = 'SELECT s.id, s.game_id, g.title as game_title, s.creator_id, u.username as creator_name,
                             s.session_datetime, s.location, s.max_players, s.note, s.created_at
                     FROM sessions s
                     JOIN games g ON s.game_id = g.id
                     JOIN users u ON s.creator_id = u.id
                     WHERE s.creator_id = ?';
            $params = [$userId];

            if (isset($_GET['status'])) {
                if ($_GET['status'] === 'upcoming') {
                    $query .= ' AND s.session_datetime > NOW()';
                } elseif ($_GET['status'] === 'past') {
                    $query .= ' AND s.session_datetime <= NOW()';
                }
            }

            $query .= ' ORDER BY s.session_datetime DESC';

            $stmt = $this->pdo->prepare($query);
            $stmt->execute($params);
            $sessions = $stmt->fetchAll();

            return json_encode($sessions);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to fetch sessions: ' . $e->getMessage()]);
        }
    }

    public function getSessionDetails($sessionId) {
        try {
            $stmt = $this->pdo->prepare('SELECT s.id, s.game_id, g.title as game_title, s.creator_id, u.username as creator_name,
                                                s.session_datetime, s.location, s.max_players, s.note, s.created_at
                                        FROM sessions s
                                        JOIN games g ON s.game_id = g.id
                                        JOIN users u ON s.creator_id = u.id
                                        WHERE s.id = ?');
            $stmt->execute([$sessionId]);
            $session = $stmt->fetch();

            if (!$session) {
                http_response_code(404);
                return json_encode(['error' => 'Session not found']);
            }

            // Get attendees
            $stmt = $this->pdo->prepare('SELECT sa.user_id, u.username, u.email, sa.rsvp_status, sa.attended
                                        FROM session_attendees sa
                                        JOIN users u ON sa.user_id = u.id
                                        WHERE sa.session_id = ?');
            $stmt->execute([$sessionId]);
            $attendees = $stmt->fetchAll();

            $session['attendees'] = $attendees;
            return json_encode($session);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to fetch session details: ' . $e->getMessage()]);
        }
    }

    public function rsvpSession($sessionId) {
        if (!$this->user) {
            http_response_code(401);
            return json_encode(['error' => 'Unauthorized']);
        }

        $data = json_decode(file_get_contents('php://input'), true);
        
        if (!$data || !isset($data['rsvpStatus'])) {
            http_response_code(400);
            return json_encode(['error' => 'RSVP status required']);
        }

        try {
            // Check if user is already an attendee
            $checkStmt = $this->pdo->prepare('SELECT * FROM session_attendees WHERE session_id = ? AND user_id = ?');
            $checkStmt->execute([$sessionId, $this->user['id']]);
            $existing = $checkStmt->fetch();
            
            if ($existing) {
                // Update existing RSVP
                $stmt = $this->pdo->prepare('UPDATE session_attendees SET rsvp_status = ? WHERE session_id = ? AND user_id = ?');
                $stmt->execute([$data['rsvpStatus'], $sessionId, $this->user['id']]);
            } else {
                // Insert new RSVP
                $stmt = $this->pdo->prepare('INSERT INTO session_attendees (session_id, user_id, rsvp_status) VALUES (?, ?, ?)');
                $stmt->execute([$sessionId, $this->user['id'], $data['rsvpStatus']]);
            }

            return json_encode(['message' => 'RSVP updated successfully', 'rsvpStatus' => $data['rsvpStatus']]);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to update RSVP: ' . $e->getMessage()]);
        }
    }

    public function markAttendance($sessionId) {
        if (!$this->user) {
            http_response_code(401);
            return json_encode(['error' => 'Unauthorized']);
        }

        $data = json_decode(file_get_contents('php://input'), true);

        try {
            // Verify user is session creator
            $stmt = $this->pdo->prepare('SELECT creator_id FROM sessions WHERE id = ?');
            $stmt->execute([$sessionId]);
            $session = $stmt->fetch();

            if (!$session || $session['creator_id'] !== $this->user['id']) {
                http_response_code(403);
                return json_encode(['error' => 'Only session creator can mark attendance']);
            }

            // Update attendance
            if (isset($data['attendedUserIds']) && is_array($data['attendedUserIds'])) {
                foreach ($data['attendedUserIds'] as $attendeeId) {
                    $stmt = $this->pdo->prepare('UPDATE session_attendees SET attended = TRUE WHERE session_id = ? AND user_id = ?');
                    $stmt->execute([$sessionId, $attendeeId]);
                }
            }

            return json_encode(['message' => 'Attendance marked successfully']);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode(['error' => 'Failed to mark attendance: ' . $e->getMessage()]);
        }
    }

    public function getSessionFeed($userId) {
        try {
            $query = "SELECT s.*, 
                         g.title as game_title,
                         u.username as creator_name
                  FROM sessions s
                  JOIN games g ON s.game_id = g.id
                  JOIN users u ON s.creator_id = u.id
                  WHERE (
                      s.creator_id = ? 
                      OR s.creator_id IN (
                          SELECT user2_id FROM friends 
                          WHERE user1_id = ? AND status = 'accepted'
                          UNION
                          SELECT user1_id FROM friends 
                          WHERE user2_id = ? AND status = 'accepted'
                      )
                  )
                  AND s.session_datetime >= CURDATE()
                  ORDER BY s.session_datetime ASC";
        
            $stmt = $this->pdo->prepare($query);
            $stmt->execute([$userId, $userId, $userId]);
            $sessions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
            foreach ($sessions as &$session) {
                $attendeeQuery = "SELECT u.id as user_id, u.username, u.email, 
                                         sa.rsvp_status, sa.attended
                                  FROM session_attendees sa
                                  JOIN users u ON sa.user_id = u.id
                                  WHERE sa.session_id = ?";
                $attendeeStmt = $this->pdo->prepare($attendeeQuery);
                $attendeeStmt->execute([$session['id']]);
                $attendees = $attendeeStmt->fetchAll(PDO::FETCH_ASSOC);
            
                // Count "going" attendees
                $goingCount = 0;
                
                foreach ($attendees as $attendee) {
                    if ($attendee['rsvp_status'] === 'going') {
                        $goingCount++;
                    }
                }
            
                $session['attendees'] = $attendees;
                $session['going_count'] = $goingCount;
            }
    
            return json_encode($sessions);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode([
                'error' => 'Failed to fetch session feed',
                'message' => $e->getMessage()
            ]);
        }
    }

    public function getSessionRsvps($sessionId) {
        try {
            $query = "SELECT u.id as user_id, u.username, u.email, 
                             sa.rsvp_status, sa.attended
                      FROM session_attendees sa
                      JOIN users u ON sa.user_id = u.id
                      WHERE sa.session_id = ?
                      ORDER BY 
                          CASE sa.rsvp_status 
                              WHEN 'going' THEN 1
                              WHEN 'pending' THEN 2
                              WHEN 'cant_go' THEN 3
                              ELSE 4
                          END,
                          u.username";
            
            $stmt = $this->pdo->prepare($query);
            $stmt->execute([$sessionId]);
            $rsvps = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            return json_encode($rsvps);
        } catch (Exception $e) {
            http_response_code(500);
            return json_encode([
                'error' => 'Failed to fetch session RSVPs',
                'message' => $e->getMessage()
            ]);
        }
    }
}