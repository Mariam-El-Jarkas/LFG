class Session {
  final int id;
  final int gameId;
  final String gameTitle;
  final int creatorId;
  final String creatorName;
  final DateTime sessionDateTime;
  final String? location;
  final int maxPlayers;
  final String? note;
  final DateTime createdAt;
  final List<SessionAttendee>? attendees;

  Session({
    required this.id,
    required this.gameId,
    required this.gameTitle,
    required this.creatorId,
    required this.creatorName,
    required this.sessionDateTime,
    this.location,
    required this.maxPlayers,
    this.note,
    required this.createdAt,
    this.attendees,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'],
      gameId: json['game_id'],
      gameTitle: json['game_title'],
      creatorId: json['creator_id'],
      creatorName: json['creator_name'],
      sessionDateTime: DateTime.parse(json['session_datetime']),
      location: json['location'],
      maxPlayers: json['max_players'],
      note: json['note'],
      createdAt: DateTime.parse(json['created_at']),
      attendees: (json['attendees'] as List<dynamic>?)
          ?.map((a) => SessionAttendee.fromJson(a))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'game_id': gameId,
      'game_title': gameTitle,
      'creator_id': creatorId,
      'creator_name': creatorName,
      'session_datetime': sessionDateTime.toIso8601String(),
      'location': location,
      'max_players': maxPlayers,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'attendees': attendees?.map((a) => a.toJson()).toList(),
    };
  }
}

class SessionAttendee {
  final int userId;
  final String username;
  final String email;
  final String rsvpStatus;
  final bool attended;

  SessionAttendee({
    required this.userId,
    required this.username,
    required this.email,
    required this.rsvpStatus,
    required this.attended,
  });

  factory SessionAttendee.fromJson(Map<String, dynamic> json) {
    return SessionAttendee(
      userId: json['user_id'],
      username: json['username'],
      email: json['email'],
      rsvpStatus: json['rsvp_status'],
      attended: json['attended'] == 1 || json['attended'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'email': email,
      'rsvp_status': rsvpStatus,
      'attended': attended,
    };
  }
}