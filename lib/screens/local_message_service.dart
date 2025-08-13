// lib/screens/local_message_service.dart

import 'package:hive/hive.dart';
import 'package:delf_global/models/message.dart';

class LocalMessageService {
  /// Guarda un mensaje en Hive bajo la caja `chat_<chatId>`
  static Future<void> saveMessage(String chatId, Message msg) async {
    // Asegúrate de haber registrado antes MessageAdapter():
    // Hive.registerAdapter(MessageAdapter());
    final box = await Hive.openBox<Message>('chat_$chatId');
    await box.add(msg);
  }

  /// Recupera todos los mensajes de Hive para el chat dado
  static Future<List<Message>> getMessages(String chatId) async {
    final box = await Hive.openBox<Message>('chat_$chatId');
    return box.values.toList();
  }

  /// Limpia todos los mensajes del chat en Hive
  static Future<void> clearMessages(String chatId) async {
    final box = await Hive.openBox<Message>('chat_$chatId');
    await box.clear();
  }
}
