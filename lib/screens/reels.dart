import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';

// Importa las demás pantallas para la navegación inferior
import 'package:delf_global/screens/telefono.dart';
import 'package:delf_global/screens/principal.dart';
import 'package:delf_global/screens/grupos.dart';
import 'package:delf_global/screens/configuracion_screen.dart';

/// Modelo que representa un Reel obtenido desde Airtable.
class Reel {
  final String id;
  final String videoUrl;
  final String descripcion;
  final String userFx; // Identificador del usuario que subió el reel
  final String userName;
  final String userProfileImage; // URL o ruta de la imagen de perfil
  int likes;
  int comentarios;
  final DateTime fecha;

  Reel({
    required this.id,
    required this.videoUrl,
    required this.descripcion,
    required this.userFx,
    required this.userName,
    required this.userProfileImage,
    required this.likes,
    required this.comentarios,
    required this.fecha,
  });
}

class ReelsScreen extends StatefulWidget {
  const ReelsScreen({Key? key}) : super(key: key);

  @override
  _ReelsScreenState createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen>
    with SingleTickerProviderStateMixin {
  // Lista simulada de reels; en producción, se obtendrían desde Airtable.
  List<Reel> reels = [
    Reel(
      id: '1',
      videoUrl:
          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      descripcion: 'Disfrutando del atardecer #relax',
      userFx: 'user_001',
      userName: 'Carlos Pérez',
      userProfileImage: 'https://via.placeholder.com/150',
      likes: 125,
      comentarios: 10,
      fecha: DateTime.now().subtract(Duration(minutes: 5)),
    ),
    Reel(
      id: '2',
      videoUrl:
          'https://sample-videos.com/video123/mp4/720/big_buck_bunny_720p_1mb.mp4',
      descripcion: 'Momentos increíbles #aventura',
      userFx: 'user_002',
      userName: 'María López',
      userProfileImage: 'https://via.placeholder.com/150',
      likes: 200,
      comentarios: 25,
      fecha: DateTime.now().subtract(Duration(minutes: 20)),
    ),
    // Agrega más reels según lo necesites...
  ];

  final PageController _pageController = PageController();
  int currentPage = 0;
  // Controlador de video para el reel actual
  VideoPlayerController? _videoController;
  // Control de animación para el corazón (doble tap)
  bool _showHeart = false;

  // Control de animación para la foto de perfil giratoria
  late final AnimationController _rotationController;

  // Variable para manejar la navegación inferior, siendo Reels el índice 0.
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: Duration(seconds: 5))
          ..repeat();
    _initializeVideo(currentPage);
  }

@override
void dispose() {
  // pausa y libera el controller actual
  _videoController?.pause();
  _videoController?.dispose();
  _rotationController.dispose();
  _pageController.dispose();
  super.dispose();
}

// Inicializa el vídeo para el reel en la posición [index]
Future<void> _initializeVideo(int index) async {
  // libera el anterior (si hay)
  final prev = _videoController;
  _videoController = null;
  await prev?.pause();
  await prev?.dispose();

  final reel = reels[index];
  final url = reel.videoUrl.trim();

  // API nueva (recomendada)
  final controller = VideoPlayerController.networkUrl(Uri.parse(url));

  await controller.initialize();
  controller.setLooping(true);
  await controller.play();

  if (!mounted) {
    await controller.dispose();
    return;
  }

  setState(() {
    _videoController = controller;
  });
}




  // Formatea la fecha/hora del reel
  String _formatDate(DateTime date) {
    return DateFormat('HH:mm, dd/MM/yyyy').format(date);
  }

  // Función para mostrar animación de corazón al doble tap
  void _onDoubleTap() {
    setState(() {
      _showHeart = true;
    });
    Future.delayed(Duration(milliseconds: 800), () {
      setState(() {
        _showHeart = false;
      });
    });
    // Aquí se podría actualizar el like en Airtable
  }

  // Función para eliminar un reel (si pertenece al usuario logueado)
  void _deleteReel(Reel reel) {
    // Implementa la lógica para eliminar desde Airtable si corresponde
    setState(() {
      reels.removeWhere((r) => r.id == reel.id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Reel eliminado')),
    );
  }

  // Acción al presionar el botón flotante para subir un nuevo reel
  void _uploadNewReel() {
    // Implementa abrir galería o cámara para subir un nuevo reel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Subir nuevo reel (función pendiente)')),
    );
  }

  // Maneja la navegación del BottomNavigationBar
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
      // Fondo negro para una experiencia inmersiva
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        itemCount: reels.length,
        onPageChanged: (index) {
          setState(() {
            currentPage = index;
          });
          _initializeVideo(index);
        },
        itemBuilder: (context, index) {
          final reel = reels[index];
          return GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Video de fondo
                _videoController != null &&
                        _videoController!.value.isInitialized
                    ? VideoPlayer(_videoController!)
                    : Container(color: Colors.black),
                // Superposición con información del reel
                Positioned(
                  bottom: 20,
                  left: 16,
                  right: 80,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre de usuario y foto
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage:
                                NetworkImage(reel.userProfileImage),
                            radius: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            reel.userName,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          // Si es tu propio reel, muestra opción de eliminar
                          if (reel.userFx == 'tu_userFx') // Cambia según tu lógica
                            IconButton(
                              onPressed: () => _deleteReel(reel),
                              icon: Icon(Icons.delete,
                                  color: Colors.redAccent),
                            )
                        ],
                      ),
                      SizedBox(height: 8),
                      // Descripción y hashtags
                      Text(
                        reel.descripcion,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                      SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: reel.descripcion
                            .split(' ')
                            .where((word) => word.startsWith('#'))
                            .map(
                              (hashtag) => ActionChip(
                                label: Text(
                                  hashtag,
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () {
                                  // Acción al presionar el hashtag (filtrar reels, etc.)
                                },
                              ),
                            )
                            .toList(),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _formatDate(reel.fecha),
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Botones flotantes en el lado derecho
                Positioned(
                  bottom: 80,
                  right: 16,
                  child: Column(
                    children: [
                      // Botón de like con contador
                      Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.favorite,
                                color: Colors.white, size: 30),
                            onPressed: () {
                              setState(() {
                                reel.likes++;
                              });
                              // Actualizar like en Airtable
                            },
                          ),
                          Text(
                            '${reel.likes}',
                            style: TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Botón de comentarios
                      IconButton(
                        icon: Icon(Icons.comment,
                            color: Colors.white, size: 30),
                        onPressed: () {
                          // Abre modal con comentarios
                          showModalBottomSheet(
                            context: context,
                            builder: (_) {
                              return Container(
                                height: 300,
                                color: Colors.black87,
                                child: Center(
                                  child: Text(
                                    'Comentarios (pendiente)',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      // Botón de compartir
                      IconButton(
                        icon: Icon(Icons.share,
                            color: Colors.white, size: 30),
                        onPressed: () {
                          // Implementa compartir: copiar enlace, compartir, etc.
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Compartir (pendiente)'),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16),
                      // Foto de perfil giratoria
                      RotationTransition(
                        turns: _rotationController,
                        child: CircleAvatar(
                          backgroundImage:
                              NetworkImage(reel.userProfileImage),
                          radius: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                // Animación de corazón (doble tap)
                if (_showHeart)
                  Center(
                    child: Icon(
                      Icons.favorite,
                      color: Colors.redAccent.withOpacity(0.8),
                      size: 100,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploadNewReel,
        backgroundColor: Colors.pinkAccent,
        child: Icon(Icons.add),
      ),
      // Barra de navegación inferior
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
              icon: Icon(Icons.video_camera_back_rounded),
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
