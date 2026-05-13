import 'package:flutter/material.dart';

import 'pet/pet_widget.dart';

class MeiTuanDeskPetApp extends StatelessWidget {
  const MeiTuanDeskPetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MeiTuanDeskPet',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: PetWidget()),
      ),
    );
  }
}
