enum PetMood { idle, petted }

class PetState {
  const PetState({required this.mood});

  final PetMood mood;

  PetState copyWith({PetMood? mood}) => PetState(mood: mood ?? this.mood);

  static const initial = PetState(mood: PetMood.idle);
}
