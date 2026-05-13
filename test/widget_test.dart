import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meituan_desk_pet/pet/pet_state.dart';
import 'package:meituan_desk_pet/pet/pet_view.dart';

void main() {
  testWidgets('PetView renders idle label by default', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PetView(mood: PetMood.idle)),
    ));

    expect(find.text('美团'), findsOneWidget);
  });

  testWidgets('PetView renders petted label when petted', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: PetView(mood: PetMood.petted)),
    ));
    await tester.pumpAndSettle();

    expect(find.text('摸摸 ♥'), findsOneWidget);
  });
}
