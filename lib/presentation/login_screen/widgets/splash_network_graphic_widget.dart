import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';

class SplashNetworkGraphicWidget extends StatefulWidget {
  const SplashNetworkGraphicWidget({super.key});

  @override
  State<SplashNetworkGraphicWidget> createState() =>
      _SplashNetworkGraphicWidgetState();
}

class _SplashNetworkGraphicWidgetState extends State<SplashNetworkGraphicWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _orbitAnim;

  static const List<Map<String, dynamic>> _avatars = [
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_199c3ae7b-1772442873446.png',
      'semanticLabel': 'Young Indian woman smiling with dark hair',
      'angle': 0.0,
      'radius': 90.0,
    },
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_1f40969ca-1763294911047.png',
      'semanticLabel': 'Middle-aged man with beard in casual shirt',
      'angle': 1.05,
      'radius': 80.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1714976326342-cf51796acad6',
      'semanticLabel': 'Young woman with glasses working',
      'angle': 2.1,
      'radius': 95.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1721477880222-1d92c77ccb47',
      'semanticLabel': 'Young man in white shirt outdoors',
      'angle': 3.14,
      'radius': 85.0,
    },
    {
      'imageUrl':
          'https://img.rocket.new/generatedImages/rocket_gen_img_19c0f0964-1772488339944.png',
      'semanticLabel': 'Woman in professional attire smiling',
      'angle': 4.19,
      'radius': 90.0,
    },
    {
      'imageUrl':
          'https://images.unsplash.com/photo-1632402121906-234d054fe55f',
      'semanticLabel': 'Older man with grey hair in traditional attire',
      'angle': 5.24,
      'radius': 78.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        )..forward(),
        curve: Curves.easeOutBack,
      ),
    );
    _orbitAnim = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: AnimatedBuilder(
        animation: _orbitAnim,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Orbit rings
              _OrbitRing(radius: 78, opacity: 0.12),
              _OrbitRing(radius: 95, opacity: 0.08),

              // Orbiting avatars
              ..._avatars.map((a) {
                final angle =
                    (a['angle'] as double) + _orbitAnim.value * 2 * 3.14159;
                final radius = a['radius'] as double;
                final x = radius * 0.55 * (angle / 6.28);
                final dx =
                    radius *
                    0.6 *
                    (1 - 2 * ((angle % 6.28) / 6.28 - 0.5).abs());
                final offsetX = radius * 0.7 * _cos(angle);
                final offsetY = radius * 0.45 * _sin(angle);
                return Positioned(
                  left: 120 + offsetX - 18,
                  top: 120 + offsetY - 18,
                  child: _AvatarOrb(
                    imageUrl: a['imageUrl'] as String,
                    semanticLabel: a['semanticLabel'] as String,
                    size: 36,
                  ),
                );
              }),

              // Center logo
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.goldLight, AppTheme.gold],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.gold.withAlpha(102),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'H',
                    style: GoogleFonts.dmSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0A0A0A),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  double _cos(double angle) {
    return (angle % (2 * 3.14159) < 3.14159 ? 1 : -1) *
        (1 - 2 * ((angle % 3.14159) / 3.14159 - 0.5).abs());
  }

  double _sin(double angle) {
    return (angle % (2 * 3.14159) < 3.14159 / 2 ||
                angle % (2 * 3.14159) > 3 * 3.14159 / 2
            ? 1
            : -1) *
        (1 - 2 * ((angle % 3.14159 / 1.5) - 0.33).abs()).clamp(-1.0, 1.0);
  }
}

class _OrbitRing extends StatelessWidget {
  final double radius;
  final double opacity;
  const _OrbitRing({required this.radius, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2 * 0.65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.gold.withOpacity(opacity), width: 1),
      ),
    );
  }
}

class _AvatarOrb extends StatelessWidget {
  final String imageUrl;
  final String semanticLabel;
  final double size;

  const _AvatarOrb({
    required this.imageUrl,
    required this.semanticLabel,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.gold.withAlpha(128), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 6),
        ],
      ),
      child: ClipOval(
        child: CustomImageWidget(
          imageUrl: imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }
}
