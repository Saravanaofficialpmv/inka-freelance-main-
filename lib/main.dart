import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/localization/app_localizations.dart';
import 'presentation/providers/locale_provider.dart';
import 'core/theme/app_theme.dart';
import 'data/models/client.dart';
import 'presentation/screens/splash_screen.dart';
import 'presentation/screens/onboarding_screen.dart';
import 'presentation/screens/auth_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/create_invoice_screen.dart';
import 'presentation/screens/invoice_preview_screen.dart';
import 'presentation/screens/clients_screen.dart';
import 'data/models/invoice_item.dart';
import 'data/models/invoice.dart';
import 'data/models/business_profile.dart';
import 'data/models/product.dart';
import 'data/models/expense.dart';
import 'data/models/time_entry.dart';
import 'data/models/project.dart';
import 'presentation/widgets/nav_shell.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/invoices_history_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/business_setup_screen.dart';
import 'presentation/screens/expenses_screen.dart';
import 'presentation/screens/time_tracker_screen.dart';
import 'presentation/screens/projects_screen.dart';
import 'presentation/screens/add_edit_project_screen.dart';
import 'presentation/screens/project_details_screen.dart';
import 'presentation/screens/client_details_screen.dart';
import 'presentation/screens/subscription_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  // 2. Initialize Hive
  await Hive.initFlutter();
  
  // 3. Safe Adapter Registration (Prevents "TypeAdapter already registered" errors)
  if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ClientAdapter());
  if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(InvoiceAdapter());
  if (!Hive.isAdapterRegistered(2)) Hive.registerAdapter(InvoiceItemAdapter());
  if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(BusinessProfileAdapter());
  if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(ProductAdapter());
  if (!Hive.isAdapterRegistered(6)) Hive.registerAdapter(ExpenseAdapter());
  if (!Hive.isAdapterRegistered(7)) Hive.registerAdapter(TimeEntryAdapter());
  if (!Hive.isAdapterRegistered(8)) Hive.registerAdapter(ProjectAdapter());
  
  // 4. Open Boxes with Fault-Tolerant Error Recovery
  await Future.wait([
    _safeOpenBox<Client>('clients'),
    _safeOpenBox<Invoice>('invoices'),
    _safeOpenBox<BusinessProfile>('business_profile'),
    _safeOpenBox<Product>('products'),
    _safeOpenBox<Expense>('expenses'),
    _safeOpenBox<TimeEntry>('time_entries'),
    _safeOpenBox<Project>('projects'),
    _safeOpenBox('subscription_prefs'),
  ]);
  
  runApp(const ProviderScope(child: InkaApp()));
}

Future<void> _safeOpenBox<T>(String name) async {
  try {
    await Hive.openBox<T>(name);
  } catch (e) {
    debugPrint('Hive openBox error for $name, attempting auto-recovery: $e');
    try {
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox<T>(name);
    } catch (e2) {
      debugPrint('Fatal box open failure for $name: $e2');
    }
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        path: '/auth', 
        builder: (c, s) => AuthScreen(
          initialIsSignUp: s.extra is bool ? (s.extra as bool) : false,
        ),
      ),
      GoRoute(path: '/business-setup', builder: (c, s) => const BusinessSetupScreen()),
      
      ShellRoute(
        builder: (context, state, child) => NavShell(state: state, child: child),
        routes: [
          GoRoute(path: '/dashboard', pageBuilder: (c, s) => const NoTransitionPage(child: DashboardScreen())),
          GoRoute(path: '/history', pageBuilder: (c, s) => const NoTransitionPage(child: InvoicesHistoryScreen())),
          GoRoute(path: '/clients-tab', pageBuilder: (c, s) => const NoTransitionPage(child: ClientsScreen())),
          GoRoute(path: '/expenses', pageBuilder: (c, s) => const NoTransitionPage(child: ExpensesScreen())),
          GoRoute(path: '/profile', pageBuilder: (c, s) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
      GoRoute(path: '/create-invoice', builder: (c, s) => const CreateInvoiceScreen()),
      
      GoRoute(path: '/preview', builder: (c, s) => InvoicePreviewScreen(invoice: s.extra as Invoice)),
      GoRoute(path: '/clients', builder: (c, s) => const ClientsScreen()),
      GoRoute(path: '/clients-select', builder: (c, s) => const ClientsScreen(isSelectionMode: true)),
      GoRoute(path: '/products', builder: (c, s) => const ProductsScreen()),
      GoRoute(path: '/products-select', builder: (c, s) => const ProductsScreen(isSelectionMode: true)),
      GoRoute(path: '/expenses', builder: (c, s) => const ExpensesScreen()),
      GoRoute(path: '/time-tracker', builder: (c, s) => const TimeTrackerScreen()),
      GoRoute(path: '/projects', builder: (c, s) => const ProjectsScreen()),
      GoRoute(path: '/add-project', builder: (c, s) => const AddEditProjectScreen()),
      GoRoute(path: '/edit-project', builder: (c, s) => AddEditProjectScreen(project: s.extra as Project?)),
      GoRoute(path: '/project-details', builder: (c, s) => ProjectDetailsScreen(project: s.extra as Project)),
      GoRoute(path: '/client-details', builder: (c, s) => ClientDetailsScreen(client: s.extra as Client)),
      GoRoute(path: '/subscription', builder: (c, s) => const SubscriptionScreen()),
    ],
  );
});

class InkaApp extends ConsumerWidget {
  const InkaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    final currentLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Inka',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      locale: currentLocale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
        Locale('hi'),
        Locale('es'),
      ],
    );
  }
}
