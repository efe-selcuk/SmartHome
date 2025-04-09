import 'package:flutter/material.dart';
import 'package:smarthome/screens/home_screen.dart';
import 'dart:async';
import 'dart:math' as math;

class TransitionScreen extends StatefulWidget {
  const TransitionScreen({super.key});

  @override
  _TransitionScreenState createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _logoAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;
  
  // List to store particles
  final List<Particle> _particles = [];
  final int _numberOfParticles = 30;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize particles
    _initializeParticles();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    
    // Logo animation (bounce effect)
    _logoAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _animationController,
      curve: Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));
    
    // Opacity animation
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );
    
    // Scale animation for text
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    
    // Start the animation
    _animationController.forward();
    
    // Setup animation timer for particles
    Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          // Move each particle
          for (var particle in _particles) {
            particle.move();
          }
        });
      } else {
        timer.cancel();
      }
    });
    
    // Navigate to home screen after animation completes
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              var begin = Offset(1.0, 0.0);
              var end = Offset.zero;
              var curve = Curves.easeInOutCubic;
              
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              
              return SlideTransition(
                position: offsetAnimation,
                child: child,
              );
            },
            transitionDuration: Duration(milliseconds: 800),
          ),
        );
      }
    });
  }
  
  void _initializeParticles() {
    final random = math.Random();
    for (int i = 0; i < _numberOfParticles; i++) {
      _particles.add(Particle(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 10 + 5,
        speed: random.nextDouble() * 1.5 + 0.5,
        opacity: random.nextDouble() * 0.6 + 0.1,
      ));
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.red[900],
      body: Stack(
        children: [
          // Background particles
          CustomPaint(
            size: size,
            painter: ParticlesPainter(_particles),
          ),
          
          // Main content
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated logo
                    Transform.scale(
                      scale: _logoAnimation.value,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [Colors.red[700]!, Colors.red[900]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Icon(
                          Icons.home,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Animated text
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Column(
                          children: [
                            Text(
                              'Chakra',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Akıllı Yaşama Hoş Geldiniz',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 60),
                    
                    // Loading indicator
                    Opacity(
                      opacity: _opacityAnimation.value,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Particle class for animations
class Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  
  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
  });
  
  void move() {
    y -= speed;
    if (y < -size) {
      y = 800 + size;
      x = math.Random().nextDouble() * 400;
      opacity = math.Random().nextDouble() * 0.6 + 0.1;
    }
  }
}

// CustomPainter for drawing particles
class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  
  ParticlesPainter(this.particles);
  
  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(particle.opacity)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(particle.x, particle.y),
        particle.size,
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 