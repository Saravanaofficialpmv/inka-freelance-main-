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
import 'presentation/widgets/nav_shell.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/products_screen.dart';
import 'presentation/screens/business_setup_screen.dart';

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
  
  // 4. Open Boxes
  await Future.wait([
    Hive.openBox<Client>('clients'),
    Hive.openBox<Invoice>('invoices'),
    Hive.openBox<BusinessProfile>('business_profile'),
    Hive.openBox<Product>('products'),
  ]);
  
  runApp(const ProviderScope(child: InkaApp()));
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
          GoRoute(path: '/create-invoice', pageBuilder: (c, s) => const NoTransitionPage(child: CreateInvoiceScreen())),
          GoRoute(path: '/history', pageBuilder: (c, s) => const NoTransitionPage(child: InvoicesHistoryScreen())),
          GoRoute(path: '/profile', pageBuilder: (c, s) => const NoTransitionPage(child: ProfileScreen())),
        ],
      ),
      
      GoRoute(path: '/preview', builder: (c, s) => InvoicePreviewScreen(invoice: s.extra as Invoice)),
      GoRoute(path: '/clients', builder: (c, s) => const ClientsScreen()),
      GoRoute(path: '/clients-select', builder: (c, s) => const ClientsScreen(isSelectionMode: true)),
      GoRoute(path: '/products', builder: (c, s) => const ProductsScreen()),
      GoRoute(path: '/products-select', builder: (c, s) => const ProductsScreen(isSelectionMode: true)),
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
