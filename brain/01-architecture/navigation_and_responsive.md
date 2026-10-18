# 01. Architecture — Navigation & Responsive Layout

Inka uses **GoRouter** (`go_router: ^17.2.0`) to handle declarative routing, authentication guards, and responsive layout switching between mobile viewports and wide desktop/web screens.

---

## 🧭 GoRouter Configuration Architecture

In `lib/main.dart`, `routerProvider` maintains two navigation keys:
- `rootNavigatorKey`: For top-level overlay screens (Splash, Onboarding, Authentication, Business Setup).
- `shellNavigatorKey`: For persistent shell routes with bottom navigation or sidebar layouts.

### Authentication Guard & Redirection
The router listens to `FirebaseAuth.instance.authStateChanges()` via `GoRouterRefreshStream`.

```dart
redirect: (context, state) {
  final user = FirebaseAuth.instance.currentUser;
  final location = state.matchedLocation;
  final isPublicRoute = location == '/splash' ||
      location == '/onboarding' ||
      location == '/auth' ||
      location == '/state-showcase';

  if (user == null && !isPublicRoute) {
    return '/auth';
  }
  return null;
}
```

---

## 📱 Responsive Layout: Mobile Shell vs Desktop/Web Sidebar

Inka automatically adapts its navigation interface based on viewport width:

```
                  ┌──────────────────────────────┐
                  │ Viewport Width Breakpoint    │
                  │       (Threshold: 800px)     │
                  └──────────────┬───────────────┘
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
                 ▼                               ▼
       Mobile (< 800px)                 Desktop / Web (>= 800px)
 ┌──────────────────────────────┐ ┌────────────────────────────────────┐
 │  Screen Content              │ │ ┌────────────┐ ┌─────────────────┐ │
 │                              │ │ │ WebSidebar │ │ Screen Content  │ │
 │                              │ │ │ (Expanded  │ │                 │ │
 │                              │ │ │  menu,     │ │                 │ │
 ├──────────────────────────────┤ │ │  branding) │ │                 │ │
 │  CustomBottomNav             │ │ └────────────┘ └─────────────────┘ │
 │  (Floating dark pill bar)    │ └────────────────────────────────────┘
 └──────────────────────────────┘
```

### NavShell Implementation (`lib/presentation/widgets/nav_shell.dart`)
- **Mobile Mode**: Wraps content in a `Scaffold` featuring the floating `CustomBottomNav` bar with active indicators and fluid page transitions.
- **Desktop/Web Mode**: Wraps content in a two-column row featuring `WebSidebar` on the left (260px fixed width) and the scrollable active screen on the right.

### Transitions
Inside the `ShellRoute`, pages are rendered with `NoTransitionPage` to ensure instantaneous tab switching without awkward page slide animations.
