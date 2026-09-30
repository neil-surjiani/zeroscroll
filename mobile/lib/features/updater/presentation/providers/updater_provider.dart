import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/updater_repository.dart';
import '../../domain/update_info.dart';

final updateCheckProvider = FutureProvider<UpdateInfo?>((ref) async {
  final repository = ref.watch(updaterRepositoryProvider);
  return repository.checkForUpdate();
});
