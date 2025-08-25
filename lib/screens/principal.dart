// lib/screens/principal.dart — FIX
// Objetivos:
// 1) El chat aparece aunque el otro usuario no te haya agregado (al crear el 1a1 ya se lista).
// 2) Al salir del chat, ves la lista actualizada (stream en tiempo real desde Firestore).
// 3) Sincroniza la lista de chats con Firestore (no dependemos de SharedPreferences para los chats).

import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'status_viewer.dart';
import 'chat_screen.dart';
import 'reels.dart';
import 'telefono.dart';
import 'grupos.dart';
import 'configuracion_screen.dart';
import 'add_contact.dart';

import 'package:delf_global/services/user_directory.dart';
import 'package:delf_global/services/chat_service.dart';
import 'package:delf_global/app_config.dart';

String buildInviteUrl(String refUid) => '$APP_INVITE_URL?ref=$refUid';

/// Modelo de contactos (libreta local)
class Contact {
  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String avatarUrl;

  Contact({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.avatarUrl = '',
  });

  factory Contact.fromMap(Map<String, dynamic> map) => Contact(
        id: map['id'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        avatarUrl: map['avatarUrl'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
      };
}

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({Key? key}) : super(key: key);
  @override
  _PrincipalScreenState createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  // Estados tipo Instagram (local persist)
  List<Map<String, dynamic>> statuses = [];
  // Libreta local de contactos
  List<Contact> contacts = [];
  // Lista de chats mostrados (derivada de Firestore)
  List<Map<String, dynamic>> chats = [];

  final Map<String, Map<String, dynamic>> _userCache = {};
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatsSub;

  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadData();
    _subscribeMyChats();
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    super.dispose();
  }

  // ===================== INVITAR / ABRIR CHAT =====================
  Future<void> _openChatOrInvite(Contact c) async {
    final phone = c.phone;
    final email = c.email;

    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión')),
      );
      return;
    }

    try {
      // Resolver UID del otro usuario
      final otherUid = await UserDirectory.resolveUidByHandle(phone: phone, email: email);

      if (otherUid == null) {
        final inviteLink = buildInviteUrl(myUid);
        await _showInviteDialog(
          context,
          nombre: c.name,
          phone: phone,
          email: email,
          inviteLink: inviteLink,
        );
        return;
      }

      // Crear/abrir chat 1a1. IMPORTANTE: esto crea/asegura chats/{chatId} con participants
      final chatId = await ChatService.getOrCreate1to1(otherUid);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            contactName: c.name,
            phone: phone ?? (email ?? ''),
            profilePic: '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showInviteDialog(
    BuildContext context, {
    required String nombre,
    String? phone,
    String? email,
    required String inviteLink,
  }) async {
    final String mensaje = '¡Hola $nombre! Te invito a unirte a Delf para chatear conmigo. Regístrate aquí: $inviteLink';

    Future<void> _inviteViaSms(String? toPhone) async {
      final uri = Uri(scheme: 'sms', path: (toPhone ?? '').trim(), queryParameters: {'body': mensaje});
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir SMS')));
        }
      }
    }

    Future<void> _inviteViaEmail(String? toEmail) async {
      final uri = Uri(scheme: 'mailto', path: (toEmail ?? '').trim(), queryParameters: {'subject': 'Únete a Delf', 'body': mensaje});
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir Email')));
        }
      }
    }

    Future<void> _copyInviteLink() async {
      await Clipboard.setData(ClipboardData(text: inviteLink));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
      }
    }

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('No está en la app'),
        content: Text('Para poder chatear, $nombre debe registrarse. ¿Copiar enlace de invitación?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
          ElevatedButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: inviteLink));
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enlace copiado')));
              }
            },
            child: const Text('Copiar enlace'),
          ),
        ],
      ),
    );

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            runSpacing: 8,
            children: [
              Center(child: Text('Invitar a $nombre', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
              const Divider(),
              if ((phone ?? '').trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.sms),
                  title: const Text('Enviar SMS'),
                  subtitle: Text(phone!),
                  onTap: () {
                    Navigator.pop(context);
                    _inviteViaSms(phone);
                  },
                ),
              if ((email ?? '').trim().isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Enviar correo'),
                  subtitle: Text(email!),
                  onTap: () {
                    Navigator.pop(context);
                    _inviteViaEmail(email);
                  },
                ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copiar enlace'),
                subtitle: Text(inviteLink, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () {
                  Navigator.pop(context);
                  _copyInviteLink();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===================== CARGA LOCAL (estados/agenda) =====================
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    final statusesString = prefs.getString('statuses');
    statuses = statusesString != null ? (json.decode(statusesString) as List).cast<Map<String, dynamic>>() : [];

    final contactsString = prefs.getString('contacts');
    final rawContacts = contactsString != null ? (json.decode(contactsString) as List).cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
    contacts = rawContacts.map((m) => Contact.fromMap(m)).toList();

    setState(() {});
  }

  // ===================== STREAM DE CHATS (Tiempo real) =====================
  void _subscribeMyChats() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _chatsSub?.cancel();
    _chatsSub = FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      final List<Map<String, dynamic>> next = [];

      for (final d in snapshot.docs) {
        final data = d.data();
        final List<dynamic> parts = (data['participants'] as List<dynamic>? ?? const []);
        if (parts.length < 2) continue;
        final String otherUid = (parts.firstWhere((x) => x != uid)) as String;

        // cache de usuario
        if (!_userCache.containsKey(otherUid)) {
          try {
            final u = await UserDirectory.getUserPublic(otherUid);
            _userCache[otherUid] = u ?? {};
          } catch (_) {
            _userCache[otherUid] = {};
          }
        }
        final u = _userCache[otherUid] ?? {};

final displayName = (u['fullName'] as String?) 
    ?? (data['nameMap']?[otherUid] as String?) 
    ?? 'Contacto';
final photoUrl = (u['photoUrl'] as String?) ?? '';
final contactHandle = (u['email'] as String?) 
    ?? (u['phoneE164'] as String?) 
    ?? '';

// Construir item para la lista
next.add({
  'chatId'      : data['id'] ?? d.id,
  'contactName' : displayName,
  'profilePic'  : photoUrl,
  'handle'      : contactHandle,     // <- nuevo
  'phone'       : u['phoneE164'],
  'email'       : u['email'],
  'lastMessage' : data['ultimoMensaje'] ?? '',
  'unreadCount' : 0,
});

      }

      if (mounted) setState(() => chats = next);
    });
  }

  // ===================== ESTADOS (UI) =====================
  Future<void> _addNewStatus() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final newStatus = {'contactId': 'me', 'contactName': 'Tú', 'imageUrl': pickedFile.path, 'viewed': false};
      statuses.insert(0, newStatus);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('statuses', json.encode(statuses));
      if (mounted) setState(() {});
    }
  }

  // ===================== LISTAS =====================
  Widget _buildChatListScreen() {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var s in statuses) {
      if (s['contactId'] != 'me') {
        grouped.putIfAbsent(s['contactId'], () => []).add(s);
      }
    }
    final statusIds = grouped.keys.toList();

    return Column(
      children: [
        // Carrusel de estados
        Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: statusIds.length + 1,
            itemBuilder: (context, idx) {
              if (idx == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: _addNewStatus,
                    child: const Column(
                      children: [
                        Stack(children: [
                          CircleAvatar(radius: 35, backgroundColor: Colors.grey, child: Icon(Icons.add_a_photo, color: Colors.white)),
                          Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 12, backgroundColor: Colors.blueAccent, child: Icon(Icons.add, size: 16, color: Colors.white)))
                        ]),
                        SizedBox(height: 6),
                        Text('Mi estado', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }

              final cid = statusIds[idx - 1];
              final myStatuses = grouped[cid] ?? const <Map<String, dynamic>>[];
              if (myStatuses.isEmpty) return const SizedBox.shrink();
              final hasUnviewed = myStatuses.any((s) => s['viewed'] == false);
              final displayStatus = myStatuses.first;

              final matches = contacts.where((c) => c.id == cid);
              final contactName = matches.isNotEmpty ? matches.first.name : 'Contacto';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () async {
                    final updated = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatusViewerScreen(
                          status: displayStatus,
                          allStatuses: myStatuses,
                          initialIndex: 0,
                        ),
                      ),
                    );
                    if (updated == true) _loadData();
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: hasUnviewed ? Colors.pinkAccent : Colors.grey, width: 3),
                        ),
                        child: ClipOval(
                          child: displayStatus['imageUrl'] != null
                              ? (displayStatus['imageUrl'].toString().startsWith('http') || kIsWeb
                                  ? Image.network(displayStatus['imageUrl'], fit: BoxFit.cover)
                                  : Image.file(File(displayStatus['imageUrl']), fit: BoxFit.cover))
                              : const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(contactName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),

       // Lista combinada: CHATS (si hay) + CONTACTOS (siempre)
Expanded(
  child: ListView(
    children: [
      if (chats.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('Chats', style: Theme.of(context).textTheme.titleMedium),
        ),
        _buildChatsListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
        ),
      ],
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text('Contactos', style: Theme.of(context).textTheme.titleMedium),
      ),
      _buildContactsListView(),
    ],
  ),
),

      ],
    );
  }

Widget _buildChatsListView({bool shrinkWrap = false, ScrollPhysics? physics}) =>
    ListView.builder(
      shrinkWrap: shrinkWrap,
      physics: physics,
        itemCount: chats.length,
        itemBuilder: (context, i) {
          final chat = chats[i];
          return Dismissible(
            key: Key(chat['chatId']?.toString() ?? i.toString()),
            background: Container(color: Colors.red, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.delete, color: Colors.white)),
            secondaryBackground: Container(color: Colors.blue, alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), child: const Icon(Icons.archive, color: Colors.white)),
            confirmDismiss: (direction) async {
              // Aquí podrías implementar borrar/archivar en Firestore si quieres
              return false; // por ahora, no borramos del servidor
            },
            child: ListTile(
              leading: (chat['profilePic'] != null && (chat['profilePic'] as String).isNotEmpty)
                  ? CircleAvatar(backgroundImage: NetworkImage(chat['profilePic']))
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(chat['contactName'] ?? 'Chat'),
              subtitle: Text(chat['lastMessage'] ?? ''),
              trailing: chat['unreadCount'] != null && chat['unreadCount'] > 0
                  ? Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                      child: Text('${chat['unreadCount']}', style: const TextStyle(color: Colors.white, fontSize: 11)),
                    )
                  : null,
              onTap: () {
                if (chat['chatId'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        contactName: chat['contactName'] ?? 'Chat',
                        phone: chat['email'] ?? chat['phone'] ?? '',
                        profilePic: chat['profilePic'],
                        chatId: chat['chatId'],
                      ),
                    ),
                  );
                }
              },
            ),
          );
        },
      );

Widget _buildContactsListView() {
  if (contacts.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        'No tienes contactos aún. Toca “+” para agregar uno.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: contacts.length,
    itemBuilder: (context, i) {
      final c = contacts[i];
      return ListTile(
        leading: c.avatarUrl.isNotEmpty
            ? (kIsWeb ? Image.network(c.avatarUrl) : Image.file(File(c.avatarUrl)))
            : const CircleAvatar(child: Icon(Icons.person)),
        title: Text(c.name),
        subtitle: Text(c.phone ?? c.email ?? ''),
        onTap: () => _openChatOrInvite(c),
      );
    },
  );
}

  // ===================== NAV =====================
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    late Widget targetScreen;
    switch (index) {
      case 0:
        targetScreen = const ReelsScreen();
        break;
      case 1:
        targetScreen = const TelefonoScreen();
        break;
      case 3:
        targetScreen = const GruposScreen();
        break;
      case 4:
        targetScreen = const ConfiguracionScreen();
        break;
      default:
        targetScreen = const PrincipalScreen();
    }
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => targetScreen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildChatListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => const AddContactScreen()));
          if (added == true) {
            // Si se agregó contacto, recarga libreta.
            _loadData();
            // La lista de chats se actualiza sola por stream si se creó un 1a1.
          }
        },
        child: const Icon(Icons.person_add),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1B2735), Color(0xFF415A77)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.video_camera_front_outlined), label: 'Reels'),
            BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Teléfono'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Grupos'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Configuración'),
          ],
        ),
      ),
    );
  }
}
