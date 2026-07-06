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

  static const mybankerHome = '/:slug';
  static const mybankerBanker = '/:slug/banker';
  static const mybankerBankerDetail = '/:slug/banker/:prospectId';
  static const mybankerStageSelector = '/:slug/stages';
  static const mybankerRelationshipHub = '/:slug/relationship-hub';
  static const mybankerProspect = '/:slug/p=:prospectId';

  static const mybankersBanker = '/mybanks/banker';
  static const mybankersBankerDetail = '/mybanks/banker/:prospectId';
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

      // Helper to extract first path segment as slug (excluding system paths)
      String getSlugFromPath(String path) {
        if (path == '/' || path.isEmpty) return '';
        final segments = path.split('/').where((s) => s.isNotEmpty).toList();
        if (segments.isEmpty) return '';
        final firstSegment = segments.first;
        
        const systemPrefixes = {'login', 'signup', 'stages', 'relationship-hub', 'banker', 'p', 'mybanks'};
        if (systemPrefixes.contains(firstSegment)) {
          return '';
        }
        return firstSegment;
      }

      final slug = state.pathParameters['slug'] ?? getSlugFromPath(path);
      Future.microtask(() {
        ref.read(activeSlugProvider.notifier).state = slug;
        if (slug.isNotEmpty) {
          ref.read(brandingProvider.notifier).setBranding(BrandingMode.myBank);
        } else {
          ref.read(brandingProvider.notifier).setBranding(BrandingMode.jpmc);
        }
      });

      // If we are on JPMC path, but our active slug is not empty, redirect to the custom path
      if (slug.isEmpty) {
        final activeSlug = ref.read(activeSlugProvider);
        if (activeSlug.isNotEmpty) {
          if (path != AppRoutes.login && path != AppRoutes.signup && !path.startsWith('/mybanks')) {
            final newPath = path == '/' ? '/$activeSlug' : '/$activeSlug$path';
            final newUri = Uri(path: newPath, queryParameters: uri.queryParameters);
            return newUri.toString();
          }
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
        final activeSlug = ref.read(activeSlugProvider);
        return activeSlug.isNotEmpty ? '/$activeSlug' : AppRoutes.home;
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
