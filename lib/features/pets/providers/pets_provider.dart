import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/pet_repository.dart';
import '../../../shared/models/pet.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository(ref.watch(dioProvider));
});

final petsListProvider = FutureProvider.autoDispose<List<Pet>>((ref) async {
  final repo = ref.watch(petRepositoryProvider);
  return repo.list();
});