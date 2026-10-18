# 05. Backend & Cloud — Authentication & Session Management

Inka supports secure user registration and multi-provider sign-in via `AuthProvider` (`lib/presentation/providers/auth_provider.dart`) and Firebase Auth.

---

## 🔑 Supported Sign-In Providers

### 1. Email & Password
- Handled with `FirebaseAuth.instance.signInWithEmailAndPassword` and `createUserWithEmailAndPassword`.
- Integrated error parser (`lib/core/utils/error_handler.dart`) converts raw Firebase error codes (`wrong-password`, `user-not-found`, `email-already-in-use`, `weak-password`) into friendly, localized messages.

### 2. Google One-Tap Sign In
- Uses `google_sign_in: ^6.2.2`.
- Fetches Google `idToken` and `accessToken`, converts to `GoogleAuthProvider.credential`, and signs into Firebase.

### 3. Sign in with Apple (iOS & macOS)
- Uses `sign_in_with_apple: ^8.1.0`.
- Generates a cryptographically secure random raw nonce, hashes it with SHA-256 (`crypto: ^3.0.7`), passes it to Apple, and authenticates using `OAuthProvider("apple.com").credential`.

---

## 🔄 Session Lifecycle & Profile Routing

```
App Launch (SplashScreen)
           │
           ▼
Check FirebaseAuth.instance.currentUser
           │
     ┌─────┴──────────────────────────────────┐
     ▼                                        ▼
User == null                             User != null
     │                                        │
Redirect to /auth                             ▼
                                    Fetch BusinessProfile (Hive / Firestore)
                                              │
                                    ┌─────────┴─────────┐
                                    ▼                   ▼
                            Profile Found       No Profile Yet
                                    │                   │
                            Redirect /dashboard Redirect /business-setup
```
