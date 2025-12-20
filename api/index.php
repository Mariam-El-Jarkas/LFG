
<?php
// ==================== CORS HEADERS ====================
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS, PATCH");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-User-Id, X-Requested-With, Accept, Origin");
header("Access-Control-Allow-Credentials: true");
header("Access-Control-Expose-Headers: Content-Length, Content-Range");
header("Access-Control-Max-Age: 86400"); // 24 hours cache

// Handle preflight OPTIONS request
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}
// ======================================================

// Rest of your existing code...
header('Content-Type: application/json');


require_once __DIR__ . '/config/database.php';

// Get route from query parameter
$route = $_GET['route'] ?? '';
$route = trim($route, '/');
$method = $_SERVER['REQUEST_METHOD'];

// If no route, show API info
if ($route === '') {
    echo json_encode([
        'api_name' => 'LFG Connect API',
        'version' => '1.0',
        'status' => 'running',
        'message' => 'API is working! Use ?route=endpoint',
        'endpoints' => [
            'POST ?route=auth/register' => 'Register user',
            'POST ?route=auth/login' => 'Login user',
            'GET ?route=auth/user/{id}' => 'Get user info',
            'POST ?route=games/add' => 'Add game (requires X-User-Id)',
            'GET ?route=games/user/{id}' => 'Get user games',
            'DELETE ?route=games/{id}' => 'Delete game (requires X-User-Id)',
            'POST ?route=friends/add' => 'Add friend (requires X-User-Id)',
            'GET ?route=friends/{userId}' => 'Get friends',
            'POST ?route=sessions/create' => 'Create session (requires X-User-Id)',
            'GET ?route=sessions/user/{id}' => 'Get user sessions',
            'GET ?route=sessions/feed/{userId}' => 'Get session feed from friends',
            'GET ?route=sessions/{id}' => 'Get session details',
            'GET ?route=sessions/{id}/rsvps' => 'Get session RSVPs',
            'POST ?route=sessions/{id}/rsvp' => 'RSVP to session (requires X-User-Id)',
            'POST ?route=sessions/{id}/attendance' => 'Mark attendance (requires X-User-Id)'
        ]
    ]);
    exit;
}

// Split route into parts
$parts = explode('/', $route);

// Helper function to get authenticated user
function getAuthenticatedUser($pdo) {
    $headers = getallheaders();
    $userId = $headers['X-User-Id'] ?? null;
    
    if ($userId) {
        try {
            $stmt = $pdo->prepare('SELECT id, username, email FROM users WHERE id = ?');
            $stmt->execute([$userId]);
            return $stmt->fetch();
        } catch (Exception $e) {
            return null;
        }
    }
    return null;
}

// ==================== AUTH ROUTES ====================
if ($parts[0] === 'auth') {
    require_once __DIR__ . '/controllers/AuthController.php';
    
    if (!class_exists('AuthController')) {
        http_response_code(500);
        echo json_encode(['error' => 'AuthController not loaded']);
        exit;
    }
    
    $controller = new AuthController($pdo);
    
    // POST /auth/register
    if (isset($parts[1]) && $parts[1] === 'register' && $method === 'POST') {
        echo $controller->register();
        exit;
    }
    
    // POST /auth/login
    if (isset($parts[1]) && $parts[1] === 'login' && $method === 'POST') {
        echo $controller->login();
        exit;
    }
    
    // GET /auth/user/{id}
    if (isset($parts[1]) && $parts[1] === 'user' && isset($parts[2]) && $method === 'GET') {
        echo $controller->getUser($parts[2]);
        exit;
    }
}

// ==================== GAMES ROUTES ====================
if ($parts[0] === 'games') {
    require_once __DIR__ . '/controllers/GameController.php';
    
    if (!class_exists('GameController')) {
        http_response_code(500);
        echo json_encode(['error' => 'GameController not loaded']);
        exit;
    }
    
    $user = getAuthenticatedUser($pdo);
    $controller = new GameController($pdo, $user);
    
    // POST /games/add (requires auth)
    if (isset($parts[1]) && $parts[1] === 'add' && $method === 'POST') {
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required. Add X-User-Id header']);
            exit;
        }
        echo $controller->addGame();
        exit;
    }
    
    // GET /games/user/{userId}
    if (isset($parts[1]) && $parts[1] === 'user' && isset($parts[2]) && $method === 'GET') {
        echo $controller->getUserGames($parts[2]);
        exit;
    }
    
    // DELETE /games/{gameId} (requires auth)
    if (isset($parts[1]) && $method === 'DELETE') {
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            exit;
        }
        echo $controller->deleteGame($parts[1]);
        exit;
    }
}

// ==================== FRIENDS ROUTES ====================
if ($parts[0] === 'friends') {
    require_once __DIR__ . '/controllers/FriendController.php';
    
    if (!class_exists('FriendController')) {
        http_response_code(500);
        echo json_encode(['error' => 'FriendController not loaded']);
        exit;
    }
    
    $user = getAuthenticatedUser($pdo);
    $controller = new FriendController($pdo, $user);
    
    // POST /friends/add (requires auth)
    if (isset($parts[1]) && $parts[1] === 'add' && $method === 'POST') {
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            exit;
        }
        echo $controller->addFriend();
        exit;
    }
    
    // GET /friends/{userId}
    if (isset($parts[1]) && $method === 'GET') {
        echo $controller->getFriends($parts[1]);
        exit;
    }
    
    // GET /friends/{userId}/games/{friendId}
    if (isset($parts[2]) && $parts[2] === 'games' && isset($parts[3]) && $method === 'GET') {
        echo $controller->getFriendGames($parts[1], $parts[3]);
        exit;
    }
}

// ==================== SESSIONS ROUTES ====================
if ($parts[0] === 'sessions') {
    require_once __DIR__ . '/controllers/SessionController.php';
    
    if (!class_exists('SessionController')) {
        http_response_code(500);
        echo json_encode(['error' => 'SessionController not loaded']);
        exit;
    }
    
    $user = getAuthenticatedUser($pdo);
    $controller = new SessionController($pdo, $user);
    
    // POST /sessions/create (requires auth)
    if (isset($parts[1]) && $parts[1] === 'create' && $method === 'POST') {
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            exit;
        }
        echo $controller->createSession();
        exit;
    }
    
    // GET /sessions/user/{userId}
    if (isset($parts[1]) && $parts[1] === 'user' && isset($parts[2]) && $method === 'GET') {
        echo $controller->getUserSessions($parts[2]);
        exit;
    }
    
    // GET /sessions/feed/{userId}
    if (isset($parts[1]) && $parts[1] === 'feed' && isset($parts[2]) && $method === 'GET') {
        echo $controller->getSessionFeed($parts[2]);
        exit;
    }
    
    // GET /sessions/{sessionId}
    if (isset($parts[1]) && !isset($parts[2]) && $method === 'GET') {
        echo $controller->getSessionDetails($parts[1]);
        exit;
    }
    
    // GET /sessions/{sessionId}/rsvps
    if (isset($parts[2]) && $parts[2] === 'rsvps' && $method === 'GET' && isset($parts[1])) {
        echo $controller->getSessionRsvps($parts[1]);
        exit;
    }
    
    // POST /sessions/{sessionId}/rsvp (requires auth)
    if (isset($parts[2]) && $parts[2] === 'rsvp' && $method === 'POST' && isset($parts[1])) {
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            exit;
        }
        echo $controller->rsvpSession($parts[1]);
        exit;
    }
    
    // POST /sessions/{sessionId}/attendance (requires auth)
    if (isset($parts[2]) && $parts[2] === 'attendance' && $method === 'POST' && isset($parts[1])) {
        if (!$user) {
            http_response_code(401);
            echo json_encode(['error' => 'Authentication required']);
            exit;
        }
        echo $controller->markAttendance($parts[1]);
        exit;
    }
}

// If no route matched
http_response_code(404);
echo json_encode([
    'error' => 'Endpoint not found',
    'route' => $route,
    'method' => $method,
    'parts' => $parts,
    'available_routes' => [
        'POST auth/register',
        'POST auth/login',
        'GET auth/user/{id}',
        'POST games/add',
        'GET games/user/{id}',
        'DELETE games/{id}',
        'POST friends/add',
        'GET friends/{userId}',
        'POST sessions/create',
        'GET sessions/user/{id}',
        'GET sessions/feed/{userId}',
        'GET sessions/{id}',
        'GET sessions/{id}/rsvps',
        'POST sessions/{id}/rsvp',
        'POST sessions/{id}/attendance'
    ]
]);