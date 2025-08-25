// lib/chat_screen.dart — versión pulida
// Mejoras clave:
// - Traducción al tocar cualquier mensaje de texto (no solo los enviados).
// - Autoscroll con animación suave.
// - Validación de adjuntos (MIME/tamaño) antes de subir.
// - Mini ChatRepository para aislar IO (Firestore/Storage).
// - Ticks de "visto" para mensajes enviados.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:record/record.dart' as rec;
import 'package:mime/mime.dart';

// ===================== MODELO =====================
class Message {
  final String id;
  final String type; // 'text' | 'image' | 'video' | 'audio' | 'file'
  final String text;
  final String? url;
  final String? fileName;
  final String? mimeType;
  final int? fileSize;
  final int? durationMs;
  final int? width;
  final int? height;
  final bool isSent; // true si lo envié yo
  final DateTime timestamp;
  final String? translatedText;
  final bool isSeen;
  final String? reaction;

  Message({
    required this.id,
    required this.type,
    required this.text,
    required this.isSent,
    required this.timestamp,
    this.url,
    this.fileName,
    this.mimeType,
    this.fileSize,
    this.durationMs,
    this.width,
    this.height,
    this.translatedText,
    this.isSeen = false,
    this.reaction,
  });

  Message copyWith({
    String? id,
    String? type,
    String? text,
    bool? isSent,
    DateTime? timestamp,
    String? url,
    String? fileName,
    String? mimeType,
    int? fileSize,
    int? durationMs,
    int? width,
    int? height,
    String? translatedText,
    bool? isSeen,
    String? reaction,
  }) {
    return Message(
      id: id ?? this.id,
      type: type ?? this.type,
      text: text ?? this.text,
      isSent: isSent ?? this.isSent,
      timestamp: timestamp ?? this.timestamp,
      url: url ?? this.url,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      translatedText: translatedText ?? this.translatedText,
      isSeen: isSeen ?? this.isSeen,
      reaction: reaction ?? this.reaction,
    );
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    final me = FirebaseAuth.instance.currentUser?.uid;
    final ts = map['timestamp'];
    DateTime when;
    if (ts is Timestamp) {
      when = ts.toDate();
    } else if (ts is DateTime) {
      when = ts;
    } else {
      when = DateTime.now();
    }

    return Message(
      id: id,
      type: (map['type'] as String?) ?? 'text',
      text: map['text'] ?? '',
      url: map['url'] as String?,
      fileName: map['fileName'] as String?,
      mimeType: map['mimeType'] as String?,
      fileSize: (map['fileSize'] as num?)?.toInt(),
      durationMs: (map['durationMs'] as num?)?.toInt(),
      width: (map['width'] as num?)?.toInt(),
      height: (map['height'] as num?)?.toInt(),
      isSent: map['de'] == me,
      timestamp: when,
      translatedText: map['translatedText'] as String?,
      isSeen: (map['isSeen'] as bool?) ?? false,
      reaction: map['reaction'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'text': text,
      'url': url,
      'fileName': fileName,
      'mimeType': mimeType,
      'fileSize': fileSize,
      'durationMs': durationMs,
      'width': width,
      'height': height,
      'de': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(), // siempre server time
      'translatedText': translatedText,
      'isSeen': isSeen,
      'reaction': reaction,
    };
  }
}

// ===================== REPOSITORIO =====================
class ChatRepository {
  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  ChatRepository({FirebaseFirestore? db, FirebaseStorage? storage})
      : _db = db ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  DocumentReference<Map<String, dynamic>> chatDoc(String chatId) =>
      _db.collection('chats').doc(chatId);

  Stream<QuerySnapshot<Map<String, dynamic>>> mensajesStream(String chatId) =>
      chatDoc(chatId).collection('mensajes').orderBy('timestamp').snapshots();

  Future<void> upsertChatMeta(String chatId, String ultimo) async {
    await chatDoc(chatId).set({
      'id': chatId,
      'ultimoMensaje': ultimo,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addMensaje(String chatId, Map<String, dynamic> data) async {
    await chatDoc(chatId).collection('mensajes').add(data);
  }

  Future<String> uploadBytes(String path, List<int> bytes,
      {required String contentType}) async {
    final task = _storage
        .ref(path)
        .putData(Uint8List.fromList(bytes), SettableMetadata(contentType: contentType));
    final snap = await task;
    return await snap.ref.getDownloadURL();
  }

  Future<String> uploadFile(String path, File f, {required String contentType}) async {
    final task =
        _storage.ref(path).putFile(f, SettableMetadata(contentType: contentType));
    final snap = await task;
    return await snap.ref.getDownloadURL();
  }
}

// ===================== UI (ChatScreen) =====================
class ChatScreen extends StatefulWidget {
  final String contactName;
  final String phone;
  final String? profilePic;
  final String chatId;

  const ChatScreen({
    Key? key,
    required this.contactName,
    required this.phone,
    required this.chatId,
    this.profilePic,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Estado
  List<Message> messages = [];

  // UI
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final _listCtrl = ScrollController();

  bool searchMode = false;
  String selectedLanguage = 'en';
  String filterQuery = '';
  String? chatBackgroundPath;

  // Audio
  late final rec.AudioRecorder _recorder;
  bool _isRecording = false;

  // Repo
  late final ChatRepository _repo;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _mensajesSub;

  // Límites adjuntos
  static const int _mb = 1024 * 1024;
  static const int _maxImage = 10 * _mb;
  static const int _maxVideo = 50 * _mb;
  static const int _maxAudio = 20 * _mb;
  static const int _maxFile = 25 * _mb;

  @override
  void initState() {
    super.initState();
    _repo = ChatRepository();
    _recorder = rec.AudioRecorder();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      debugPrint('Usuario no autenticado.');
      return;
    }

    _messageController.addListener(() => setState(() {}));
    _listenToMessages();
  }

  @override
  void dispose() {
    _mensajesSub?.cancel();
    _messageController.dispose();
    _searchController.dispose();
    _listCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _startRecordingCompat(rec.RecordConfig cfg) async {
    try {
      await (_recorder as dynamic).start(config: cfg);
    } catch (_) {
      await (_recorder as dynamic).start(cfg);
    }
  }

  Future<void> _changeChatBackground() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => chatBackgroundPath = pickedFile.path);
    }
  }

  Future<void> _markIncomingAsSeen(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final batch = FirebaseFirestore.instance.batch();
    int toUpdate = 0;

    for (final d in docs) {
      final data = d.data();
      final fromOther = data['de'] != uid;
      final isSeen = (data['isSeen'] as bool?) ?? false;
      if (fromOther && !isSeen) {
        batch.update(d.reference, {'isSeen': true});
        toUpdate++;
      }
    }
    if (toUpdate > 0) await batch.commit();
  }

  Widget _buildBackground() {
    if (chatBackgroundPath == null) return Container(color: Colors.grey[200]);
    if (kIsWeb) return Container(color: Colors.grey[200]);
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: FileImage(File(chatBackgroundPath!)),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  void _listenToMessages() {
    _mensajesSub = _repo.mensajesStream(widget.chatId).listen((snapshot) async {
      final nuevos =
          snapshot.docs.map((d) => Message.fromMap(d.id, d.data())).toList();
      setState(() => messages = nuevos);

      // autoscroll suave
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (_listCtrl.hasClients) {
          await _listCtrl.animateTo(
            _listCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
      });

      await _markIncomingAsSeen(snapshot.docs);
      _translateReceivedMessages();
    });
  }

  // ===================== ENVÍO =====================
  Future<void> _sendMessage() async {
    final txt = _messageController.text.trim();
    if (txt.isEmpty) return;
    _messageController.clear();

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _repo.upsertChatMeta(widget.chatId, txt);
      await _repo.addMensaje(widget.chatId, {
        'type': 'text',
        'text': txt,
        'de': uid,
        'timestamp': FieldValue.serverTimestamp(),
        'isSeen': false,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo enviar: $e')));
    }
  }

// ignore: unused_element  IGNORADO PARA LUEGO XXX
Future<void> _sendSystemText(String text) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _repo.upsertChatMeta(widget.chatId, text);
    await _repo.addMensaje(widget.chatId, {
      'type': 'text',
      'text': text,
      'de': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });
  }

  // ===================== VALIDACIONES =====================
  bool _checkLimitAndMime({
    required String type,
    required String fileName,
    required int size,
    required String mime,
  }) {
    bool ok = true;
    String? error;

    if (type == 'image') {
      if (!mime.startsWith('image/')) error = 'Formato de imagen no válido';
      if (size > _maxImage) error = 'Imagen supera ${_maxImage ~/ _mb}MB';
    } else if (type == 'video') {
      if (!mime.startsWith('video/')) error = 'Formato de video no válido';
      if (size > _maxVideo) error = 'Video supera ${_maxVideo ~/ _mb}MB';
    } else if (type == 'audio') {
      if (!mime.startsWith('audio/')) error = 'Formato de audio no válido';
      if (size > _maxAudio) error = 'Audio supera ${_maxAudio ~/ _mb}MB';
    } else {
      if (size > _maxFile) error = 'Archivo supera ${_maxFile ~/ _mb}MB';
    }

    if (error != null) {
      ok = false;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
    return ok;
  }

  // ===================== STORAGE + MENSAJES =====================
  Future<void> _uploadAndSendXFile(XFile xf, String type) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName = xf.name;
    final mime = lookupMimeType(fileName) ?? 'application/octet-stream';

    UploadTask task;
    int size = 0;
    final storagePath =
        'chats/${widget.chatId}/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    if (kIsWeb) {
      final bytes = await xf.readAsBytes();
      size = bytes.length;
      if (!_checkLimitAndMime(type: type, fileName: fileName, size: size, mime: mime)) return;
      task = FirebaseStorage.instance
          .ref(storagePath)
          .putData(bytes, SettableMetadata(contentType: mime));
    } else {
      final f = File(xf.path);
      size = await f.length();
      if (!_checkLimitAndMime(type: type, fileName: fileName, size: size, mime: mime)) return;
      task = FirebaseStorage.instance
          .ref(storagePath)
          .putFile(f, SettableMetadata(contentType: mime));
    }

    final snap = await task;
    final url = await snap.ref.getDownloadURL();

    final ultimo = (type == 'image')
        ? '📷 Imagen'
        : (type == 'video')
            ? '🎬 Video'
            : (type == 'audio')
                ? '🎙️ Audio'
                : '📎 Archivo';

    await _repo.upsertChatMeta(widget.chatId, ultimo);
    await _repo.addMensaje(widget.chatId, {
      'type': type,
      'text': '',
      'url': url,
      'fileName': fileName,
      'mimeType': mime,
      'fileSize': size,
      'de': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });
  }

  Future<void> _uploadAndSendPlatformFile(PlatformFile pf, String type) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fileName = pf.name;

    String mime = lookupMimeType(fileName) ?? 'application/octet-stream';
    int size = pf.size;

    final storagePath =
        'chats/${widget.chatId}/$uid/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    if (!_checkLimitAndMime(type: type, fileName: fileName, size: size, mime: mime)) return;

    UploadTask task;
    if (kIsWeb || pf.bytes != null) {
      final bytes = pf.bytes!;
      task = FirebaseStorage.instance
          .ref(storagePath)
          .putData(bytes, SettableMetadata(contentType: mime));
    } else {
      final f = File(pf.path!);
      task = FirebaseStorage.instance
          .ref(storagePath)
          .putFile(f, SettableMetadata(contentType: mime));
    }

    final snap = await task;
    final url = await snap.ref.getDownloadURL();

    final ultimo = (type == 'image')
        ? '📷 Imagen'
        : (type == 'video')
            ? '🎬 Video'
            : (type == 'audio')
                ? '🎙️ Audio'
                : '📎 Archivo';

    await _repo.upsertChatMeta(widget.chatId, ultimo);
    await _repo.addMensaje(widget.chatId, {
      'type': type,
      'text': '',
      'url': url,
      'fileName': fileName,
      'mimeType': mime,
      'fileSize': size,
      'de': uid,
      'timestamp': FieldValue.serverTimestamp(),
      'isSeen': false,
    });
  }

  // Adjuntar
  Future<void> _sendAttachment(String type) async {
    if (type == 'Foto') {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) await _uploadAndSendXFile(picked, 'image');
    } else if (type == 'Video') {
      final picker = ImagePicker();
      final picked = await picker.pickVideo(source: ImageSource.gallery);
      if (picked != null) await _uploadAndSendXFile(picked, 'video');
    } else if (type == 'Documento') {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: kIsWeb,
        type: FileType.any,
      );
      if (res != null && res.files.isNotEmpty) {
        await _uploadAndSendPlatformFile(res.files.single, 'file');
      }
    }
  }

  // Cámara directa
  Future<void> _sendCameraMedia(String mode) async {
    final picker = ImagePicker();
    if (mode == 'Foto') {
      final f = await picker.pickImage(source: ImageSource.camera);
      if (f != null) await _uploadAndSendXFile(f, 'image');
    } else {
      final f = await picker.pickVideo(source: ImageSource.camera);
      if (f != null) await _uploadAndSendXFile(f, 'video');
    }
  }

  // Audio
  Future<void> _sendAudioMessage() async {
    if (kIsWeb) {
      final res = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        withData: true,
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'aac', 'wav', 'ogg'],
      );
      if (res != null && res.files.isNotEmpty) {
        await _uploadAndSendPlatformFile(res.files.single, 'audio');
      }
      return;
    }

    final ok = await _recorder.hasPermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono denegado')),
      );
      return;
    }

    if (!_isRecording) {
      await _startRecordingCompat(
        rec.RecordConfig(
          encoder: rec.AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
      );
      setState(() => _isRecording = true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grabando... toca el mic para detener')),
      );
    } else {
      final path = await _recorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await _uploadAndSendXFile(XFile(path), 'audio');
      }
    }
  }

  // ===================== EDICIÓN / REACCIONES =====================
  Future<void> _updateMessageText(Message message, String newText) async {
    if (message.id.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('mensajes')
        .doc(message.id)
        .update({'text': newText});
  }

  void _editMessage(Message message) async {
    if (message.type != 'text') return;
    final now = DateTime.now();
    if (now.difference(message.timestamp).inMinutes > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El mensaje ya no se puede editar.')),
      );
      return;
    }

    String editedText = message.text;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar mensaje'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nuevo mensaje'),
          onChanged: (v) => editedText = v,
          controller: TextEditingController(text: message.text),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await _updateMessageText(message, editedText);
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _setReaction(Message message, String emoji) async {
    if (message.id.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('mensajes')
        .doc(message.id)
        .update({'reaction': emoji});
  }

  void _showReactionOptions(Message message) async {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '👏'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SizedBox(
        height: 80,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: reactions
              .map((r) => GestureDetector(
                    onTap: () => Navigator.pop(context, r),
                    child: Text(r, style: const TextStyle(fontSize: 24)),
                  ))
              .toList(),
        ),
      ),
    );
    if (selected != null) await _setReaction(message, selected);
  }

  // ===================== TRADUCCIÓN =====================
  Future<String?> translateText(String text, String targetLang) async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('translateText');
      final res = await callable.call({'text': text, 'target': targetLang});
      final data = res.data as Map;
      return data['translation'] as String?;
    } catch (_) {
      return null;
    }
  }

  void _onMessagePressed(Message message) async {
    // FIX: permitir traducir cualquier mensaje de texto (entrante o saliente)
    if (message.type != 'text') return;

    final translation = await translateText(message.text, selectedLanguage);
    if (translation == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Traducción no disponible')));
      return;
    }

    final index = messages.indexOf(message);
    if (index != -1) {
      setState(() {
        messages[index] = message.copyWith(translatedText: translation);
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Traducción: $translation')));
  }

  void _translateReceivedMessages() async {
    bool hasChanges = false;
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (!msg.isSent && msg.type == 'text' && msg.translatedText == null) {
        final translation = await translateText(msg.text, selectedLanguage);
        if (translation != null) {
          messages[i] = msg.copyWith(translatedText: translation);
          hasChanges = true;
        }
      }
    }
    if (hasChanges) setState(() {});
  }

  // ===================== HELPERS UI =====================
  bool isSameDate(DateTime d1, DateTime d2) =>
      d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  List<Message> get filteredMessages {
    if (filterQuery.isNotEmpty) {
      return messages
          .where((m) => (m.text).toLowerCase().contains(filterQuery.toLowerCase()) ||
              (m.fileName ?? '').toLowerCase().contains(filterQuery.toLowerCase()) ||
              m.type.toLowerCase().contains(filterQuery.toLowerCase()))
          .toList();
    }
    return messages;
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _ticks(bool seen) => Icon(
        seen ? Icons.done_all : Icons.done,
        size: 14,
        color: seen ? Colors.blue : Colors.grey,
      );

  Widget _messageBubble(Message msg) {
    Widget inner;

    if (msg.type == 'image' && msg.url != null) {
      inner = Column(
        crossAxisAlignment:
            msg.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(msg.url!, fit: BoxFit.cover),
          ),
          if ((msg.fileName ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(msg.fileName!, style: const TextStyle(fontSize: 12)),
          ],
        ],
      );
    } else if ((msg.type == 'video' || msg.type == 'audio' || msg.type == 'file') &&
        msg.url != null) {
      final icon = msg.type == 'video'
          ? Icons.videocam
          : (msg.type == 'audio' ? Icons.audiotrack : Icons.insert_drive_file);
      inner = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              msg.fileName ?? (msg.type.toUpperCase()),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(onPressed: () => _openUrl(msg.url!), child: const Text('Abrir')),
        ],
      );
    } else {
      inner = Column(
        crossAxisAlignment:
            msg.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(msg.text),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('HH:mm').format(msg.timestamp),
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              if (msg.isSent) ...[
                const SizedBox(width: 6),
                _ticks(msg.isSeen),
              ]
            ],
          ),
          if (msg.translatedText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                msg.translatedText!,
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: msg.isSent ? Colors.blue[100] : Colors.grey[300],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: inner,
    );
  }

  int get lastContactMessageIndex {
    return filteredMessages.lastIndexWhere((m) => m.isSent == false);
  }

  Widget _buildMessageItem(int index) {
    final msg = filteredMessages[index];

    bool showDateHeader = false;
    if (index == 0) {
      showDateHeader = true;
    } else {
      final prevMsg = filteredMessages[index - 1];
      if (!isSameDate(prevMsg.timestamp, msg.timestamp)) showDateHeader = true;
    }

    bool showAvatar = (!msg.isSent && index == lastContactMessageIndex);

    return Column(
      crossAxisAlignment:
          msg.isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showDateHeader)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(msg.timestamp),
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _onMessagePressed(msg),
          onDoubleTap: () => _showReactionOptions(msg),
          onLongPress: msg.isSent && msg.type == 'text' ? () => _editMessage(msg) : null,
          child: Row(
            mainAxisAlignment:
                msg.isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showAvatar)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 12,
                    backgroundImage: (widget.profilePic != null &&
                            widget.profilePic!.isNotEmpty)
                        ? (kIsWeb || widget.profilePic!.startsWith('http')
                            ? NetworkImage(widget.profilePic!)
                            : FileImage(File(widget.profilePic!)) as ImageProvider)
                        : null,
                    child: (widget.profilePic == null || widget.profilePic!.isEmpty)
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                ),
              Flexible(child: _messageBubble(msg)),
            ],
          ),
        ),
        if (msg.reaction != null)
          Padding(
            padding: EdgeInsets.only(
              left: msg.isSent ? 0 : 32,
              right: msg.isSent ? 32 : 0,
              bottom: 8,
              top: 2,
            ),
            child: Align(
              alignment: msg.isSent ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(msg.reaction!, style: const TextStyle(fontSize: 20)),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Buscar mensajes...',
        border: InputBorder.none,
      ),
      onChanged: (value) => setState(() => filterQuery = value),
      onSubmitted: (value) => setState(() {
        filterQuery = value;
        searchMode = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _messageController.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: searchMode
            ? _buildSearchField()
            : Row(
                children: [
                  CircleAvatar(
                    backgroundImage: (widget.profilePic != null && widget.profilePic!.isNotEmpty)
                        ? (kIsWeb || widget.profilePic!.startsWith('http')
                            ? NetworkImage(widget.profilePic!)
                            : FileImage(File(widget.profilePic!)) as ImageProvider)
                        : null,
                    child: (widget.profilePic == null || widget.profilePic!.isEmpty)
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      widget.contactName,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
        actions: [
          if (!searchMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => searchMode = true),
            ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () => ScaffoldMessenger.of(context)
                .showSnackBar(const SnackBar(content: Text('Llamada iniciada'))),
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Videollamada iniciada'))),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(4),
          child: SizedBox(
            height: 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Colors.pink, Colors.orange, Colors.yellow]),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildBackground(),
          Column(
            children: [
              // Barra superior extra
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Spacer(),
                    DropdownButton<String>(
                      value: selectedLanguage,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('Inglés')),
                        DropdownMenuItem(value: 'es', child: Text('Español')),
                        DropdownMenuItem(value: 'fr', child: Text('Francés')),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedLanguage = val!;
                          _translateReceivedMessages();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () => _changeChatBackground(),
                    ),
                  ],
                ),
              ),
              // Lista de mensajes
              Expanded(
                child: ListView.builder(
                  controller: _listCtrl,
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) => _buildMessageItem(index),
                ),
              ),
              // Input
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () async {
                        final choice = await showModalBottomSheet<String>(
                          context: context,
                          builder: (context) {
                            return Container(
                              padding: const EdgeInsets.all(16),
                              height: 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context, 'Foto'),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [Icon(Icons.photo_camera, size: 30), Text('Foto')],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context, 'Video'),
                                    child: const Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [Icon(Icons.videocam, size: 30), Text('Video')],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (choice != null) await _sendCameraMedia(choice);
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    hasText
                        ? IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage)
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.mic, color: _isRecording ? Colors.red : null),
                                onPressed: _sendAudioMessage,
                                tooltip: _isRecording ? 'Detener grabación' : 'Grabar audio',
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () async {
                                  final attachmentType = await showModalBottomSheet<String>(
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        height: 100,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              onTap: () => Navigator.pop(context, 'Foto'),
                                              child: const Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [Icon(Icons.photo, size: 30), Text('Foto')],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.pop(context, 'Video'),
                                              child: const Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [Icon(Icons.videocam, size: 30), Text('Video')],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () => Navigator.pop(context, 'Documento'),
                                              child: const Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.insert_drive_file, size: 30),
                                                  Text('Doc'),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                  if (attachmentType != null) {
                                    await _sendAttachment(attachmentType);
                                  }
                                },
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
