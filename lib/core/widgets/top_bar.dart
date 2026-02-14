import 'package:flutter/material.dart';
import 'package:sooq_merchant/config/models/app_theme_model.dart';

class TopBar extends StatelessWidget {
  final String storeName;
  final bool showSearch;
  final bool showCustomizeButton;
  final AppThemeModel? colors;

  const TopBar({
    super.key,
    this.storeName = 'My Store',
    this.showSearch = true,
    this.showCustomizeButton = true,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = colors?.text ?? Colors.black;

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
                  Expanded(
                    child: Text(
                      storeName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (showSearch) ...[
                    const SizedBox(width: 12),
                    Icon(Icons.search, size: 18, color: textColor),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            left: 42,
            child: ClipPath(
              clipper: _CurvedConnectorClipper(),
              child: Container(width: 15, height: 44, color: Colors.white),
            ),
          ),
          const Positioned(left: 0, child: _CircleIcon(icon: Icons.menu)),
          Positioned(
            right: 0,
            child: _CircleIcon(
              icon: showCustomizeButton
                  ? Icons.notifications_none
                  : Icons.notifications_none,
            ),
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

class _CurvedConnectorClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      size.width,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.5,
      0,
      size.height * 0.7,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
