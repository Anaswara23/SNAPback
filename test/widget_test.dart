import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snapback_app/app.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots and renders the splash logo', (tester) async {
    await tester.pumpWidget(const SnapbackRoot());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('SNAPback'), findsOneWidget);
  });
}
