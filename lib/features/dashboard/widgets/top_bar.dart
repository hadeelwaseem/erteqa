import 'package:flutter/material.dart';
import 'package:sooq_merchant/Features/customization/presentation/screens/customization_screen.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Positioned(
            left: 55,
            right: 68,
            child: Container(
              height: 44,
              padding: const EdgeInsets.only(left: 24, right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'My Store',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CustomizationScreen(),
                        ),
                      );
                    },
                    child: const Icon(Icons.edit, size: 18),
                  ),

                  const SizedBox(width: 12),
                  const Icon(Icons.search, size: 18),
                ],
              ),
            ),
          ),
          Positioned(
            left: 42,
            child: ClipPath(
              clipper: CurvedConnectorClipper(),
              child: Container(width: 15, height: 44, color: Colors.white),
            ),
          ),

          const Positioned(left: 0, child: _CircleIcon(icon: Icons.menu)),
          const Positioned(
            right: 0,
            child: _CircleIcon(icon: Icons.notifications_none),
          ),
        ],
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;

  const _CircleIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: Colors.white,
      child: Icon(icon, color: Colors.black),
    );
  }
}

class CurvedConnectorClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // نبدأ من أعلى اليسار
    path.moveTo(0, size.height * 0.3);

    // منحنى علوي (ينحني للداخل في الأعلى)
    path.quadraticBezierTo(
      size.width * 0.5, // نقطة التحكم x (المنتصف)
      size.height * 0.5, // نقطة التحكم y (للداخل - للأسفل)
      size.width, // نقطة النهاية x
      size.height * 0.3, // نقطة النهاية y
    );

    // خط للأسفل
    path.lineTo(size.width, size.height * 0.7);

    // منحنى سفلي (ينحني للخارج في الأسفل)
    path.quadraticBezierTo(
      size.width * 0.5, // نقطة التحكم x (المنتصف)
      size.height * 0.5, // نقطة التحكم y (للخارج - للأعلى)
      0, // نقطة النهاية x
      size.height * 0.7, // نقطة النهاية y
    );

    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
