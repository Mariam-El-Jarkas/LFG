import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/session.dart';
import '../models/game.dart';

class SessionCreateScreen extends StatefulWidget {
  @override
  State<SessionCreateScreen> createState() => _SessionCreateScreenState();
}

class _SessionCreateScreenState extends State<SessionCreateScreen> {
  final _locationController = TextEditingController();
  final _maxPlayersController = TextEditingController(text: '4');
  final _noteController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;
  List<Game> _userGames = [];
  Game? _selectedGame;
  bool _loadingGames = false;
  bool _showAddNewGame = false;
  final _newGameTitleController = TextEditingController();
  final _newGamePlatformController = TextEditingController();
  final _newGameGenreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserGames();
  }

  Future<void> _loadUserGames() async {
    setState(() => _loadingGames = true);
    try {
      final userId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
      if (userId != null) {
        final games = await ApiService.getUserGames(userId);
        setState(() => _userGames = games);
      }
    } catch (e) {
      print('Error loading games: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load games: $e'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
    } finally {
      setState(() => _loadingGames = false);
    }
  }

  Future<void> _addNewGame() async {
    if (_newGameTitleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game title is required'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.addGame(
        title: _newGameTitleController.text,
        platform: _newGamePlatformController.text.isNotEmpty ? _newGamePlatformController.text : null,
        genre: _newGameGenreController.text.isNotEmpty ? _newGameGenreController.text : null,
      );
      
      // Reload games list
      await _loadUserGames();
      
      // Find and select the newly added game
      final newGame = _userGames.firstWhere(
        (game) => game.title == _newGameTitleController.text,
        orElse: () => _userGames.first,
      );
      
      setState(() {
        _selectedGame = newGame;
        _showAddNewGame = false;
      });
      
      // Clear new game form
      _newGameTitleController.clear();
      _newGamePlatformController.clear();
      _newGameGenreController.clear();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Game added successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding game: $e'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _createSession() async {
    if (_selectedGame == null || _selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a game and date/time'),
          backgroundColor: Color(0xFFFF6584),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.createSession(
        gameId: _selectedGame!.id,
        sessionDateTime: _selectedDateTime!,
        location: _locationController.text,
        maxPlayers: int.tryParse(_maxPlayersController.text) ?? 4,
        note: _noteController.text,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating session: $e'),
          backgroundColor: const Color(0xFFFF6584),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildGameSelection() {
    if (_loadingGames) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Theme.of(context).primaryColor),
              const SizedBox(height: 8),
              const Text(
                'Loading your games...',
                style: TextStyle(color: Color(0xFF666666)),
              ),
            ],
          ),
        ),
      );
    }

    if (_showAddNewGame) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF6C63FF), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add New Game',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6C63FF),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newGameTitleController,
              decoration: InputDecoration(
                labelText: 'Game Title *',
                prefixIcon: const Icon(Icons.sports_esports, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newGamePlatformController,
              decoration: InputDecoration(
                labelText: 'Platform (e.g., PS5, PC, Switch)',
                prefixIcon: const Icon(Icons.computer, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newGameGenreController,
              decoration: InputDecoration(
                labelText: 'Genre (e.g., RPG, FPS, Strategy)',
                prefixIcon: const Icon(Icons.category, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8F9FF),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _showAddNewGame = false);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF666666),
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _addNewGame,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Add Game'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Game *',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (_selectedGame != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _selectedGame!.title.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedGame!.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            if (_selectedGame!.platform != null)
                              Text(
                                _selectedGame!.platform!,
                                style: const TextStyle(
                                  color: Color(0xFF666666),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() => _selectedGame = null);
                        },
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sports_esports, color: Color(0xFF999999)),
                      SizedBox(width: 12),
                      Text(
                        'No game selected',
                        style: TextStyle(color: Color(0xFF999999)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_userGames.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: ExpansionTile(
              title: const Text(
                'Your Game Collection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              initiallyExpanded: false,
              children: _userGames.map((game) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF8B78FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        game.title.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    game.title,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: game.platform != null
                      ? Text(
                          game.platform!,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  trailing: _selectedGame?.id == game.id
                      ? const Icon(Icons.check_circle, color: Color(0xFF6C63FF))
                      : null,
                  onTap: () {
                    setState(() => _selectedGame = game);
                  },
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            setState(() => _showAddNewGame = true);
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add New Game'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6C63FF),
            side: const BorderSide(color: Color(0xFF6C63FF)),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Session'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FF),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
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
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.add_circle, color: Color(0xFF6C63FF), size: 28),
                        SizedBox(width: 12),
                        Text(
                          'New Gaming Session',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Plan your next gaming session with friends',
                      style: TextStyle(
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Game Selection Section
                    _buildGameSelection(),
                    const SizedBox(height: 20),
                    // Date & Time
                    GestureDetector(
                      onTap: _selectDateTime,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE0E0E0)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date & Time *',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: const Color(0xFF999999),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedDateTime == null
                                        ? 'Select date and time'
                                        : _selectedDateTime!.toLocal().toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: _selectedDateTime == null
                                          ? const Color(0xFF999999)
                                          : const Color(0xFF333333),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_drop_down,
                              color: Theme.of(context).primaryColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        labelText: 'Location',
                        prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6C63FF)),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _maxPlayersController,
                      decoration: InputDecoration(
                        labelText: 'Max Players',
                        prefixIcon: const Icon(Icons.people, color: Color(0xFF6C63FF)),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        prefixIcon: const Icon(Icons.note, color: Color(0xFF6C63FF)),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FF),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_isLoading || _selectedGame == null || _selectedDateTime == null) 
                            ? null 
                            : _createSession,
                        icon: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.add),
                        label: _isLoading
                            ? const Text('Creating...')
                            : const Text('Create Session'),
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
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Color(0xFF6C63FF)),
                        SizedBox(width: 8),
                        Text(
                          'Tips for a great session:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• Pick a convenient time for everyone'),
                    Text('• Make sure your location has enough space'),
                    Text('• Select a game from your collection'),
                    Text('• Add notes about any special requirements'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    _maxPlayersController.dispose();
    _noteController.dispose();
    _newGameTitleController.dispose();
    _newGamePlatformController.dispose();
    _newGameGenreController.dispose();
    super.dispose();
  }
}

class SessionDetailScreen extends StatefulWidget {
  final int sessionId;

  const SessionDetailScreen({required this.sessionId});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  late Future<Session> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = ApiService.getSessionDetails(widget.sessionId);
  }

  void _refreshSession() {
    setState(() {
      _sessionFuture = ApiService.getSessionDetails(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Details'),
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshSession,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF5F7FF),
              Colors.white,
            ],
          ),
        ),
        child: FutureBuilder<Session>(
          future: _sessionFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading session details...',
                      style: TextStyle(color: Color(0xFF666666)),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, color: Color(0xFFFF6584), size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      'Failed to load session',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshSession,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              );
            }

            final session = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F3FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            session.gameTitle,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6C63FF),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.person, size: 18, color: Color(0xFF666666)),
                            const SizedBox(width: 8),
                            Text(
                              'Hosted by ${session.creatorName}',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF666666),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          title: 'Date & Time',
                          value: session.sessionDateTime.toLocal().toString(),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.location_on,
                          title: 'Location',
                          value: session.location ?? 'To be decided',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.people,
                          title: 'Max Players',
                          value: '${session.maxPlayers} players',
                        ),
                        if (session.note != null && session.note!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.note,
                            title: 'Notes',
                            value: session.note!,
                            isMultiline: true,
                          ),
                        ],
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
                        const Row(
                          children: [
                            Icon(Icons.people, color: Color(0xFF6C63FF)),
                            SizedBox(width: 8),
                            Text(
                              'Attendees',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (session.attendees == null || session.attendees!.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.group,
                                  size: 60,
                                  color: Color(0xFF999999),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No attendees yet',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Be the first to join this session!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Color(0xFF999999),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...session.attendees!.map(
                            (attendee) => Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: CircleAvatar(
                                  backgroundColor: _getRsvpColor(attendee.rsvpStatus),
                                  radius: 22,
                                  child: Text(
                                    attendee.username.substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  attendee.username,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  attendee.email,
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getRsvpColor(attendee.rsvpStatus)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: _getRsvpColor(attendee.rsvpStatus)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        attendee.rsvpStatus.replaceAll('_', ' '),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: _getRsvpColor(attendee.rsvpStatus),
                                        ),
                                      ),
                                    ),
                                    if (attendee.attended)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String title,
    required String value,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment: isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF999999),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF333333),
                ),
                maxLines: isMultiline ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getRsvpColor(String status) {
    switch (status) {
      case 'going':
        return Colors.green;
      case 'cant_go':
        return const Color(0xFFFF6584);
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}