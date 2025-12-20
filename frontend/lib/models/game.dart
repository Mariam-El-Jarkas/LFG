class Game {
  final int id;
  final String title;
  final String? platform;
  final String? genre;
  final int? releaseYear;
  final String? completionStatus;

  Game({
    required this.id,
    required this.title,
    this.platform,
    this.genre,
    this.releaseYear,
    this.completionStatus,
  });

  factory Game.fromJson(Map<String, dynamic> json) {
    return Game(
      id: json['id'],
      title: json['title'],
      platform: json['platform'],
      genre: json['genre'],
      releaseYear: json['release_year'],
      completionStatus: json['completion_status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'genre': genre,
      'release_year': releaseYear,
      'completion_status': completionStatus,
    };
  }
}
