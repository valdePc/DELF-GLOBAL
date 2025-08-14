import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'status_viewer.dart';
import 'chat_screen.dart';
import 'reels.dart';
import 'telefono.dart';
import 'grupos.dart';
import 'configuracion_screen.dart';
import 'add_contact.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'registro_screen.dart';


/// Modelo simple para un contacto real
class Contact {
  final String id;
  final String name;
  final String phone;
  final String avatarUrl;

  Contact({
    required this.id,
    required this.name,
    required this.phone,
    this.avatarUrl = '',
  });

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String,
      avatarUrl: map['avatarUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'avatarUrl': avatarUrl,
    };
  }
}

class PrincipalScreen extends StatefulWidget {
  const PrincipalScreen({Key? key}) : super(key: key);
  @override
  _PrincipalScreenState createState() => _PrincipalScreenState();
}

class _PrincipalScreenState extends State<PrincipalScreen> {
  List<Map<String, dynamic>> statuses = [];
  List<Contact> contacts = [];
  List<Map<String, dynamic>> chats = [];
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Carga estados
    final statusesString = prefs.getString('statuses');
    statuses = statusesString != null
        ? (json.decode(statusesString) as List).cast<Map<String, dynamic>>()
        : [];

    // Carga contactos
    final contactsString = prefs.getString('contacts');
    final rawContacts = contactsString != null
        ? (json.decode(contactsString) as List).cast<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    contacts = rawContacts.map((m) => Contact.fromMap(m)).toList();

    // Carga chats
    final chatsString = prefs.getString('chats');
    chats = chatsString != null
        ? (json.decode(chatsString) as List).cast<Map<String, dynamic>>()
        : [];

    setState(() {});
  }

  Future<void> _saveStatuses() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('statuses', json.encode(statuses));
  }

  Future<void> _saveChats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chats', json.encode(chats));
  }

  Future<void> _addNewStatus() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final newStatus = {
        'contactId': 'me',
        'contactName': 'Tú',
        'imageUrl': pickedFile.path,
        'viewed': false,
      };
      statuses.insert(0, newStatus);
      await _saveStatuses();
      setState(() {});
    }
  }

  void _deleteChat(int index) {
    chats.removeAt(index);
    _saveChats();
    setState(() {});
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Chat eliminado')));
  }

  void _archiveChat(int index) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Chat archivado')));
  }

  Widget _buildChatListScreen() {
    // Agrupar estados solo para contactos distintos de "me"
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var s in statuses) {
      if (s['contactId'] != 'me') {
        grouped.putIfAbsent(s['contactId'], () => []).add(s);
      }
    }
    final statusIds = grouped.keys.toList();

    return Column(
      children: [
        // Carrusel de estados: "Mi estado" + contactos con estados
        Container(
          height: 110,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: statusIds.length + 1,
            itemBuilder: (context, idx) {
              if (idx == 0) {
                // Botón "Mi estado"
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: _addNewStatus,
                    child: const Column(
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.grey,
                              child:
                                  Icon(Icons.add_a_photo, color: Colors.white),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.blueAccent,
                                child:
                                    Icon(Icons.add, size: 16, color: Colors.white),
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 6),
                        Text("Mi estado", style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              }
              // Estado de cada contacto real
              final cid = statusIds[idx - 1];
              final contact = contacts.firstWhere((c) => c.id == cid);
              final myStatuses = grouped[cid]!;
              final hasUnviewed = myStatuses.any((s) => s['viewed'] == false);
              final displayStatus = myStatuses.first;

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
                          border: Border.all(
                            color: hasUnviewed ? Colors.pinkAccent : Colors.grey,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: displayStatus['imageUrl'] != null
                              ? (displayStatus['imageUrl']
                                          .toString()
                                          .startsWith('http') ||
                                      kIsWeb
                                  ? Image.network(
                                      displayStatus['imageUrl'],
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(displayStatus['imageUrl']),
                                      fit: BoxFit.cover,
                                    ))
                              : const Icon(Icons.person,
                                  size: 40, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contact.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Divider(height: 1),
        // Chats o, si no hay chats, lista de contactos
        Expanded(
          child: chats.isNotEmpty
              ? _buildChatsListView()
              : ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, i) {
                    final c = contacts[i];
                    return ListTile(
                      leading: c.avatarUrl.isNotEmpty
                          ? (kIsWeb
                              ? Image.network(c.avatarUrl)
                              : Image.file(File(c.avatarUrl)))
                          : const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(c.name),
                      subtitle: Text(c.phone),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              contactName: c.name,
                              phone: c.phone,
                              profilePic: c.avatarUrl,
                              chatId: c.id,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatsListView() => ListView.builder(
        itemCount: chats.length,
        itemBuilder: (context, i) {
          final chat = chats[i];
          return Dismissible(
            key: Key(chat['phone'] ?? i.toString()),
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            secondaryBackground: Container(
              color: Colors.blue,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Icon(Icons.archive, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                _deleteChat(i);
                return true;
              } else {
                _archiveChat(i);
                return false;
              }
            },
            child: ListTile(
              leading: chat['profilePic'] != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(chat['profilePic']),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),
              title: Text(chat['contactName'] ?? chat['phone']),
              subtitle: Text(chat['lastMessage'] ?? ''),
              trailing: chat['unreadCount'] != null && chat['unreadCount'] > 0
                  ? Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${chat['unreadCount']}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    )
                  : null,
              onTap: () {
                if (chat['chatId'] != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        contactName: chat['contactName'] ?? chat['phone'],
                        phone: chat['phone'],
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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildChatListScreen(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddContactScreen()),
          );
          if (added == true) _loadData();
        },
        child: const Icon(Icons.person_add),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1B2735), Color(0xFF415A77)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
            BottomNavigationBarItem(
                icon: Icon(Icons.video_camera_front_outlined),
                label: 'Reels'),
            BottomNavigationBarItem(icon: Icon(Icons.phone), label: 'Teléfono'),
            BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Grupos'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings), label: 'Configuración'),
          ],
        ),
      ),
    );
  }
}
