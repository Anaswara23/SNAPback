import 'package:flutter/material.dart';

import '../../../core/utils/ui_scale.dart';
import 'neon_backdrop.dart';
import 'snapback_header.dart';

/// Per-screen scaffold used inside [MainShell].
/// Bottom nav is owned by the shell — no route awareness needed here.
class SnapbackScaffold extends StatelessWidget {
  const SnapbackScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SnapbackHeader(title: title),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: NeonBackdrop(
        child: Padding(
          padding: context.rPad(horizontal: 16, vertical: 8),
          child: child,
        ),
      ),
    );
  }
}
