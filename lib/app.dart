import 'package:flutter/material.dart';

import 'pet/pet_widget.dart';

class MeiTuanDeskPetApp extends StatelessWidget {
  const MeiTuanDeskPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MeiTuanDeskPet',
      color: Colors.transparent,
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Colors.transparent,
        child: Center(child: PetWidget()),
      ),
    );
  }
}
