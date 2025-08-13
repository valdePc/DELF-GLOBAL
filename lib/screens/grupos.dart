import 'package:flutter/material.dart';
import 'package:delf_global/screens/chat_grupal.dart';
import 'package:delf_global/screens/reels.dart';
import 'package:delf_global/screens/telefono.dart';
import 'package:delf_global/screens/principal.dart';
import 'package:delf_global/screens/configuracion_screen.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  _GruposScreenState createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  // Datos de ejemplo para el usuario.
  final String userName = "Usuario Actual";
  final String userProfileUrl = "https://via.placeholder.com/150";

  // Lista de grupos (ejemplo) que en producción se filtrará según el fx del usuario.
  List<Map<String, dynamic>> groups = [
    {
      'name': 'Amigos Cercanos',
      'lastMessage': 'Nos vemos en la cena.',
      'lastMessageTime': '10:30 AM',
      'unreadCount': 2,
      'participants': 5,
      'isNew': true,
    },
    {
      'name': 'Equipo de Trabajo',
      'lastMessage': 'Reunión a las 3 PM',
      'lastMessageTime': '09:15 AM',
      'unreadCount': 0,
      'participants': 8,
      'isNew': false,
    },
  ];

  // En la navegación global, Grupos es el índice 3.
  int _selectedIndex = 3;

  // Función para manejar la navegación de la barra inferior.
  void _onNavBarTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ReelsScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TelefonoScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
       MaterialPageRoute(builder: (_) => PrincipalScreen()),

      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const GruposScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ConfiguracionScreen()),
      );
    }
  }

  // Función para abrir el modal de creación de grupo.
  void _createGroup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        // Para que se adapte a la altura del teclado.
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: _buildCreateGroupSheet(),
      ),
    );
  }

  // Widget que simula la creación de un grupo.
  Widget _buildCreateGroupSheet() {
    // Datos de ejemplo para contactos.
    List<Map<String, dynamic>> contacts = [
      {'name': 'Contacto 1', 'selected': false},
      {'name': 'Contacto 2', 'selected': false},
      {'name': 'Contacto 3', 'selected': false},
    ];

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setModalState) {
        return SizedBox(
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crear Grupo',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text(contacts[index]['name']),
                      value: contacts[index]['selected'],
                      onChanged: (bool? value) {
                        setModalState(() {
                          contacts[index]['selected'] = value ?? false;
                        });
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  int participantes =
                      contacts.where((c) => c['selected']).length;
                  if (participantes > 0) {
                    setState(() {
                      groups.add({
                        'name': 'Nuevo Grupo',
                        'lastMessage': '',
                        'lastMessageTime': '',
                        'unreadCount': 0,
                        'participants': participantes,
                        'isNew': true,
                      });
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Crear Grupo'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // Widget que construye cada elemento de la lista de grupos.
  Widget _buildGroupItem(Map<String, dynamic> group) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(group['name'][0]),
      ),
      title: Row(
        children: [
          Expanded(child: Text(group['name'])),
          if (group['isNew'])
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Nuevo',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group['lastMessage']),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(group['lastMessageTime']),
              if ((group['unreadCount'] ?? 0) > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${group['unreadCount']}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          Text('Participantes: ${group['participants']}'),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatGrupalScreen(
              groupName: group['name'],
              currentUser: userName,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Encabezado con foto, nombre y botón para crear grupo.
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(userProfileUrl),
            ),
            const SizedBox(width: 8),
            Text(userName),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: _createGroup,
          ),
        ],
      ),
      // Lista de grupos.
      body: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: _buildGroupItem(groups[index]),
          );
        },
      ),
      // Barra inferior de navegación con fondo degradado.
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1B2735),
              Color(0xFF415A77),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onNavBarTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.white70,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.video_camera_front_outlined),
              label: 'Reels',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.phone),
              label: 'Teléfono',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              label: 'Grupos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Configuración',
            ),
          ],
        ),
      ),
    );
  }
}
