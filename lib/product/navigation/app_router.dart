import 'package:akillisletme/feature/app_scanner/app_scan_view.dart';
import 'package:akillisletme/feature/home/android_modules/android_modules_view.dart';
import 'package:akillisletme/feature/home/cupertino_widgets/cupertino_widgets_view.dart';
import 'package:akillisletme/feature/home/home_view.dart';
import 'package:akillisletme/feature/home/material_widgets/material_widgets_view.dart';
import 'package:akillisletme/feature/login_process/onboarding/onboarding_view.dart';
import 'package:akillisletme/feature/network/network_view.dart';
import 'package:akillisletme/feature/privacy_guide/privacy_guide_view.dart';
import 'package:akillisletme/feature/security/security_view.dart';
import 'package:akillisletme/feature/security_timeline/security_timeline_view.dart';
import 'package:akillisletme/feature/settings/about/about_view.dart';
import 'package:akillisletme/feature/settings/language_selection/language_selection_view.dart';
import 'package:akillisletme/feature/settings/settings_view.dart';
import 'package:akillisletme/product/navigation/route_transitions.dart';
import 'package:akillisletme/product/service/service_locator.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

part 'app_router.g.dart';

@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [
    TypedGoRoute<SettingsRoute>(
      path: 'settings',
      routes: [
        TypedGoRoute<AboutRoute>(path: 'about'),
        TypedGoRoute<LanguageSelectionRoute>(path: 'language'),
      ],
    ),
    TypedGoRoute<SecurityRoute>(path: 'security'),
    TypedGoRoute<SecurityTimelineRoute>(path: 'security-timeline'),
    TypedGoRoute<AppScanRoute>(path: 'app-scan'),
    TypedGoRoute<NetworkRoute>(path: 'network'),
    TypedGoRoute<PrivacyGuideRoute>(path: 'privacy-guide'),
    TypedGoRoute<MaterialWidgetsRoute>(path: 'material-widgets'),
    TypedGoRoute<CupertinoWidgetsRoute>(path: 'cupertino-widgets'),
    TypedGoRoute<AndroidModulesRoute>(path: 'android-modules'),
  ],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return fadeTransition(key: state.pageKey, child: const HomeView());
  }
}

class SecurityRoute extends GoRouteData with $SecurityRoute {
  const SecurityRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(key: state.pageKey, child: const SecurityView());
  }
}

class SecurityTimelineRoute extends GoRouteData with $SecurityTimelineRoute {
  const SecurityTimelineRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const SecurityTimelineView(),
    );
  }
}

class AppScanRoute extends GoRouteData with $AppScanRoute {
  const AppScanRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(key: state.pageKey, child: const AppScanView());
  }
}

class NetworkRoute extends GoRouteData with $NetworkRoute {
  const NetworkRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(key: state.pageKey, child: const NetworkView());
  }
}

class PrivacyGuideRoute extends GoRouteData with $PrivacyGuideRoute {
  const PrivacyGuideRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const PrivacyGuideView(),
    );
  }
}

class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const SettingsView(),
    );
  }
}

class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const AboutView(),
    );
  }
}

class LanguageSelectionRoute extends GoRouteData with $LanguageSelectionRoute {
  const LanguageSelectionRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const LanguageSelectionView(),
    );
  }
}

class MaterialWidgetsRoute extends GoRouteData with $MaterialWidgetsRoute {
  const MaterialWidgetsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const MaterialWidgetsView(),
    );
  }
}

class CupertinoWidgetsRoute extends GoRouteData with $CupertinoWidgetsRoute {
  const CupertinoWidgetsRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const CupertinoWidgetsView(),
    );
  }
}

class AndroidModulesRoute extends GoRouteData with $AndroidModulesRoute {
  const AndroidModulesRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return slideRightTransition(
      key: state.pageKey,
      child: const AndroidModulesView(),
    );
  }
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) {
    return fadeTransition(key: state.pageKey, child: const OnboardingView());
  }
}

/// App router configuration
final class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: locator.sharedCache.isOnboardingCompleted
        ? '/'
        : '/onboarding',
    routes: $appRoutes,
  );
}
