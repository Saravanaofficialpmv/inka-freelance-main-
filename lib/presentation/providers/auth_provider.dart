import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/error_handler.dart';
import '../../services/firestore_service.dart';
import 'profile_provider.dart';
import 'client_provider.dart';
import 'product_provider.dart';
import '../viewmodels/invoice_viewmodel.dart';

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
        serverClientId: '605207323939-afos8vflkq6evad2img0b9cpcupk6lhe.apps.googleusercontent.com',
      );
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
      state = const AsyncValue.data(null);
    } catch (e, st) {
      final userFriendlyError = ErrorHandler.getErrorMessage(e);
      state = AsyncValue.error(userFriendlyError, st);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e, st) {
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
