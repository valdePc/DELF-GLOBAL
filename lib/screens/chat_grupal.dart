import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

/// Modelo de mensaje para chat grupal.
class Message {
  final String id;
  final String senderName;
  final String text;
  final bool isSent;
  final DateTime timestamp;
  final String? translatedText;
  final bool isSeen;
  final String? reaction;

  Message({
    required this.id,
    required this.senderName,
    required this.text,
    required this.isSent,
    required this.timestamp,
    this.translatedText,
    this.isSeen = false,
    this.reaction,
  });

  Message copyWith({
    String? id,
    String? senderName,
    String? text,
    bool? isSent,
    DateTime? timestamp,
    String? translatedText,
    bool? isSeen,
    String? reaction,
  }) {
    return Message(
      id: id ?? this.id,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      isSent: isSent ?? this.isSent,
      timestamp: timestamp ?? this.timestamp,
      translatedText: translatedText ?? this.translatedText,
      isSeen: isSeen ?? this.isSeen,
      reaction: reaction ?? this.reaction,
    );
  }
}

class ChatGrupalScreen extends StatefulWidget {
  final String groupName;
  final String currentUser;
  final String? groupPic;

  const ChatGrupalScreen({
    Key? key,
    required this.groupName,
    required this.currentUser,
    this.groupPic,
  }) : super(key: key);

  @override
  _ChatGrupalScreenState createState() => _ChatGrupalScreenState();
}

class _ChatGrupalScreenState extends State<ChatGrupalScreen> {
  late List<Message> messages;

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool searchMode = false;
  String selectedLanguage = 'en';
  String filterQuery = '';

  String? chatBackgroundPath;

  @override
  void initState() {
    super.initState();
    messages = [
      Message(
        id: '1',
        senderName: 'Alice',
        text: '¡Hola a todos!',
        isSent: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        isSeen: true,
      ),
      Message(
        id: '2',
        senderName: widget.currentUser,
        text: '¡Hola Alice, cómo estás?',
        isSent: true,
        timestamp: DateTime.now().subtract(const Duration(minutes: 14)),
        isSeen: true,
      ),
      Message(
        id: '3',
        senderName: 'Bob',
        text: 'Yo también me uno, ¿qué cuentan?',
        isSent: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 13)),
      ),
    ];
    _messageController.addListener(() => setState(() {}));
    _translateReceivedMessages();
  }

  @override
  void dispose() {
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
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final newMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: widget.currentUser,
      text: _messageController.text.trim(),
      isSent: true,
      timestamp: DateTime.now(),
    );
    setState(() {
      messages.add(newMsg);
    });
    _messageController.clear();
  }

  /// Envía un mensaje de audio (simulado).
  Future<void> _sendAudioMessage() async {
    await Future.delayed(const Duration(seconds: 1));
    final audioMsg = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderName: widget.currentUser,
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
    final picker = ImagePicker();
    if (type == 'Foto') {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final attachmentMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: widget.currentUser,
          text: 'Foto adjunta: ${pickedFile.path.split('/').last}',
          isSent: true,
          timestamp: DateTime.now(),
        );
        setState(() {
          messages.add(attachmentMsg);
        });
      }
    } else if (type == 'Video') {
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      if (pickedFile != null) {
        final attachmentMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: widget.currentUser,
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
        senderName: widget.currentUser,
        text: 'Documento adjunto (simulado)',
        isSent: true,
        timestamp: DateTime.now(),
      );
      setState(() {
        messages.add(docMsg);
      });
    }
  }

  /// Envía imagen o video desde la cámara (simulado).
  Future<void> _sendCameraMedia(String mode) async {
    final picker = ImagePicker();
    if (mode == 'Foto') {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      if (pickedFile != null) {
        final cameraMsg = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          senderName: widget.currentUser,
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
          senderName: widget.currentUser,
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

  /// Permite editar un mensaje (si han pasado menos de 15 minutos).
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

  /// Al presionar un mensaje enviado se traduce al idioma seleccionado.
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

  /// Traduce automáticamente los mensajes recibidos de otros usuarios.
  void _translateReceivedMessages() async {
    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      if (!msg.isSent && msg.translatedText == null) {
        final translation = await translateText(msg.text, selectedLanguage);
        setState(() {
          messages[i] = msg.copyWith(translatedText: translation);
        });
      }
    }
  }

  /// Muestra las opciones de reacción al hacer doble toque sobre un mensaje.
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

  bool isSameDate(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  List<Message> get filteredMessages {
    if (filterQuery.isNotEmpty) {
      return messages
          .where((m) => m.text.toLowerCase().contains(filterQuery.toLowerCase()))
          .toList();
    }
    return messages;
  }

  Widget _buildMessageItem(int index) {
    final msg = filteredMessages[index];

    bool showDateHeader = false;
    if (index == 0) {
      showDateHeader = true;
    } else {
      final prevMsg = filteredMessages[index - 1];
      if (!isSameDate(prevMsg.timestamp, msg.timestamp)) {
        showDateHeader = true;
      }
    }

    bool showSenderName = false;
    if (!msg.isSent) {
      if (index == 0) {
        showSenderName = true;
      } else if (filteredMessages[index - 1].senderName != msg.senderName) {
        showSenderName = true;
      }
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
        if (showSenderName)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, bottom: 4),
            child: Text(
              msg.senderName,
              style: const TextStyle(fontWeight: FontWeight.bold),
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
              if (!msg.isSent)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: CircleAvatar(
                    radius: 14,
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
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
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
                  if (widget.groupPic != null)
                    CircleAvatar(
                      backgroundImage: NetworkImage(widget.groupPic!),
                    )
                  else
                    const CircleAvatar(child: Icon(Icons.group)),
                  const SizedBox(width: 10),
                  Text(widget.groupName),
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
                const SnackBar(content: Text('Llamada grupal iniciada')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Videollamada grupal iniciada')),
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
            Container(color: Colors.grey[200]),
          Column(
            children: [
              // Barra superior adicional para idioma y menú
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
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (v) {
                        if (v == 'bg') _changeChatBackground();
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'bg', child: Text('Cambiar fondo')),
                      ],
                    ),
                  ],
                ),
              ),

              // Lista de mensajes
              Expanded(
                child: ListView.builder(
                  itemCount: filteredMessages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageItem(index);
                  },
                ),
              ),

              // Barra inferior: campo de texto y botones
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context, 'Foto'),
                                    child: const Column(
                                      children: [
                                        Icon(Icons.photo_camera, size: 30),
                                        Text('Foto'),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context, 'Video'),
                                    child: const Column(
                                      children: [
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, 'Foto');
                                              },
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.photo, size: 30),
                                                  Text('Foto'),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, 'Video');
                                              },
                                              child: const Column(
                                                children: [
                                                  Icon(Icons.videocam, size: 30),
                                                  Text('Video'),
                                                ],
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.pop(context, 'Documento');
                                              },
                                              child: const Column(
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
