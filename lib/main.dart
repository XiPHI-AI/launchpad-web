import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'core/auth/auth_provider.dart';
import 'router/app_router.dart';
import 'shared/widgets/demo_banner.dart';
import 'theme/app_theme.dart';

void main() {
  usePathUrlStrategy();
  runApp(const ProviderScope(child: LaunchPadApp()));
}

class LaunchPadApp extends ConsumerStatefulWidget {
  const LaunchPadApp({super.key});

  @override
  ConsumerState<LaunchPadApp> createState() => _LaunchPadAppState();
}

class _LaunchPadAppState extends ConsumerState<LaunchPadApp> {
  late final RouterRefreshNotifier _routerNotifier;
  late final _router;
  bool _showDemoBanner = true;

  @override
  void initState() {
    super.initState();
    _routerNotifier = RouterRefreshNotifier();
    _router = createRouter(
      refreshNotifier: _routerNotifier,
      isAuthenticated: () => ref.read(isAuthenticatedProvider),
      ref: ref,
    );
    // Restore session from secure storage silently on first launch
    Future.microtask(
      () => ref.read(authNotifierProvider.notifier).tryAutoLogin(),
    );
  }

  @override
  void dispose() {
    _routerNotifier.dispose();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Drive GoRouter refresh whenever auth state changes.
    // ref.listen is safe here — called during build.
    ref.listen<bool>(isAuthenticatedProvider, (_, __) {
      _routerNotifier.notify();
    });

    return MaterialApp.router(
      title: 'Prospectz.ai',
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
      theme: AppTheme.light(),
      builder: (context, child) {
        final routedChild = child ?? const SizedBox.shrink();

        if (!_showDemoBanner) {
          return routedChild;
        }

        return Column(
          children: [
            DemoBanner(
              dismissible: true,
              onDismiss: () {
                setState(() => _showDemoBanner = false);
              },
            ),
            Expanded(child: routedChild),
          ],
        );
      },
    );
  }
}
