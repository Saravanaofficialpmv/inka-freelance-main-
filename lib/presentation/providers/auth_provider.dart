import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../core/utils/error_handler.dart';
import '../../services/firestore_service.dart';
import '../../data/models/business_profile.dart';
import '../../data/models/client.dart';
import '../../data/models/product.dart';
import '../../data/models/invoice.dart';
import '../../data/models/invoice_item.dart';
import 'profile_provider.dart';
import 'client_provider.dart';
import 'product_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';
import '../viewmodels/expense_viewmodel.dart';
import '../viewmodels/time_tracker_viewmodel.dart';
import '../viewmodels/project_viewmodel.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return AuthNotifier(firestoreService, ref);
});

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final FirestoreService _firestoreService;
  final Ref _ref;

  AuthNotifier(this._firestoreService, this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<User?>? _authSubscription;

  void _init() {
    final currentUser = _auth.currentUser;
    state = AsyncValue.data(currentUser);
    if (currentUser != null) {
      _syncAndRefresh(currentUser.uid);
    }

    _authSubscription = _auth.authStateChanges().listen((user) {
      state = AsyncValue.data(user);
      if (user != null) {
        _syncAndRefresh(user.uid);
      }
    });
  }

  Future<void> _syncAndRefresh(String uid) async {
    await _firestoreService.syncAllData(uid);
    _ref.read(profileProvider.notifier).loadFromLocal();
    _ref.read(clientsProvider.notifier).refreshFromLocal();
    _ref.read(productsProvider.notifier).refreshFromLocal();
    _ref.read(invoiceProvider.notifier).refreshFromLocal();
    _ref.read(expenseProvider.notifier).refreshFromLocal();
    _ref.read(timeEntriesProvider.notifier).refreshFromLocal();
    _ref.read(projectProvider.notifier).refreshFromLocal();
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(credential.user);
      if (credential.user != null) {
        await _syncAndRefresh(credential.user!.uid);
      }
    } catch (e, st) {
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
      rethrow;
    }
  }

  Future<void> signUp(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(credential.user);
      if (credential.user != null) {
        await _syncAndRefresh(credential.user!.uid);
      }
    } catch (e, st) {
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      try {
        await googleSignIn.signOut();
      } catch (_) {}

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in dialog
        state = AsyncValue.data(_auth.currentUser);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      state = AsyncValue.data(userCredential.user);

      if (userCredential.user != null) {
        await _syncAndRefresh(userCredential.user!.uid);
      }
    } catch (e, st) {
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
      rethrow;
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      state = AsyncValue.data(userCredential.user);

      if (userCredential.user != null) {
        await _syncAndRefresh(userCredential.user!.uid);
      }
    } catch (e, st) {
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> signOut() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) {
        await googleSignIn.signOut();
      }
      await _auth.signOut();
      _ref.read(profileProvider.notifier).clear();
      _ref.read(clientsProvider.notifier).clear();
      _ref.read(productsProvider.notifier).clear();
      _ref.read(invoiceProvider.notifier).clear();
      _ref.read(expenseProvider.notifier).clear();
      _ref.read(projectProvider.notifier).clear();
      _ref.read(timeEntriesProvider.notifier).clear();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
    }
  }

  Future<void> signInAsDemo() async {
    state = const AsyncValue.loading();
    try {
      User? user;
      try {
        final credential = await _auth.signInAnonymously();
        user = credential.user;
      } catch (_) {
        // Fallback in case anonymous auth is restricted on Firebase Console
        try {
          final credential = await _auth.signInWithEmailAndPassword(
            email: 'demo@inkabilling.com',
            password: 'DemoPassword123!',
          );
          user = credential.user;
        } catch (_) {
          try {
            final credential = await _auth.createUserWithEmailAndPassword(
              email: 'demo@inkabilling.com',
              password: 'DemoPassword123!',
            );
            user = credential.user;
          } catch (_) {}
        }
      }

      state = AsyncValue.data(user ?? _auth.currentUser);
      await seedDemoData();
    } catch (e) {
      // Offline fallback: seed demo data locally regardless
      await seedDemoData();
      state = AsyncValue.data(_auth.currentUser);
    }
  }

  Future<void> seedDemoData() async {
    final profileBox = Hive.box<BusinessProfile>('business_profile');
    final clientsBox = Hive.box<Client>('clients');
    final invoicesBox = Hive.box<Invoice>('invoices');
    final productsBox = Hive.box<Product>('products');

    // 1. Business Profile
    final demoProfile = BusinessProfile(
      businessName: 'Inka Design Studio',
      address: '742 Evergreen Terrace, San Francisco, CA 94107',
      phone: '+1 (555) 019-2834',
      email: 'hello@inkastudio.com',
      currency: '\$',
      gstNumber: 'GSTIN29ABCDE1234F1Z5',
      accountHolderName: 'Inka Creative Studio LLC',
      accountNo: '987654321012',
      ifscCode: 'HDFC0001234',
      bankName: 'Silicon Valley Bank',
      branchName: 'Downtown SF',
      upiId: 'inkastudio@okhdfcbank',
      upiNumber: '+15550192834',
    );
    await profileBox.put('current', demoProfile);
    _ref.read(profileProvider.notifier).loadFromLocal();

    // 2. Sample Clients
    final client1 = Client(
      id: 'client_demo_1',
      name: 'Acme Technologies',
      phone: '+1 (555) 234-5678',
      email: 'billing@acmetech.io',
      address: '100 Innovation Way, Suite 400, New York, NY',
      gstNumber: 'GSTIN27AAAAA0000A1Z5',
    );
    final client2 = Client(
      id: 'client_demo_2',
      name: 'Sarah Connor Design',
      phone: '+1 (555) 876-5432',
      email: 'sarah@connorstudio.com',
      address: '42 Skyfall Avenue, Los Angeles, CA',
    );
    await clientsBox.put(client1.id, client1);
    await clientsBox.put(client2.id, client2);
    _ref.read(clientsProvider.notifier).refreshFromLocal();

    // 3. Sample Products
    final prod1 = Product(
      id: 'prod_demo_1',
      name: 'Brand Identity Design',
      defaultPrice: 850.0,
      category: 'Design',
      description: 'Complete logo suite, color palette, and typography guidelines.',
    );
    final prod2 = Product(
      id: 'prod_demo_2',
      name: 'Mobile App UI/UX Design',
      defaultPrice: 1200.0,
      category: 'Design',
      description: 'High-fidelity Figma prototypes and design system.',
    );
    final prod3 = Product(
      id: 'prod_demo_3',
      name: 'Full-Stack Web App',
      defaultPrice: 2500.0,
      category: 'Development',
      description: 'Frontend and backend development with cloud deployment.',
    );
    await productsBox.put(prod1.id, prod1);
    await productsBox.put(prod2.id, prod2);
    await productsBox.put(prod3.id, prod3);
    _ref.read(productsProvider.notifier).refreshFromLocal();

    // 4. Sample Invoices
    final inv1 = Invoice(
      id: 'inv_demo_1',
      invoiceNumber: 'INV-2024-001',
      client: client1,
      items: [
        InvoiceItem(id: 'item_demo_1', name: 'Brand Identity Design', quantity: 1, price: 850.0),
        InvoiceItem(id: 'item_demo_2', name: 'Mobile App UI/UX Design', quantity: 1, price: 1200.0),
      ],
      issueDate: DateTime.now().subtract(const Duration(days: 4)),
      dueDate: DateTime.now().add(const Duration(days: 10)),
      taxPercentage: 18.0,
      discount: 100.0,
      status: 'paid',
      notes: 'Thank you for your business! Payment settled via UPI.',
    );
    final inv2 = Invoice(
      id: 'inv_demo_2',
      invoiceNumber: 'INV-2024-002',
      client: client2,
      items: [
        InvoiceItem(id: 'item_demo_3', name: 'Full-Stack Web App', quantity: 1, price: 2500.0),
      ],
      issueDate: DateTime.now().subtract(const Duration(days: 1)),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      taxPercentage: 18.0,
      discount: 0.0,
      status: 'pending',
      notes: 'Net 15 days payment terms.',
    );
    await invoicesBox.put(inv1.id, inv1);
    await invoicesBox.put(inv2.id, inv2);
    _ref.read(invoiceProvider.notifier).refreshFromLocal();
  }

  DateTime? _lastPasswordResetRequest;
  static const Duration _passwordResetCooldown = Duration(seconds: 60);

  Future<void> resetPassword(String email) async {
    final now = DateTime.now();
    if (_lastPasswordResetRequest != null) {
      final elapsed = now.difference(_lastPasswordResetRequest!);
      if (elapsed < _passwordResetCooldown) {
        final remaining = _passwordResetCooldown.inSeconds - elapsed.inSeconds;
        throw 'Please wait $remaining seconds before requesting another password reset.';
      }
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      _lastPasswordResetRequest = now;
    } catch (e, st) {
      if (e is String) rethrow;
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
