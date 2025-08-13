import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Importa las demás pantallas para la navegación inferior
import 'package:delf_global/screens/reels.dart';
import 'package:delf_global/screens/principal.dart';
import 'package:delf_global/screens/grupos.dart';
import 'package:delf_global/screens/configuracion_screen.dart';


/// Modelo que representa un registro de llamada.
class CallLog {
  final String id; // Identificador único para el Dismissible.
  final String contactName;
  final String profileImage; // URL o ruta local.
  final bool isVideoCall;
  final bool isIncoming; // true: entrante, false: saliente.
  final DateTime callTime;

  CallLog({
    required this.id,
    required this.contactName,
    required this.profileImage,
    required this.isVideoCall,
    required this.isIncoming,
    required this.callTime,
  });
}

class TelefonoScreen extends StatefulWidget {
  const TelefonoScreen({Key? key}) : super(key: key);

  @override
  _TelefonoScreenState createState() => _TelefonoScreenState();
}

class _TelefonoScreenState extends State<TelefonoScreen> {
  // Lista simulada de registros de llamadas.
  List<CallLog> callLogs = [
    CallLog(
      id: '1',
      contactName: 'Carlos Pérez',
      profileImage: 'https://via.placeholder.com/150',
      isVideoCall: true,
      isIncoming: true,
      callTime: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    CallLog(
      id: '2',
      contactName: 'María López',
      profileImage: 'https://via.placeholder.com/150',
      isVideoCall: false,
      isIncoming: false,
      callTime: DateTime.now().subtract(Duration(minutes: 20)),
    ),
    CallLog(
      id: '3',
      contactName: 'Juan Martínez',
      profileImage: 'https://via.placeholder.com/150',
      isVideoCall: false,
      isIncoming: true,
      callTime: DateTime.now().subtract(Duration(hours: 1, minutes: 10)),
    ),
    // Agrega más registros según lo necesites.
  ];

  // Variable para la navegación inferior, siendo Teléfono el índice 1.
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    // Ordena la lista para que los registros más recientes aparezcan primero.
    callLogs.sort((a, b) => b.callTime.compareTo(a.callTime));
  }

  // Retorna el ícono según el tipo de llamada y dirección.
  Icon _getCallIcon(CallLog log) {
    if (log.isVideoCall) {
      return Icon(
        Icons.videocam,
        color: log.isIncoming ? Colors.green : Colors.blue,
      );
    } else {
      return Icon(
        Icons.call,
        color: log.isIncoming ? Colors.green : Colors.blue,
      );
    }
  }

  // Función para manejar la acción al tocar un registro.
  void _onCallLogTapped(CallLog log) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(log.contactName),
        content: Text(
          log.isVideoCall ? 'Realizar videollamada' : 'Realizar llamada',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí inicia la llamada, por ejemplo: _startCall(log);
            },
            child: Text('Llamar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          )
        ],
      ),
    );
  }

  // Función para eliminar un registro de la lista.
  void _removeCallLog(String id) {
    setState(() {
      callLogs.removeWhere((log) => log.id == id);
    });
  }

  // Maneja la navegación del BottomNavigationBar.
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ReelsScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TelefonoScreen()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => PrincipalScreen()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => GruposScreen()),
      );
    } else if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfiguracionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Se eliminó el AppBar para quitar "Historial de llamadas"
      body: ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: callLogs.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) {
          final log = callLogs[index];
          return Dismissible(
            key: Key(log.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: 20),
              color: Colors.red,
              child: Icon(Icons.delete, color: Colors.white),
            ),
            onDismissed: (direction) {
              _removeCallLog(log.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Registro eliminado')),
              );
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(log.profileImage),
                radius: 25,
              ),
              title: Text(log.contactName),
              // Se ha eliminado la fecha (callTime) del subtítulo.
              trailing: _getCallIcon(log),
              onTap: () => _onCallLogTapped(log),
            ),
          );
        },
      ),
      // Barra de navegación inferior integrada
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
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
          onTap: _onItemTapped,
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
              icon: Icon(Icons.phone_android_outlined),
              label: 'Teléfono',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Perfil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group),
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
String formatTime(DateTime time) {
  return DateFormat('HH:mm').format(time);
}
