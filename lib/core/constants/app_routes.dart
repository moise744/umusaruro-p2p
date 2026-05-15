class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String register = '/register';
  static const String farmerProfileSetup = '/farmer-profile-setup';
  static const String pendingVerification = '/pending-verification';

  // Farmer
  static const String farmerHome = '/farmer/home';
  static const String myProjects = '/farmer/projects';
  static const String projectDetailFarmer = '/farmer/projects/:id';
  static const String createProject = '/farmer/projects/create';
  static const String editProject = '/farmer/projects/:id/edit';
  static const String submitHarvest = '/farmer/projects/:id/harvest';
  static const String transactionsFarmer = '/farmer/transactions';

  // Investor
  static const String investorHome = '/investor/home';
  static const String browseProjects = '/investor/browse';
  static const String projectDetailInvestor = '/investor/projects/:id';
  static const String investmentFlow = '/investor/projects/:id/invest';
  static const String portfolio = '/investor/portfolio';
  static const String investmentDetail = '/investor/portfolio/:id';
  static const String transactionsInvestor = '/investor/transactions';

  // Shared
  static const String notifications = '/notifications';
  static const String messages = '/messages';
  static const String profile = '/profile';
  static const String helpSupport = '/help';
}
