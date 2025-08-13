import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Modelo de mensaje:
/// - [isSeen]: indica si el mensaje fue visto.
/// - [reaction]: reacción tipo emoji (por ejemplo: '❤️', '👍', etc.).
class Message {
  final String id;
  final String text;
  final bool isSent;
  final DateTime timestamp;
  final String? translatedText;
  final bool isSeen;
  final String? reaction;

  Message({
    required this.id,
    required this.text,
    required this.isSent,
    required this.timestamp,
    this.translatedText,
    this.isSeen = false,
    this.reaction,
  });

  Message copyWith({
    String? id,
    String? text,
    bool? isSent,
    DateTime? timestamp,
    String? translatedText,
    bool? isSeen,
    String? reaction,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      isSent: isSent ?? this.isSent,
      timestamp: timestamp ?? this.timestamp,
      translatedText: translatedText ?? this.translatedText,
      isSeen: isSeen ?? this.isSeen,
      reaction: reaction ?? this.reaction,
    );
  }

  factory Message.fromMap(String id, Map<String, dynamic> map) {
    return Message(
      id: id,
      text: map['text'] ?? '',
      isSent: map['de'] == FirebaseAuth.instance.currentUser?.uid,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      translatedText: map['translatedText'],
      isSeen: map['isSeen'] ?? false,
      reaction: map['reaction'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'de': FirebaseAuth.instance.currentUser?.uid,
      'timestamp': timestamp,
      'translatedText': translatedText,
      'isSeen': isSeen,
      'reaction': reaction,
    };
  }
}


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
  /// Lista simulada inicial de mensajes con el nombre del contacto incluido.
  late List<Message> messages;

  /// Controladores y estados:
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  /// Modo de búsqueda activo/inactivo.
  bool searchMode = false;

  /// Idioma seleccionado para traducción.
  String selectedLanguage = 'en';

  /// Término de búsqueda actual.
  String filterQuery = '';

  /// Ruta de la imagen de fondo del chat (seleccionada por el usuario).
  String? chatBackgroundPath;

  /// Para saber cuál es el último mensaje del contacto (isSent = false).
  /// Solo en ese último mensaje (del contacto) se mostrará el avatar.
  int get lastContactMessageIndex {
    return filteredMessages.lastIndexWhere((m) => m.isSent == false);
  }




late StreamSubscription<QuerySnapshot> _mensajesSub;

@override
void initState() {
  super.initState();

  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    // Redirige al login o lanza un error si es necesario
    print("Usuario no autenticado.");
    return;
  }

  messages = [];
  _messageController.addListener(() => setState(() {}));
  _listenToMessages();
}

void _listenToMessages() {
  final mensajesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .collection('mensajes')
      .orderBy('timestamp');

  _mensajesSub = mensajesRef.snapshots().listen((snapshot) {
    final nuevos = snapshot.docs
       .map((doc) => Message.fromMap(doc.id, doc.data()))
        .toList();

    setState(() {
      messages = nuevos;
    });

    _translateReceivedMessages(); // Traduce si aún no estaban traducidos
  });
}

@override
void dispose() {
  _mensajesSub.cancel();
  _messageController.dispose();
  _searchController.dispose();
  super.dispose();
}



  /// Función simulada de traducción.
  Future<String> translateText(String text, String targetLang) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return '[$targetLang] $text';
  }

  /// Envía un mensaje de texto.
void _sendMessage() async {
  if (_messageController.text.trim().isEmpty) return;

  final newMsg = Message(
    id: '', // Lo generará Firestore
    text: _messageController.text.trim(),
    isSent: true,
    timestamp: DateTime.now(),
  );

  _messageController.clear();

  final mensajesRef = FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .collection('mensajes');

  await mensajesRef.add(newMsg.toMap());

  // Actualizar el chat principal
  await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
    'ultimoMensaje': newMsg.text,
    'timestamp': FieldValue.serverTimestamp(),
  });
}


  /// Graba y envía un mensaje de audio (ejemplo básico).
  Future<void> _sendAudioMessage() async {
    await Future.delayed(const Duration(seconds: 1));
    final audioMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: 'Audio enviado (simulado)',
      isSent: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      messages.add(audioMsg);
    });
  }

  /// Adjunta un archivo: foto, video o documento.
  Future<void> _sendAttachment(String type) async {
    if (type == 'Foto') {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final attachmentMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Foto adjunta: ${pickedFile.path.split('/').last}',
          isSent: true,
          timestamp: DateTime.now(),
        );
        setState(() {
          messages.add(attachmentMsg);
        });
      }
    } else if (type == 'Video') {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        final attachmentMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Video adjunto: ${pickedFile.path.split('/').last}',
          isSent: true,
          timestamp: DateTime.now(),
        );
        setState(() {
          messages.add(attachmentMsg);
        });
      }
    } else if (type == 'Documento') {
      final docMsg = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: 'Documento adjunto (simulado)',
        isSent: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        messages.add(docMsg);
      });
    }
  }

  /// Envía imagen/video desde la cámara (simulado).
  Future<void> _sendCameraMedia(String mode) async {
    final picker = ImagePicker();
    if (mode == 'Foto') {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final cameraMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Foto con cámara: ${pickedFile.path.split('/').last}',
          isSent: true,
          timestamp: DateTime.now(),
        );
        setState(() {
          messages.add(cameraMsg);
        });
      }
    } else if (mode == 'Video') {
      final pickedFile = await picker.pickVideo(source: ImageSource.camera);
      if (pickedFile != null) {
        final cameraMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: 'Video con cámara: ${pickedFile.path.split('/').last}',
          isSent: true,
          timestamp: DateTime.now(),
        );
        setState(() {
          messages.add(cameraMsg);
        });
      }
    }
  }

  /// Editar mensaje (si han pasado menos de 15 minutos).
  void _editMessage(Message message) async {
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar mensaje'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nuevo mensaje'),
            onChanged: (value) => editedText = value,
            controller: TextEditingController(text: message.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final index = messages.indexOf(message);
                setState(() {
                  messages[index] = message.copyWith(text: editedText);
                });
                Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  /// Al presionar un mensaje enviado, se traduce al idioma seleccionado.
  void _onMessagePressed(Message message) async {
    if (message.isSent) {
      final translation = await translateText(message.text, selectedLanguage);
      final index = messages.indexOf(message);
      if (index != -1) {
        setState(() {
          messages[index] = message.copyWith(translatedText: translation);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Traducción: $translation')),
      );
    }
  }

  /// Traduce automáticamente los mensajes recibidos.
 void _translateReceivedMessages() async {
  bool hasChanges = false;

  for (int i = 0; i < messages.length; i++) {
    final msg = messages[i];
    if (!msg.isSent && msg.translatedText == null) {
      final translation = await translateText(msg.text, selectedLanguage);
      messages[i] = msg.copyWith(translatedText: translation);
      hasChanges = true;
    }
  }

  if (hasChanges) {
    setState(() {});
  }
}

  /// Muestra las reacciones al hacer doble toque en el mensaje.
  void _showReactionOptions(Message message) async {
    List<String> reactions = ['👍', '❤️', '😂', '😮', '😢', '👏'];
    final selectedReaction = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: reactions.map((reaction) {
              return GestureDetector(
                onTap: () => Navigator.pop(context, reaction),
                child: Text(
                  reaction,
                  style: const TextStyle(fontSize: 24),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
    if (selectedReaction != null) {
      final index = messages.indexOf(message);
      if (index != -1) {
        setState(() {
          messages[index] = message.copyWith(reaction: selectedReaction);
        });
      }
    }
  }

  /// Cambia el fondo del chat seleccionando una imagen de la galería.
  Future<void> _changeChatBackground() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        chatBackgroundPath = pickedFile.path;
      });
    }
  }

  /// Determina si dos fechas corresponden al mismo día.
  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Obtiene la lista de mensajes filtrados por texto (búsqueda).
  List<Message> get filteredMessages {
    if (filterQuery.isNotEmpty) {
      return messages
          .where((m) => m.text.toLowerCase().contains(filterQuery.toLowerCase()))
          .toList();
    }
    return messages;
  }

  /// Construye cada ítem de la lista de mensajes, con separadores de fecha y avatar.
  Widget _buildMessageItem(int index) {
    final msg = filteredMessages[index];

    // Determinar si mostramos el separador de fecha.
    bool showDateHeader = false;
    if (index == 0) {
      showDateHeader = true;
    } else {
      final prevMsg = filteredMessages[index - 1];
      if (!isSameDate(prevMsg.timestamp, msg.timestamp)) {
        showDateHeader = true;
      }
    }

    // Solo en el último mensaje del contacto (isSent=false) mostramos el avatar.
    bool showAvatar = false;
    if (!msg.isSent && index == lastContactMessageIndex) {
      showAvatar = true;
    }

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
          onLongPress: msg.isSent ? () => _editMessage(msg) : null,
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
                    backgroundImage: const AssetImage('assets/profile_small.png'),
                  ),
                ),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: msg.isSent ? Colors.blue[100] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: msg.isSent
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(msg.text),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('HH:mm').format(msg.timestamp),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                      if (msg.translatedText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            msg.translatedText!,
                            style: const TextStyle(
                                fontSize: 12, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
              alignment:
                  msg.isSent ? Alignment.centerRight : Alignment.centerLeft,
              child: Text(
                msg.reaction!,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
      ],
    );
  }

  /// ÚNICO método para construir el campo de búsqueda.
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: const InputDecoration(
        hintText: 'Buscar mensajes...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        setState(() {
          filterQuery = value;
        });
      },
      onSubmitted: (value) {
        setState(() {
          filterQuery = value;
          searchMode = false;
        });
      },
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
                  if (widget.profilePic != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.profilePic!),
                    )
                  else
                    const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 10),
                  Text(widget.contactName),
                ],
              ),
        actions: [
          if (!searchMode)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  searchMode = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Llamada iniciada')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Videollamada iniciada')),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Container(
            height: 4,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.pink, Colors.orange, Colors.yellow],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Fondo de chat (imagen seleccionada) o color gris.
          if (chatBackgroundPath != null)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(chatBackgroundPath!)),
                  fit: BoxFit.cover,
                ),
              ),
            )
          else
            Container(
              color: Colors.grey[200],
            ),
          Column(
            children: [
              // Barra superior adicional con idioma y configuración.
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Spacer(),
                    DropdownButton<String>(
                      value: selectedLanguage,
                      items: <Map<String, String>>[
                        {'lang': 'en', 'label': 'Inglés'},
                        {'lang': 'es', 'label': 'Español'},
                        {'lang': 'fr', 'label': 'Francés'},
                      ].map((Map<String, String> item) {
                        return DropdownMenuItem<String>(
                          value: item['lang'],
                          child: Text(item['label']!),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedLanguage = val!;
                          _translateReceivedMessages();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Accediendo a configuración')),
                        );
                        _changeChatBackground();
                      },
                    ),
                  ],
                ),
              ),
              // Lista de mensajes.
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(index);
                  },
                ),
              ),
              // Barra inferior con campo de texto y botones.
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
                                    child: Column(
                                      children: const [
                                        Icon(Icons.photo_camera, size: 30),
                                        Text('Foto'),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context, 'Video'),
                                    child: Column(
                                      children: const [
                                        Icon(Icons.videocam, size: 30),
                                        Text('Video'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                        if (choice != null) {
                          await _sendCameraMedia(choice);
                        }
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
                        ? IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _sendMessage,
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.mic),
                                onPressed: _sendAudioMessage,
                              ),
                              IconButton(
                                icon: const Icon(Icons.attach_file),
                                onPressed: () async {
                                  final attachmentType =
                                      await showModalBottomSheet<String>(
                                    context: context,
                                    builder: (context) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        height: 100,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, 'Foto');
                                              },
                                              child: Column(
                                                children: const [
                                                  Icon(Icons.photo, size: 30),
                                                  Text('Foto'),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, 'Video');
                                              },
                                              child: Column(
                                                children: const [
                                                  Icon(Icons.videocam, size: 30),
                                                  Text('Video'),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, 'Documento');
                                              },
                                              child: Column(
                                                children: const [
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
