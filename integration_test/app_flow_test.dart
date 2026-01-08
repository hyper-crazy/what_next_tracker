import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:what_next/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Full App Flow', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Define standard delays
    const Duration slowMo = Duration(seconds: 1);       // For adding items
    const Duration verifyDelay = Duration(seconds: 3);  // For checking the filter

    // --- CHECK: LOGOUT IF NEEDED ---
    if (find.byType(FloatingActionButton).evaluate().isNotEmpty) {
      print("System: User is already logged in. Logging out first...");
      await tester.tap(find.byKey(const Key('home_profile_icon')));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Log Out'),
        500.0,
        scrollable: find.byType(Scrollable).last,
      );

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
    }

    // --- STEP 1: LOGIN ---
    print("Step 1: Logging in...");
    await tester.enterText(find.byKey(const Key('login_email')), 'marufislam1232@gmail.com');
    await tester.enterText(find.byKey(const Key('login_password')), 'a!1234567890');
    await tester.pump();
    await tester.tap(find.byKey(const Key('login_button')));
    await tester.pumpAndSettle();

    // --- STEP 2: ADD 3 MEDIA ITEMS (SLOW MOTION) ---
    final mediaItems = [
      {'title': 'Inception', 'type': 'Movie'},
      {'title': 'Breaking Bad', 'type': 'Series'},
      {'title': 'Solo Leveling', 'type': 'Anime'},
      {'title': 'The Alchemist', 'type': 'Book'},
    ];

    for (var item in mediaItems) {
      print("Step 2: Adding ${item['title']}...");

      // 1. Open Add Screen
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await Future.delayed(slowMo); // PAUSE

      // 2. Type Title
      await tester.enterText(find.byKey(const Key('add_media_title')), item['title']!);
      await Future.delayed(slowMo); // PAUSE

      // 3. Select Type
      await tester.tap(find.byKey(const Key('add_media_type_dropdown')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(item['type']!).last);
      await tester.pumpAndSettle();
      await Future.delayed(slowMo); // PAUSE

      // 4. Save
      await tester.tap(find.byKey(const Key('add_media_save')));
      await tester.pumpAndSettle();
      await Future.delayed(slowMo); // PAUSE
    }

    // --- STEP 3: CHANGE USERNAME ---
    print("Step 3: Updating Profile...");
    await tester.tap(find.byKey(const Key('home_profile_icon')));
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    await tester.enterText(nameField, 'HyperCrazy');

    await tester.tap(find.text('Save Profile Changes'));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    // --- STEP 4: SEARCH ---
    print("Step 4: Searching...");
    await tester.enterText(find.byType(TextField), 'Inception');
    await tester.pumpAndSettle();

    expect(find.text('Inception'), findsAtLeastNWidgets(1));

    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();

    // --- STEP 5: DELETE ---
    print("Step 5: Deleting...");

    final breakingBadText = find.text('The Alchemist').first;
    final specificCard = find.ancestor(
      of: breakingBadText,
      matching: find.byType(Card),
    ).first;
    final deleteButton = find.descendant(
      of: specificCard,
      matching: find.byIcon(Icons.delete_outline_rounded),
    );

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();


    // --- STEP 6: FILTER (WITH 3 SECOND PAUSE) ---
    print("Step 6: Filtering...");

    // 1. Click Filter Icon
    final filterButton = find.descendant(
      of: find.byType(AppBar),
      matching: find.byIcon(Icons.filter_alt_rounded),
    );
    if (filterButton.evaluate().isNotEmpty) {
      await tester.tap(filterButton);
    } else {
      await tester.tap(find.byIcon(Icons.filter_alt_off_rounded));
    }

    // 2. Wait for Bottom Sheet
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 3. Select 'Movies'
    final movieInSheet = find.descendant(
      of: find.byType(BottomSheet),
      matching: find.text('Movies'),
    );

    if (movieInSheet.evaluate().length > 1) {
      await tester.tap(movieInSheet.last);
    } else {
      await tester.tap(movieInSheet);
    }

    await tester.pumpAndSettle();

    // --- NEW: WAIT 3 SECONDS TO OBSERVE FILTER ---
    print("Waiting 3 seconds to verify filter results...");
    await Future.delayed(verifyDelay);

    expect(find.text('Inception'), findsAtLeastNWidgets(1));


    // --- STEP 7: LOGOUT ---
    print("Step 7: Logging Out...");
    await tester.tap(find.byKey(const Key('home_profile_icon')));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Log Out'),
      500.0,
      scrollable: find.byType(Scrollable).last,
    );

    await tester.tap(find.text('Log Out'));
    await tester.pumpAndSettle();

    expect(find.text('Log In'), findsOneWidget);
    print("TEST COMPLETED SUCCESSFULLY!");
  });
}