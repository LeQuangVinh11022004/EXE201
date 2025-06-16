import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:exe_201/main.dart';
import 'package:exe_201/journal/journal_provider.dart';

void main() {
  testWidgets('Check login screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => JournalProvider(),
        child: const MyApp(),
      ),
    );

    await tester.pumpAndSettle(Duration(seconds: 5));
    await tester.pump(Duration(milliseconds: 500)); 

    expect(find.text('Mom&Baby'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2)); 
    expect(find.text('Login'), findsOneWidget); 

    await tester.enterText(find.byType(TextField).first, 'testuser');
    await tester.pump();
    expect(find.text('testuser'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump();
    expect(find.text('password123'), findsOneWidget);
  });
}