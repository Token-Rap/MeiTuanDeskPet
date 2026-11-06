import 'package:flutter_test/flutter_test.dart';
import 'package:meituan_desk_pet/pet/pet_controller.dart';
import 'package:meituan_desk_pet/pet/pet_state.dart';

void main() {
  test('initial left drag faces left immediately', () {
    final pet = PetController();
    addTearDown(pet.dispose);
    pet.startDrag(deltaX: -20);
    expect(pet.value.mood, PetMood.draggingLeft);
  });

  test('reversing direction turns before crossing the starting position', () {
    final pet = PetController();
    addTearDown(pet.dispose);
    pet.startDrag(deltaX: 20);
    pet.updateDrag(100);
    pet.updateDrag(-4);
    expect(pet.value.mood, PetMood.draggingLeft);
    pet.updateDrag(4);
    expect(pet.value.mood, PetMood.draggingRight);
    pet.endDrag();
    pet.updateDrag(-100);
    expect(pet.value.mood, PetMood.idle);
  });

  test('small jitter is ignored but slow deliberate reversals accumulate', () {
    final pet = PetController();
    addTearDown(pet.dispose);
    pet.startDrag(deltaX: 20);
    pet.updateDrag(-1);
    expect(pet.value.mood, PetMood.draggingRight);
    pet.updateDrag(-1);
    pet.updateDrag(-1);
    expect(pet.value.mood, PetMood.draggingLeft);
  });
}
