import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import '../models/game.dart';
import '../models/user.dart';

class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<List<Session>> _upcomingSessions;
  int _selectedIndex = 0;
  bool _needsRefresh = false;

  @override
  void initState() {
    super.initState();
    _refreshSessions();
  }

  void _refreshSessions() {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      setState(() {
        _upcomingSessions = ApiService.getSessionFeed(userId);
        _needsRefresh = false;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_needsRefresh) {
      _refreshSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.sports_esports, size: 24),
            SizedBox(width: 8),
            Text('LFG Connect'),
          ],
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshSessions,
              tooltip: 'Refresh sessions',
            ),
          ),
          const SizedBox(width: 8),
//           GestureDetector(
//   onTap: () => print("👆 Tapped"),
//   onDoubleTap: () => print("👆👆 Double tapped"),
//   onLongPress: () => print("👆⏱️ Held down"),
//   onTapDown: (details) => print("Finger touched screen"),
//   onTapUp: (details) => print("Finger lifted"),
//   child: YourWidget(),
// )
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 16,
                child: Text(
                  user?.username.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? _buildHomeTab(user?.id) // If index = 0 → Home Tab
          : _selectedIndex == 1
              ? GameCollectionScreen() // If index = 1 → Games Screen
              : _selectedIndex == 2
                  ? FriendListScreen() // If index = 2 → Friends Screen
                  : Container(), // Fallback (should never happen)
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
                backgroundColor: Colors.white,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.games),
                label: 'Games',
                backgroundColor: Colors.white,
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people),
                label: 'Friends',
                backgroundColor: Colors.white,
              ),
            ],
            selectedItemColor: const Color(0xFF6C63FF),
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
      //creates + in hoome screen to add sessions
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/create-session');
                if (result == true || result == 'refresh') {
                  setState(() {
                    _needsRefresh = true;
                  });
                }
              },
              backgroundColor: const Color(0xFFFF6584),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildHomeTab(int? userId) {
    if (userId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Theme.of(context).primaryColor),
            const SizedBox(height: 16),
            const Text(
              'Loading your gaming world...',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _refreshSessions();
        await _upcomingSessions;
      },
      child: FutureBuilder<List<Session>>(
        future: _upcomingSessions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                      color: Theme.of(context).primaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading gaming sessions...',
                    style: TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            );
          }
          //This is an ERROR HANDLING UI for failed API callsWhat is snapshot really?
// snapshot is an AsyncSnapshot<T> object that contains:

// dart
// class AsyncSnapshot<T> {
//   final ConnectionState connectionState;  // waiting, done, active
//   final T? data;                          // Your actual data (if loaded)
//   final Object? error;                    // Error (if failed)
//   final StackTrace? stackTrace;           // Where error happened

//   bool get hasData => data != null;
//   bool get hasError => error != null;
// }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Color(0xFFFF6584), size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Oops! Something went wrong',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFF666666)),
                  ),
                ],
              ),
            );
          }

          final sessions = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🎮 Friends Sessions Feed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'See what your friends are playing',
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                if (sessions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3FF),
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.group,
                            size: 40,
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No sessions yet',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Be the first to create a gaming session!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF666666),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.pushNamed(
                                context, '/create-session');
                            if (result == true || result == 'refresh') {
                              _refreshSessions();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 8),
                              Text('Create Session'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...sessions.map((session) => SessionCard(
                        session: session,
                        userId: userId,
                        onRsvpChanged: _refreshSessions,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class SessionCard extends StatefulWidget {
  final Session session;
  final int userId;
  final VoidCallback? onRsvpChanged;

  const SessionCard({
    required this.session,
    required this.userId,
    this.onRsvpChanged,
  });

  @override
  State<SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<SessionCard> {
  String? _userRsvpStatus;
  bool _loadingRsvp = false;
  List<SessionAttendee>? _allRsvps;

  @override
  void initState() {
    super.initState();
    _loadUserRsvp();
    _loadAllRsvps();
  }

  Future<void> _loadUserRsvp() async {
    if (widget.session.attendees != null &&
        widget.session.attendees!.isNotEmpty) {
      for (var attendee in widget.session.attendees!) {
        if (attendee.userId == widget.userId) {
          setState(() => _userRsvpStatus = attendee.rsvpStatus);
          return;
        }
      }
    }
    setState(() => _userRsvpStatus = null);
  }

  Future<void> _loadAllRsvps() async {
    try {
      final rsvps = await ApiService.getSessionRsvps(widget.session.id);
      setState(() => _allRsvps = rsvps);
    } catch (e) {
      print('Error loading RSVPs: $e');
    }
  }

  Future<void> _updateRsvp(String status) async {
    setState(() => _loadingRsvp = true);
    try {
      await ApiService.rsvpSession(widget.session.id, status);
      setState(() => _userRsvpStatus = status);
      _loadAllRsvps();

      if (widget.onRsvpChanged != null) {
        widget.onRsvpChanged!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are $status!'),
          backgroundColor:
              status == 'going' ? Colors.green : const Color(0xFFFF6584),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
    } finally {
      setState(() => _loadingRsvp = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goingCount =
        _allRsvps?.where((rsvp) => rsvp.rsvpStatus == 'going').length ??
            widget.session.attendees
                ?.where((a) => a.rsvpStatus == 'going')
                .length ??
            0;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F3FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.session.gameTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person,
                              size: 16, color: Color(0xFF666666)),
                          const SizedBox(width: 4),
                          Text(
                            'Hosted by ${widget.session.creatorName}',
                            style: const TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        '$goingCount going',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6C63FF),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.session.sessionDateTime
                                  .toLocal()
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.session.location ?? 'Location TBD',
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.people_alt,
                              size: 18, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            '${widget.session.maxPlayers} max players',
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF666666),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.session.note != null && widget.session.note!.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.chat,
                        size: 18, color: Theme.of(context).primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.session.note!,
                        style: const TextStyle(
                          color: Color(0xFF666666),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            if (_userRsvpStatus == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Will you join?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _loadingRsvp
                      ? Center(
                          child: CircularProgressIndicator(
                              color: Theme.of(context).primaryColor))
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _updateRsvp('going'),
                                icon: const Icon(Icons.check_circle, size: 20),
                                label: const Text('Going'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _updateRsvp('cant_go'),
                                icon: const Icon(Icons.cancel, size: 20),
                                label: const Text("Can't Go"),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFFF6584),
                                  side: const BorderSide(
                                      color: Color(0xFFFF6584)),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              )
            else
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _userRsvpStatus == 'going'
                      ? Colors.green.withOpacity(0.1)
                      : const Color(0xFFFF6584).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _userRsvpStatus == 'going'
                        ? Colors.green.withOpacity(0.3)
                        : const Color(0xFFFF6584).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _userRsvpStatus == 'going'
                          ? Icons.check_circle
                          : Icons.cancel,
                      size: 18,
                      color: _userRsvpStatus == 'going'
                          ? Colors.green
                          : const Color(0xFFFF6584),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You: ${_userRsvpStatus!.replaceAll('_', ' ')}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _userRsvpStatus == 'going'
                            ? Colors.green
                            : const Color(0xFFFF6584),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/session-detail',
                  arguments: widget.session.id,
                );

                if (result == true || result == 'refresh') {
                  _loadUserRsvp();
                  _loadAllRsvps();
                  if (widget.onRsvpChanged != null) {
                    widget.onRsvpChanged!();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View Details & All RSVPs'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GameCollectionScreen extends StatefulWidget {
  const GameCollectionScreen();

  @override
  State<GameCollectionScreen> createState() => _GameCollectionScreenState();
}

class _GameCollectionScreenState extends State<GameCollectionScreen> {
  List<Game> _games = [];
  bool _loadingGames = false;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _platformController = TextEditingController();
  final TextEditingController _genreController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _loadingGames = true);
    try {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (userId != null) {
        final games = await ApiService.getUserGames(userId);
        setState(() => _games = games);
      }
    } catch (e) {
      print('Error loading games: $e');
    } finally {
      setState(() => _loadingGames = false);
    }
  }

  Future<void> _addGame() async {
    try {
      await ApiService.addGame(
        title: _titleController.text,
        platform: _platformController.text,
        genre: _genreController.text,
        releaseYear: int.tryParse(_yearController.text),
      );
      _titleController.clear();
      _platformController.clear();
      _genreController.clear();
      _yearController.clear();
      _loadGames();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
    }
  }

  IconData _getPlatformIcon(String platform) {
    final lowerPlatform = platform.toLowerCase();

    if (lowerPlatform.contains('playstation') || lowerPlatform.contains('ps')) {
      return Icons.videogame_asset;
    } else if (lowerPlatform.contains('xbox')) {
      return Icons.sports_esports;
    } else if (lowerPlatform.contains('nintendo') ||
        lowerPlatform.contains('switch')) {
      return Icons.gamepad;
    } else if (lowerPlatform.contains('pc') ||
        lowerPlatform.contains('computer')) {
      return Icons.computer;
    } else if (lowerPlatform.contains('mobile') ||
        lowerPlatform.contains('android') ||
        lowerPlatform.contains('ios')) {
      return Icons.phone_android;
    } else {
      return Icons.sports_esports;
    }
  }

  Map<String, List<Game>> _groupGamesByPlatform() {
    final Map<String, List<Game>> groupedGames = {};

    for (var game in _games) {
      final platform = game.platform?.trim() ?? 'No Platform';
      if (!groupedGames.containsKey(platform)) {
        groupedGames[platform] = [];
      }
      groupedGames[platform]!.add(game);
    }

    final platforms = groupedGames.keys.toList();
    platforms.sort((a, b) {
      if (a == 'No Platform') return 1;
      if (b == 'No Platform') return -1;
      return a.compareTo(b);
    });

    for (var platform in platforms) {
      groupedGames[platform]!.sort((a, b) => a.title.compareTo(b.title));
    }

    return groupedGames;
  }

  List<Widget> _buildPlatformSections() {
    final groupedGames = _groupGamesByPlatform();
    final platforms = groupedGames.keys.toList();

    List<Widget> sections = [];

    for (var platform in platforms) {
      final games = groupedGames[platform]!;

      sections.add(
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getPlatformIcon(platform),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        platform,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${games.length} games',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ...games.map((game) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          game.title.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      game.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (game.genre != null && game.genre!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F3FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              game.genre!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        if (game.releaseYear != null)
                          Text(
                            'Released: ${game.releaseYear}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (game.completionStatus != null &&
                            game.completionStatus != 'not_started')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getCompletionStatusColor(
                                  game.completionStatus!),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              game.completionStatus!.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color(0xFFFF6584),
                            size: 20,
                          ),
                          onPressed: () async {
                            try {
                              await ApiService.deleteGame(game.id);
                              _loadGames();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: const Color(0xFFFF6584),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }

    return sections;
  }

  Color _getCompletionStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'not_started':
        return Colors.grey;
      case 'abandoned':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.library_books, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Game Collection',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Manage your gaming library and track your progress',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Game',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Game Title *',
                    prefixIcon: const Icon(Icons.sports_esports,
                        color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _platformController,
                  decoration: InputDecoration(
                    labelText: 'Platform (e.g., PS5, PC, Switch)',
                    prefixIcon:
                        const Icon(Icons.computer, color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _genreController,
                  decoration: InputDecoration(
                    labelText: 'Genre (e.g., RPG, FPS, Strategy)',
                    prefixIcon:
                        const Icon(Icons.category, color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _yearController,
                  decoration: InputDecoration(
                    labelText: 'Release Year',
                    prefixIcon: const Icon(Icons.calendar_today,
                        color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addGame,
                    icon: const Icon(Icons.add, size: 24),
                    label: const Text(
                      'Add to Collection',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Your Game Collection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          _loadingGames
              ? Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                          color: Theme.of(context).primaryColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading your game collection...',
                        style: TextStyle(color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                )
              : _games.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF0F3FF), Color(0xFFE0E7FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.sports_esports,
                              size: 50,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Your collection is empty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add your first game above to start building your library!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _buildPlatformSections(),
                    ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _platformController.dispose();
    _genreController.dispose();
    _yearController.dispose();
    super.dispose();
  }
}

class FriendListScreen extends StatefulWidget {
  const FriendListScreen();

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  List<User> _friends = [];
  bool _loadingFriends = false;
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _loadingFriends = true);
    try {
      final userId =
          Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (userId != null) {
        final friends = await ApiService.getFriends(userId);
        setState(() => _friends = friends);
      }
    } catch (e) {
      print('Error loading friends: $e');
    } finally {
      setState(() => _loadingFriends = false);
    }
  }

  Future<void> _addFriend() async {
    try {
      await ApiService.addFriend(_emailController.text);
      _emailController.clear();
      _loadFriends();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Friend request sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.white, size: 28),
                    SizedBox(width: 12),
                    Text(
                      'Friends',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Connect with fellow gamers and plan sessions together',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 15,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add Friend',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Friend's Email",
                    hintText: 'Enter email address',
                    prefixIcon:
                        const Icon(Icons.email, color: Color(0xFF6C63FF)),
                    filled: true,
                    fillColor: const Color(0xFFF8F9FF),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addFriend,
                    icon: const Icon(Icons.person_add, size: 24),
                    label: const Text(
                      'Add Friend',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Your Friends',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 16),
          _loadingFriends
              ? Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(
                          color: Theme.of(context).primaryColor),
                      const SizedBox(height: 16),
                      const Text(
                        'Loading friends list...',
                        style: TextStyle(color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                )
              : _friends.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFF0F3FF), Color(0xFFE0E7FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.group,
                              size: 50,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'No friends yet',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Add friends above to start gaming together!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: _friends.map((friend) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF6C63FF),
                                    Color(0xFF8B78FF)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                              ),
                              child: Center(
                                child: Text(
                                  friend.username.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              friend.username,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: const TextStyle(
                                color: Color(0xFF666666),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F3FF),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.games,
                                      size: 14, color: Color(0xFF6C63FF)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Gamer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
