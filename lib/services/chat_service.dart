// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  /// ID determinístico para 1–a–1: uids ordenados unidos por "_"
  static String _pairId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Crea (si no existe) o devuelve el chat 1–a–1 entre el usuario actual y [otherUid].
  /// Asegura: chats/{chatId} con `participants`, `createdAt`, `updatedAt`, `ultimoMensaje`.
  static Future<String> getOrCreate1to1(String otherUid) async {
    final me = FirebaseAuth.instance.currentUser!;
    if (otherUid == me.uid) {
      throw StateError('No puedes crear un chat contigo mismo.');
    }

    final chatId = _pairId(me.uid, otherUid);
    final ref = FirebaseFirestore.instance.collection('chats').doc(chatId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final participants = [me.uid, otherUid]..sort();

      if (!snap.exists) {
        tx.set(ref, {
          'id': chatId,
          'type': '1to1',
          'participants': participants,                 // <- CLAVE p/ reglas
          'ultimoMensaje': '',                          // <- usado por tu UI
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Sanea: garantiza participants y refresca updatedAt
        final data = snap.data() ?? {};
        final current = List<String>.from(data['participants'] ?? const <String>[]);
        if (current.toSet().containsAll(participants) == false) {
          tx.update(ref, {'participants': participants});
        }
        tx.update(ref, {'updatedAt': FieldValue.serverTimestamp()});
      }
    });

    return chatId;
  }

  /// Envía un texto alineado con tu `ChatScreen`:
  /// subcolección `mensajes` con campos: de, type, text, timestamp, isSeen
  /// y actualiza `chats/{id}`: ultimoMensaje, updatedAt
// lib/services/chat_service.dart

static Future<void> sendText({
  required String chatId,
  required String text,
}) async {
  final me = FirebaseAuth.instance.currentUser;
  if (me == null) throw StateError('No hay sesión de usuario.');
  final trimmed = text.trim();
  if (trimmed.isEmpty) return;

  final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
  final msgRef  = chatRef.collection('mensajes').doc();

  // ✅ Batch clásico (compatible con todas las versiones)
  final batch = FirebaseFirestore.instance.batch();

  batch.set(msgRef, {
    'id'       : msgRef.id,
    'de'       : me.uid,                          // tu modelo usa 'de'
    'type'     : 'text',
    'text'     : trimmed,
    'timestamp': FieldValue.serverTimestamp(),
    'isSeen'   : false,
  });

  batch.set(chatRef, {
    'ultimoMensaje': trimmed,                     // tu UI lee 'ultimoMensaje'
    'updatedAt'    : FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  await batch.commit();
}
    
  }

