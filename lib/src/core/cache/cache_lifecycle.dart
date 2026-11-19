import 'dart:async';
import 'package:flutter/material.dart';
import 'cache_maintenance.dart';

/// Mobile apps cannot run Dart timers while terminated. Clean at startup,
/// on resume, and once a minute while open; read paths also enforce expiration.
class CacheLifecycle extends StatefulWidget {
  const CacheLifecycle({super.key, required this.child});
  final Widget child;
  @override
  State<CacheLifecycle> createState() => _CacheLifecycleState();
}

class _CacheLifecycleState extends State<CacheLifecycle>
    with WidgetsBindingObserver {
  late final Timer _timer;
  bool _running = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _prune();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _prune());
  }

  Future<void> _prune() async {
    if (_running) return;
    _running = true;
    try {
      await CacheMaintenance.pruneAll();
    } catch (error) {
      debugPrint('Cache cleanup failed: $error');
    } finally {
      _running = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _prune();
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
