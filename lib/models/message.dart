import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'message.g.dart';

@HiveType(typeId: 0)
class Message {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String fromUserId;

  @HiveField(2)
  final String toUserId;

  @HiveField(3)
  final String content;

  @HiveField(4)
  final DateTime timestamp;

  Message({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.content,
    required this.timestamp,
  });

  /// Crea un Message desde un documento Firestore
  factory Message.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return Message(
      id: doc.id,
      fromUserId: data['fromUserId'] as String,
      toUserId: data['toUserId'] as String,
      content: data['content'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  /// Convierte este Message a un mapa para Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'content': content,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
