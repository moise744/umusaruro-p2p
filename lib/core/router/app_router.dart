import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:umusaruro_p2p/core/constants/app_routes.dart';

// Screens — we will create these in upcoming steps
// For now they are placeholder imports — fill in as we build each screen
import 'package:umusaruro_p2p/features/auth/presentation/screens/splash_screen.dart';
import 'package:umusaruro_p2p/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:umusaruro_p2p/features/auth/presentation/screens/login_screen.dart';
import 'package:umusaruro_p2p/features/auth/presentation/screens/otp_screen.dart';
import 'package:umusaruro_p2p/features/auth/presentation/screens/register_screen.dart';
import 'package:umusaruro_p2p/features/auth/presentation/screens/farmer_profile_setup_screen.dart';
import 'package:umusaruro_p2p/features/auth/presentation/screens/pending_verification_screen.dart';
import 'package:umusaruro_p2p/features/farmer/presentation/screens/farmer_home_screen.dart';
import 'package:umusaruro_p2p/features/farmer/presentation/screens/my_projects_screen.dart';
import 'package:umusaruro_p2p/features/investor/presentation/screens/investor_home_screen.dart';
import 'package:umusaruro_p2p/features/investor/presentation/screens/browse_projects_screen.dart';
import 'package:umusaruro_p2p/features/cell_leader/presentation/screens/cell_leader_home_screen.dart';
import 'package:umusaruro_p2p/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:umusaruro_p2p/features/messages/presentation/screens/messages_screen.dart';
import 'package:umusaruro_p2p/features/profile/presentation/screens/profile_screen.dart';

import 'package:umusaruro_p2p/features/farmer/presentation/screens/project_detail_screen.dart';
import 'package:umusaruro_p2p/features/farmer/presentation/screens/harvest_submit_screen.dart';
import 'package:umusaruro_p2p/features/investor/presentation/screens/invest_flow_screen.dart';
import 'package:umusaruro_p2p/core/mock/mock_data.dart';
import 'package:umusaruro_p2p/core/screens/transactions_screen.dart';
part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      // ── Auth ──────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        builder: (context, state) {
          final phone = state.extra as String;
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.farmerProfileSetup,
        builder: (context, state) => const FarmerProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.pendingVerification,
        builder: (context, state) => const PendingVerificationScreen(),
      ),

      // ── Farmer Shell (bottom nav) ──────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => FarmerShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.farmerHome,
            builder: (context, state) => const FarmerHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.myProjects,
            builder: (context, state) => const MyProjectsScreen(),
          ),
          GoRoute(
            path: AppRoutes.messages,
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Investor Shell (bottom nav) ────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => InvestorShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.investorHome,
            builder: (context, state) => const InvestorHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.browseProjects,
            builder: (context, state) => const BrowseProjectsScreen(),
          ),
        ],
      ),

      // ── Cell Leader Shell ──────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) => CellLeaderShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.cellLeaderHome,
            builder: (context, state) => const CellLeaderHomeScreen(),
          ),
        ],
      ),

      // ── Shared ────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),

      // ── Project Detail (farmer & investor), Invest/Harvest flows, Transactions ──
      GoRoute(
        path: '/farmer/projects/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: id, isInvestorView: false);
        },
      ),
      GoRoute(
        path: '/investor/projects/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProjectDetailScreen(projectId: id, isInvestorView: true);
        },
      ),
      GoRoute(
        path: '/investor/projects/:id/invest',
        builder: (context, state) {
          final project = state.extra as MockProject;
          return InvestFlowScreen(project: project);
        },
      ),
      GoRoute(
        path: '/farmer/projects/:id/harvest',
        builder: (context, state) {
          final project = state.extra as MockProject;
          return HarvestSubmitScreen(project: project);
        },
      ),
      GoRoute(
        path: '/farmer/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: '/investor/transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
    ],
  );
}

// ── Shell widgets (bottom nav bars per role) ────────────────────────────────

class FarmerShell extends StatelessWidget {
  final Widget child;
  const FarmerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.eco_outlined),
            activeIcon: Icon(Icons.eco),
            label: 'My Projects',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.myProjects)) return 1;
    if (location.startsWith(AppRoutes.messages)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.farmerHome);
        return;
      case 1:
        context.go(AppRoutes.myProjects);
        return;
      case 2:
        context.go(AppRoutes.messages);
        return;
      case 3:
        context.go(AppRoutes.profile);
        return;
    }
  }
}

class InvestorShell extends StatelessWidget {
  final Widget child;
  const InvestorShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            activeIcon: Icon(Icons.search),
            label: 'Browse',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Portfolio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.browseProjects)) return 1;
    if (location.startsWith(AppRoutes.portfolio)) return 2;
    if (location.startsWith(AppRoutes.messages)) return 3;
    if (location.startsWith(AppRoutes.profile)) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.investorHome);
        return;
      case 1:
        context.go(AppRoutes.browseProjects);
        return;
      case 2:
        context.go(AppRoutes.portfolio);
        return;
      case 3:
        context.go(AppRoutes.messages);
        return;
      case 4:
        context.go(AppRoutes.profile);
        return;
    }
  }
}

class CellLeaderShell extends StatelessWidget {
  final Widget child;
  const CellLeaderShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (index) => _onTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: 'Tasks',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith(AppRoutes.verificationHistory)) return 1;
    if (location.startsWith(AppRoutes.messages)) return 2;
    if (location.startsWith(AppRoutes.profile)) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.cellLeaderHome);
        return;
      case 1:
        context.go(AppRoutes.verificationHistory);
        return;
      case 2:
        context.go(AppRoutes.messages);
        return;
      case 3:
        context.go(AppRoutes.profile);
        return;
    }
  }
}
