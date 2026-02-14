import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sooq_merchant/config/config_loader.dart';
import 'package:sooq_merchant/core/utils/service_locator.dart';
import 'package:sooq_merchant/core/widgets/bottom_nav_bar.dart';
import 'package:sooq_merchant/engine/component_renderer/component_renderer.dart';
import 'package:sooq_merchant/engine/screen_renderer/screen_renderer.dart';
import 'package:sooq_merchant/config/models/app_theme_model.dart';
import 'package:sooq_merchant/config/models/store_layout_model.dart';
import 'package:sooq_merchant/features/dashboard/domain/dashboard_data.dart';
import 'package:sooq_merchant/features/dashboard/presentation/manager/dashboard_cubit/dashboard_cubit.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<void> _configFuture;
  late final ConfigLoader _configLoader;
  late final ScreenRenderer _screenRenderer;
  late final AppThemeModel _colors;
  late final StoreLayoutModel _layout;

  @override
  void initState() {
    super.initState();
    _configLoader = getIt<ConfigLoader>();
    _screenRenderer = ScreenRenderer(getIt<Map<String, ComponentRenderer>>());
    _configFuture = Future.value();
    _colors = AppThemeModel(
      primary: const Color(0xFF273B56),
      secondary: const Color(0xFFE5E7EB),
      background: const Color(0xFFF5F6FA),
      button: const Color(0xFF1E2A3A),
      success: const Color(0xFF8DB9A0),
      text: Colors.black,
    );
    _layout = StoreLayoutModel.defaultLayout();
    context.read<DashboardCubit>().loadDashboard(recentOrdersMaxItems: 3);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _configFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return FutureBuilder(
          future: _configLoader.load(),
          builder: (context, configSnapshot) {
            if (configSnapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (configSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error loading config: ${configSnapshot.error}'),
                ),
              );
            }

            final appConfig = configSnapshot.data!;
            final dashboardScreen = appConfig.screens.firstWhere(
              (screen) => screen.id == 'dashboard',
              orElse: () =>
                  throw Exception('Dashboard screen not found in config'),
            );

            return BlocBuilder<DashboardCubit, DashboardState>(
              builder: (context, state) {
                if (state is DashboardLoading || state is DashboardInitial) {
                  return Scaffold(
                    backgroundColor: _colors.background,
                    body: const Center(child: CircularProgressIndicator()),
                  );
                }
                if (state is DashboardFailure) {
                  return Scaffold(
                    backgroundColor: _colors.background,
                    body: Center(child: Text('Error: ${state.message}')),
                  );
                }

                final dataContext = _prepareDataContext(
                  state is DashboardSuccess ? state.data : null,
                );

                return Scaffold(
                  backgroundColor: _colors.background,
                  bottomNavigationBar: BottomNavBar(colors: _colors),
                  body: SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _screenRenderer.render(
                        dashboardScreen,
                        dataContext: dataContext,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  //check datakey?
  Map<String, dynamic> _prepareDataContext(DashboardData? data) {
    return {
      if (data != null) ...{
        'welcomeMessage': data.welcomeMessage,
        'stats': data.stats,
        'recentOrders': data.recentOrders,
        'insights': data.insights,
      },
      'appTheme': _colors,
      'storeLayout': _layout,
    };
  }
}
