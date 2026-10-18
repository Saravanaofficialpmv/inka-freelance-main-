import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Safely navigate back from a nested or shell route.
///
/// If a modal or stack route can be popped via standard Navigator, it pops it.
/// If not, and GoRouter is present in the widget tree, it navigates to [fallbackRoute].
/// This prevents empty navigator stacks that cause blank white screens in ShellRoute.
void safeNavigateBack(
  BuildContext context, {
  String fallbackRoute = '/profile',
  dynamic result,
}) {
  if (Navigator.canPop(context)) {
    Navigator.pop(context, result);
    return;
  }

  final router = GoRouter.maybeOf(context);
  if (router != null) {
    context.go(fallbackRoute);
  }
}

extension SafeNavigationExtension on BuildContext {
  void safePopOrGo(String fallbackRoute, [dynamic result]) {
    safeNavigateBack(this, fallbackRoute: fallbackRoute, result: result);
  }
}
