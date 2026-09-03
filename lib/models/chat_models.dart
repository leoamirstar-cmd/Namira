class ChatSessionModel {
  String id;
  String title;
  List<Map<String, String>> messages;

  ChatSessionModel({required this.id, required this.title, required this.messages});

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages,
      };

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) => ChatSessionModel(
        id: json['id'],
        title: json['title'],
        messages: List<Map<String, String>>.from(json['messages'].map((x) => Map<String, String>.from(x))),
      );
}

class MusicMessageModel {
  String title;
  String author;
  String audioUrl;
  String duration;
  bool isPlaying;
  bool isDownloaded;

  MusicMessageModel({
    required this.title,
    required this.author,
    required this.audioUrl,
    required this.duration,
    this.isPlaying = false,
    this.isDownloaded = false,
  });
}
