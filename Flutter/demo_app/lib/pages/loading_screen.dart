import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Creamos un controlador de animación para hacer girar la imagen
    _controller = AnimationController(
      duration: const Duration(seconds: 3), // El tiempo que tarda en dar una vuelta completa
      vsync: this,
    )..repeat(); // Repite la animación infinitamente
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco
      body: Center(
        child: RotationTransition(
          turns: _controller, // Rotamos la imagen usando el controlador
          child: SvgPicture.asset(
            'assets/icons/SPASCAT_LOGO_BLUE.svg', // Reemplaza esto con el path de tu imagen
            width: 150, // Ajusta el tamaño de la imagen
            height: 150,
          ),
        ),
      ),
    );
  }
}
