import 'package:flutter/material.dart';

import '../../engine/config_pipeline.dart';
import '../../engine/config_pipeline_result.dart';
import 'config_bootstrap_startup.dart';
/// Minimal startup UI when remote config fetch fails before router is ready.
class ConfigBootstrapErrorApp extends StatefulWidget {
  final ConfigPipelineResult pipelineResult;

  const ConfigBootstrapErrorApp({
    super.key,
    required this.pipelineResult,
  });

  @override
  State<ConfigBootstrapErrorApp> createState() => _ConfigBootstrapErrorAppState();
}

class _ConfigBootstrapErrorAppState extends State<ConfigBootstrapErrorApp> {
  bool _retrying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.pipelineResult.loadError;
  }

  Future<void> _retry() async {
    setState(() {
      _retrying = true;
      _errorMessage = null;
    });

    final result = await ConfigPipeline.initialize();
    if (!mounted) return;

    if (result.mobileAppConfig != null) {
      await restartWithPipelineResult(result);
      return;
    }

    setState(() {
      _retrying = false;
      _errorMessage = result.loadError ?? 'Failed to load app configuration.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.cloud_off, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Could not load app configuration',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage ?? 'Check your network connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _retrying ? null : _retry,
                  child: _retrying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
