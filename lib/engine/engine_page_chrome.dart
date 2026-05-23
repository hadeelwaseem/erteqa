import 'package:flutter/material.dart';

/// Mutable page chrome registered during render (e.g. [appDrawer]).
///
/// Stored once on root [dataContext] so nested debug context copies do not
/// lose drawer registration.
class EnginePageChromeRegistry {
  EnginePageChromeRegistry();

  static const contextKey = '_enginePageChrome';

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  Widget? drawer;
  String drawerEdge = 'start';
}

/// Legacy keys — prefer [EnginePageChromeRegistry].
class EnginePageChrome {
  EnginePageChrome._();

  static const drawerKey = '_enginePageDrawer';
  static const drawerEdgeKey = '_enginePageDrawerEdge';
}
