import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/branding/branding_provider.dart';
import '../features/auth/login_page.dart';
import '../features/landing_jpmc/jpmc_startups_clone_page.dart';
import '../features/relationship_hub/relationship_hub_page.dart';
import '../features/banker/banker_crm_page.dart';
import '../shared/widgets/app_shell.dart';

// ── Route paths ───────────────────────────────────────────────────────────────

class AppRoutes {
  static const login = '/login';
  static const signup = '/signup';
  static const stageSelector = '/stages';
  static const relationshipHub = '/relationship-hub';
  static const banker = '/banker';
  static const home = '/';

  static const mybankerHome = '/mybanker';
  static const mybankerBanker = '/mybanker/banker';
  static const mybankerBankerDetail = '/mybanker/banker/:prospectId';
  static const mybankerStageSelector = '/mybanker/stages';
  static const mybankerRelationshipHub = '/mybanker/relationship-hub';
  static const mybankerProspect = '/mybanker/p=:prospectId';

  static const mybankersBanker = '/mybankers/banker';
  static const mybankersBankerDetail = '/mybankers/banker/:prospectId';
}

/// Simple [ChangeNotifier] owned by the root widget and notified whenever
/// auth state changes. Passed to [GoRouter.refreshListenable] so redirects
/// are re-evaluated on every login / logout.
class RouterRefreshNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

// ── Router factory ────────────────────────────────────────────────────────────

/// [refreshNotifier] — the [RouterRefreshNotifier] owned by the root widget.
/// [isAuthenticated] — reads current auth state (via `ref.read`).
GoRouter createRouter({
  required RouterRefreshNotifier refreshNotifier,
  required bool Function() isAuthenticated,
  required WidgetRef ref,
}) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: refreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final authed = isAuthenticated();
      final uri = state.uri;
      final path = uri.path;

      // 1. Branding detection and persistence
      final isTargetMyBanker = path.startsWith('/mybanker') || path.startsWith('/mybankers');
      if (isTargetMyBanker) {
        Future.microtask(() => ref.read(brandingProvider.notifier).setBranding(BrandingMode.myBanker));
      } else {
        // If not explicitly visiting a mybanker path, but our state is myBanker,
        // we redirect them to the branded path.
        final currentBranding = ref.read(brandingProvider);
        if (currentBranding == BrandingMode.myBanker) {
          if (path != AppRoutes.login && path != AppRoutes.signup) {
            final newPath = path == '/' ? '/mybanker' : '/mybanker$path';
            final newUri = Uri(path: newPath, queryParameters: uri.queryParameters);
            return newUri.toString();
          }
        } else {
          Future.microtask(() => ref.read(brandingProvider.notifier).setBranding(BrandingMode.jpmc));
        }
      }

      // 2. Auth redirect logic
      final isOnLogin = path == AppRoutes.login;
      final isOnSignup = path == AppRoutes.signup;

      if (!authed) {
        if (isOnLogin) {
          return null;
        }
        return AppRoutes.login;
      }

      if (isOnLogin || isOnSignup) {
        final currentBranding = ref.read(brandingProvider);
        return currentBranding == BrandingMode.myBanker ? AppRoutes.mybankerHome : AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.signup,
        redirect: (_, __) => AppRoutes.login,
      ),
      
      // Default Routes
      GoRoute(
        path: AppRoutes.stageSelector,
        pageBuilder: (context, state) {
          final returnProspectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: AppShell(
              stageBucket: 'super_agent',
              prospectId: returnProspectId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        pageBuilder: (context, state) {
          final invitationCode = state.uri.queryParameters['invite'];
          final returnProspectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: JpmcStartupsClonePage(
              invitationCode: invitationCode,
              returnProspectId: returnProspectId,
            ),
          );
        },
      ),
      GoRoute(
        path: '/p=:prospectId',
        pageBuilder: (context, state) {
          final prospectId = state.pathParameters['prospectId'];
          final mode = state.uri.queryParameters['mode'];
          return NoTransitionPage(
            child: AppShell(
              stageBucket: 'super_agent',
              prospectId: prospectId,
              startAtModeSelection: true,
              initialConversationMode: mode,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.relationshipHub,
        pageBuilder: (context, state) {
          final prospectId = state.uri.queryParameters['p'];
          final mode = state.uri.queryParameters['mode'];
          return NoTransitionPage(
            child: RelationshipHubPage(
              prospectId: prospectId,
              mode: mode,
              dynamicVariables: const {},
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.banker,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BankerCrmPage(),
        ),
      ),
      GoRoute(
        path: '/banker/:prospectId',
        pageBuilder: (context, state) {
          final prospectId = state.pathParameters['prospectId'];
          return NoTransitionPage(
            child: BankerDetailPage(
              prospectId: prospectId ?? '',
            ),
          );
        },
      ),

      // My Banker Branded Routes
      GoRoute(
        path: AppRoutes.mybankerHome,
        pageBuilder: (context, state) {
          final invitationCode = state.uri.queryParameters['invite'];
          final returnProspectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: JpmcStartupsClonePage(
              invitationCode: invitationCode,
              returnProspectId: returnProspectId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mybankerStageSelector,
        pageBuilder: (context, state) {
          final returnProspectId = state.uri.queryParameters['p'];
          return NoTransitionPage(
            child: AppShell(
              stageBucket: 'super_agent',
              prospectId: returnProspectId,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mybankerProspect,
        pageBuilder: (context, state) {
          final prospectId = state.pathParameters['prospectId'];
          final mode = state.uri.queryParameters['mode'];
          return NoTransitionPage(
            child: AppShell(
              stageBucket: 'super_agent',
              prospectId: prospectId,
              startAtModeSelection: true,
              initialConversationMode: mode,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mybankerRelationshipHub,
        pageBuilder: (context, state) {
          final prospectId = state.uri.queryParameters['p'];
          final mode = state.uri.queryParameters['mode'];
          return NoTransitionPage(
            child: RelationshipHubPage(
              prospectId: prospectId,
              mode: mode,
              dynamicVariables: const {},
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mybankerBanker,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BankerCrmPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.mybankerBankerDetail,
        pageBuilder: (context, state) {
          final prospectId = state.pathParameters['prospectId'];
          return NoTransitionPage(
            child: BankerDetailPage(
              prospectId: prospectId ?? '',
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.mybankersBanker,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: BankerCrmPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.mybankersBankerDetail,
        pageBuilder: (context, state) {
          final prospectId = state.pathParameters['prospectId'];
          return NoTransitionPage(
            child: BankerDetailPage(
              prospectId: prospectId ?? '',
            ),
          );
        },
      ),
    ],
  );
}
