import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  @JsonKey(name: 'id')
  String id;
  
  @JsonKey(name: 'content')
  String content;
  
  @JsonKey(name: 'is_user')
  bool isUser;
  
  @JsonKey(name: 'timestamp')
  DateTime timestamp;
  
  @JsonKey(name: 'mode')
  String mode; // 'work' or 'personal'
  
  @JsonKey(name: 'metadata')
  Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    required this.mode,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => 
      _$ChatMessageFromJson(json);
  
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class Conversation {
  @JsonKey(name: 'id')
  String id;
  
  @JsonKey(name: 'title')
  String title;
  
  @JsonKey(name: 'messages')
  List<ChatMessage> messages;
  
  @JsonKey(name: 'created_at')
  DateTime createdAt;
  
  @JsonKey(name: 'updated_at')
  DateTime updatedAt;
  
  @JsonKey(name: 'mode')
  String mode;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    required this.mode,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => 
      _$ConversationFromJson(json);
  
  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}