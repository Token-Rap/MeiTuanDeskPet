import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meituan_desk_pet/pet/pet_state.dart';
import 'package:meituan_desk_pet/pet/pet_view.dart';

void main() {
  testWidgets('PetView renders idle sprite by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PetView(mood: PetMood.idle)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PetView), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
  });

  testWidgets('PetView renders petted sprite', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PetView(mood: PetMood.petted)),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(PetView), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);
  });
  testWidgets('switching cats loads the smaller Xiaomei sprite', (tester) async {
    Widget view(PetCat cat) => MaterialApp(
      home: Scaffold(body: Center(child: PetView(mood: PetMood.idle, cat: cat))),
    );
    await tester.pumpWidget(view(PetCat.xiaotuan));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CustomPaint)).width, 208);

    await tester.pumpWidget(view(PetCat.xiaomei));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(CustomPaint)).width, 184);
    expect(tester.takeException(), isNull);
  });

}
