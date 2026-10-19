import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'presentation/screens/interactive_web_invoice_screen.dart';
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
import 'presentation/screens/template_gallery_screen.dart';
import 'presentation/screens/state_showcase_screen.dart';
import 'presentation/screens/company_details_screen.dart';
import 'presentation/screens/bank_details_screen.dart';
import 'presentation/screens/signature_settings_screen.dart';
import 'presentation/screens/document_settings_screen.dart';
import 'presentation/screens/notes_terms_screen.dart';
import 'presentation/screens/currency_settings_screen.dart';
import 'presentation/screens/help_support_screen.dart';
import 'presentation/screens/privacy_policy_screen.dart';
import 'presentation/screens/language_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure custom ErrorWidget builder to log exceptions and prevent full-screen freezes
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('════════════ Flutter Error in Widget Tree ════════════');
    debugPrint(details.exceptionAsString());
    debugPrint(details.stack.toString());
    debugPrint('═══════════════════════════════════════════════════════');

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: const Color(0xFFF8F9FA),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                ),
                child: const Icon(Icons.warning_amber_rounded, size: 28, color: Color(0xFFFF5722)),
              ),
              const SizedBox(height: 14),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              const Text(
                'A display error occurred. Your data remains safe and intact.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  constraints: const BoxConstraints(maxWidth: 540),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: SelectableText(
                    details.exceptionAsString(),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF334155)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ),
  );
};
  
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
    _safeOpenBox('template_config'),
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

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (dynamic _) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges());
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final location = state.matchedLocation;
      final isPublicRoute = location == '/splash' ||
          location == '/onboarding' ||
          location == '/auth' ||
          location == '/state-showcase' ||
          location.startsWith('/inv/');

      if (user == null && !isPublicRoute) {
        return '/auth';
      }
      return null;
    },
    routes: [
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: '/splash', builder: (c, s) => const SplashScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: '/onboarding', builder: (c, s) => const OnboardingScreen()),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/auth', 
        builder: (c, s) => AuthScreen(
          initialIsSignUp: s.extra is bool ? (s.extra as bool) : false,
        ),
      ),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: '/business-setup', builder: (c, s) => const BusinessSetupScreen()),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: '/clients-select', builder: (c, s) => const ClientsScreen(isSelectionMode: true)),
      GoRoute(parentNavigatorKey: rootNavigatorKey, path: '/products-select', builder: (c, s) => const ProductsScreen(isSelectionMode: true)),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/inv/:id',
        builder: (c, s) => InteractiveWebInvoiceScreen(
          invoiceId: s.pathParameters['id'] ?? '',
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/preview',
        pageBuilder: (c, s) => NoTransitionPage(
          child: s.extra is Invoice ? InvoicePreviewScreen(invoice: s.extra as Invoice) : const DashboardScreen(),
        ),
      ),
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/create-invoice',
        pageBuilder: (c, s) => const NoTransitionPage(child: CreateInvoiceScreen()),
      ),
      
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => NavShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/',
            redirect: (context, state) => '/dashboard',
          ),
          GoRoute(
            path: '/dashboard',
            pageBuilder: (c, s) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/history',
            pageBuilder: (c, s) => NoTransitionPage(
              child: InvoicesHistoryScreen(
                initialStatusFilter: s.extra is String
                    ? (s.extra as String)
                    : s.uri.queryParameters['status'],
              ),
            ),
          ),
          GoRoute(path: '/clients', pageBuilder: (c, s) => const NoTransitionPage(child: ClientsScreen())),
          GoRoute(path: '/clients-tab', pageBuilder: (c, s) => const NoTransitionPage(child: ClientsScreen())),
          GoRoute(path: '/statistics', redirect: (c, s) => '/expenses'),
          GoRoute(path: '/settings', redirect: (c, s) => '/profile'),
          GoRoute(path: '/expenses', pageBuilder: (c, s) => const NoTransitionPage(child: ExpensesScreen())),
          GoRoute(path: '/profile', pageBuilder: (c, s) => const NoTransitionPage(child: ProfileScreen())),
          GoRoute(path: '/projects', pageBuilder: (c, s) => const NoTransitionPage(child: ProjectsScreen())),
          GoRoute(path: '/products', pageBuilder: (c, s) => const NoTransitionPage(child: ProductsScreen())),
          GoRoute(path: '/time-tracker', pageBuilder: (c, s) => const NoTransitionPage(child: TimeTrackerScreen())),
          GoRoute(path: '/add-project', pageBuilder: (c, s) => const NoTransitionPage(child: AddEditProjectScreen())),
          GoRoute(
            path: '/edit-project',
            pageBuilder: (c, s) => NoTransitionPage(
              child: AddEditProjectScreen(project: s.extra is Project ? (s.extra as Project) : null),
            ),
          ),
          GoRoute(
            path: '/project-details',
            pageBuilder: (c, s) => NoTransitionPage(
              child: s.extra is Project ? ProjectDetailsScreen(project: s.extra as Project) : const ProjectsScreen(),
            ),
          ),
          GoRoute(
            path: '/client-details',
            pageBuilder: (c, s) => NoTransitionPage(
              child: s.extra is Client ? ClientDetailsScreen(client: s.extra as Client) : const ClientsScreen(),
            ),
          ),
          GoRoute(path: '/subscription', pageBuilder: (c, s) => const NoTransitionPage(child: SubscriptionScreen())),
          GoRoute(path: '/templates', pageBuilder: (c, s) => const NoTransitionPage(child: TemplateGalleryScreen())),
          GoRoute(path: '/company-details', pageBuilder: (c, s) => const NoTransitionPage(child: CompanyDetailsScreen())),
          GoRoute(path: '/bank-details', pageBuilder: (c, s) => const NoTransitionPage(child: BankDetailsScreen())),
          GoRoute(path: '/signatures', pageBuilder: (c, s) => const NoTransitionPage(child: SignatureSettingsScreen())),
          GoRoute(path: '/document-settings', pageBuilder: (c, s) => const NoTransitionPage(child: DocumentSettingsScreen())),
          GoRoute(path: '/notes-terms', pageBuilder: (c, s) => const NoTransitionPage(child: NotesTermsScreen())),
          GoRoute(path: '/language-settings', pageBuilder: (c, s) => const NoTransitionPage(child: LanguageSettingsScreen())),
          GoRoute(path: '/currency-settings', pageBuilder: (c, s) => const NoTransitionPage(child: CurrencySettingsScreen())),
          GoRoute(path: '/help-support', pageBuilder: (c, s) => const NoTransitionPage(child: HelpSupportScreen())),
          GoRoute(path: '/privacy-policy', pageBuilder: (c, s) => const NoTransitionPage(child: PrivacyPolicyScreen())),
          GoRoute(path: '/state-showcase', pageBuilder: (c, s) => const NoTransitionPage(child: StateShowcaseScreen())),
        ],
      ),
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
      themeMode: ThemeMode.light,
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
