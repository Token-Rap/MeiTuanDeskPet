import 'dart:ui' as ui;
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
    final dynamic painter = tester.widget<CustomPaint>(petPaint).painter;
    expect(painter.petting, isTrue);
    expect(painter.sleeping, isFalse);
  });
  testWidgets('switching cats loads the smaller Xiaomei sprite', (tester) async {
    Widget view(PetCat cat) => MaterialApp(
      home: Scaffold(body: Center(child: PetView(mood: PetMood.idle, cat: cat))),
    );
    await tester.pumpWidget(view(PetCat.xiaotuan));
    await waitForSprite(tester);
    expect(tester.getSize(petPaint).width, 166);

    await tester.pumpWidget(view(PetCat.xiaomei));
    await waitForSprite(tester);
    expect(tester.getSize(petPaint).width, 148);
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

  testWidgets('new walking artwork mirrors pixels for left dragging', (tester) async {
    Widget view(PetMood mood) => MaterialApp(
      home: Scaffold(body: Center(child: PetView(mood: mood))),
    );
    await tester.pumpWidget(view(PetMood.draggingRight));
    await waitForSprite(tester);
    final right = tester.widget<CustomPaint>(petPaint).painter!;
    expect((right as dynamic).walking, isTrue);
    await tester.pumpWidget(view(PetMood.draggingLeft));
    final left = tester.widget<CustomPaint>(petPaint).painter!;
    await tester.runAsync(() async {
      Future<List<int>> render(CustomPainter painter) async {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Size(166, 166));
        final picture = recorder.endRecording();
        final image = await picture.toImage(166, 166);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final pixels = data!.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return pixels;
      }
      final a = await render(right);
      final b = await render(left);
      var visible = 0;
      for (var y = 0; y < 166; y += 5) {
        for (var x = 0; x < 166; x += 5) {
          final normal = (y * 166 + x) * 4;
          final mirrored = (y * 166 + 165 - x) * 4;
          if (a[normal + 3] > 128) visible++;
          for (var channel = 0; channel < 4; channel++) {
            expect((a[normal + channel] - b[mirrored + channel]).abs(), lessThanOrEqualTo(16));
          }
        }
      }
      expect(visible, greaterThan(20));
    });
  });

}
