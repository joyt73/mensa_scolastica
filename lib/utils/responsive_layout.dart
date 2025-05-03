import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget tabletLayout;

  const ResponsiveLayout({
    Key? key,
    required this.mobileLayout,
    required this.tabletLayout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Utilizza MediaQuery per ottenere le dimensioni dello schermo
    final width = MediaQuery.of(context).size.width;

    // Su tablet usiamo il layout tablet
    if (width >= 600) {
      return tabletLayout;
    }

    // Altrimenti usiamo il layout mobile
    return mobileLayout;
  }
}

// Funzioni helper per il responsive design
class ResponsiveHelper {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
          MediaQuery.of(context).size.width < 1200;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static double getHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static double getWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;
}