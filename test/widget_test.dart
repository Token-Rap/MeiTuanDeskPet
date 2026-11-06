import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meituan_desk_pet/pet/pet_state.dart';
import 'package:meituan_desk_pet/pet/pet_view.dart';

final petPaint = find.descendant(
  of: find.byType(PetView),
  matching: find.byType(CustomPaint),
);

Future<void> waitForSprite(WidgetTester tester) async {
  for (var attempt = 0; attempt < 100; attempt++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
    if (petPaint.evaluate().isNotEmpty) return;
  }
  fail('Cat sprite did not load within five seconds');
}

void main() {
  testWidgets('PetView renders idle sprite by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PetView(mood: PetMood.idle)),
    ));
    await waitForSprite(tester);

    expect(find.byType(PetView), findsOneWidget);
    expect(petPaint, findsOneWidget);
  });

  testWidgets('PetView renders petted sprite', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PetView(mood: PetMood.petted)),
    ));
    await waitForSprite(tester);

    expect(find.byType(PetView), findsOneWidget);
    expect(petPaint, findsOneWidget);
  });
  testWidgets('switching cats loads the smaller Xiaomei sprite', (tester) async {
    Widget view(PetCat cat) => MaterialApp(
      home: Scaffold(body: Center(child: PetView(mood: PetMood.idle, cat: cat))),
    );
    await tester.pumpWidget(view(PetCat.xiaotuan));
    await waitForSprite(tester);
    expect(tester.getSize(petPaint).width, 208);

    await tester.pumpWidget(view(PetCat.xiaomei));
    await waitForSprite(tester);
    expect(tester.getSize(petPaint).width, 184);
    expect(tester.takeException(), isNull);
  });

  testWidgets('idle breathing keeps the approved sleep image', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: PetView(mood: PetMood.idle))),
    ));
    await waitForSprite(tester);
    dynamic painter = tester.widget<CustomPaint>(petPaint).painter;
    final sleepImage = painter.spritesheet;
    expect(painter.sleeping, isTrue);
    await tester.pump(const Duration(minutes: 25));
    await tester.pump(const Duration(milliseconds: 520));
    painter = tester.widget<CustomPaint>(petPaint).painter;
    expect(painter.sleeping, isTrue);
    expect(identical(painter.spritesheet, sleepImage), isTrue);
    expect(painter.breath, greaterThan(0));
  });

}
