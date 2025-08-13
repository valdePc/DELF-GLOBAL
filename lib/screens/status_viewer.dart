import 'dart:io';
import 'dart:async'; // 👈 Necesario para Timer
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StatusViewerScreen extends StatefulWidget {
  final Map<String, dynamic> status;
  final List<Map<String, dynamic>> allStatuses;
  final int initialIndex;

  const StatusViewerScreen({
    Key? key,
    required this.status,
    required this.allStatuses,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<StatusViewerScreen> createState() => _StatusViewerScreenState();
}

class _StatusViewerScreenState extends State<StatusViewerScreen> {
  late PageController _pageController;
  late int currentIndex;
  VideoPlayerController? _videoController;
  bool isPaused = false;

  double _imageProgress = 0.0;
  Timer? _imageProgressTimer;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    _loadStatus();
  }

  void _loadStatus() {
    final status = widget.allStatuses[currentIndex];
    final type = status['type'] ?? 'image';

    _disposeVideo();

    if (type == 'video') {
      final source = status['imageUrl'];
      _videoController = kIsWeb
          ? VideoPlayerController.network(source)
          : VideoPlayerController.file(File(source));

      _videoController!.initialize().then((_) {
        setState(() {});
        _videoController!.play();
        _videoController!.setLooping(false);
        _videoController!.addListener(() {
          if (!mounted) return;
          setState(() {}); // actualiza el progreso
          if (_videoController!.value.position >= _videoController!.value.duration &&
              !_videoController!.value.isPlaying) {
            _nextStatus();
          }
        });
      });
    } else {
      _imageProgress = 0.0;
      _imageProgressTimer?.cancel();
      _imageProgressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        if (!mounted) return;
        setState(() {
          _imageProgress += 0.01;
          if (_imageProgress >= 1.0) {
            timer.cancel();
            _nextStatus();
          }
        });
      });
    }
  }

  void _nextStatus() {
    if (currentIndex + 1 < widget.allStatuses.length) {
      setState(() {
        currentIndex++;
      });
      _pageController.jumpToPage(currentIndex);
      _loadStatus();
    } else {
     Navigator.pop(context, true); // Retorna 'true' para forzar refresco

    }
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _videoController = null;
    _imageProgressTimer?.cancel();
    _imageProgress = 0.0;
  }

  void _togglePlayback() {
    if (_videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
        isPaused = true;
      } else {
        _videoController!.play();
        isPaused = false;
      }
    });
  }

void _deleteStatus() async {
  final prefs = await SharedPreferences.getInstance();

  // Cargar todos los estados
  final stored = prefs.getString('statuses');
  List<Map<String, dynamic>> storedStatuses = stored != null
      ? (json.decode(stored) as List).map((e) => e as Map<String, dynamic>).toList()
      : [];

  // Eliminar este estado específico
  storedStatuses.removeWhere((s) =>
      s['contactName'] == widget.status['contactName'] &&
      s['imageUrl'] == widget.status['imageUrl']);

  // Guardar cambios
  await prefs.setString('statuses', json.encode(storedStatuses));

  Navigator.pop(context, true); // 👉 esto hace que Principal recargue
}



  @override
  void dispose() {
    _disposeVideo();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.allStatuses[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
body: GestureDetector(
  behavior: HitTestBehavior.opaque,
  onTapUp: (details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dx = details.globalPosition.dx;

    if (dx < screenWidth * 0.3) {
      if (currentIndex > 0) {
        setState(() {
          currentIndex--;
        });
        _pageController.jumpToPage(currentIndex);
        _loadStatus();
      }
    } else if (dx > screenWidth * 0.7) {
      _nextStatus();
    } else {
      _togglePlayback();
    }
  },
  child: Stack(
    children: [
            // Barra superior tipo historias
            Positioned(
              top: 16,
              left: 8,
              right: 8,
              child: Row(
                children: List.generate(widget.allStatuses.length, (index) {
                  double value;
                  if (index < currentIndex) {
                    value = 1.0;
                  } else if (index == currentIndex) {
                    value = _videoController != null && _videoController!.value.isInitialized
                        ? _videoController!.value.position.inMilliseconds /
                            _videoController!.value.duration.inMilliseconds
                        : _imageProgress;
                  } else {
                    value = 0.0;
                  }
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2.0),
                      child: LinearProgressIndicator(
                        value: value.clamp(0.0, 1.0),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white24,
                        minHeight: 4,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Contenido de los estados
            PageView.builder(
              controller: _pageController,
              itemCount: widget.allStatuses.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final item = widget.allStatuses[index];
                final src = item['imageUrl'];

                if (item['type'] == 'video') {
                  return Center(
                    child: _videoController != null && _videoController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const CircularProgressIndicator(),
                  );
                } else {
                  return Center(
                    child: src.toString().startsWith("http") || kIsWeb
                        ? Image.network(src)
                        : Image.file(File(src)),
                  );
                }
              },
            ),

            // Nombre del contacto
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                status['contactName'] ?? 'Desconocido',
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            // Botón de eliminar si es del usuario
            if (status['contactName'] == 'Tú')
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.white),
                  onPressed: _deleteStatus,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
