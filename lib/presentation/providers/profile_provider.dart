import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../data/models/business_profile.dart';
import '../../services/firestore_service.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, BusinessProfile>((ref) {
  final box = Hive.box<BusinessProfile>('business_profile');
  final firestoreService = ref.watch(firestoreServiceProvider);
  return ProfileNotifier(box, firestoreService);
});

class ProfileNotifier extends StateNotifier<BusinessProfile> {
  final Box<BusinessProfile> _box;
  final FirestoreService _firestoreService;
  
  ProfileNotifier(this._box, this._firestoreService) : super(_box.get('current') ?? BusinessProfile.empty());

  /// Updates both local Hive and remote Firestore
  Future<void> updateProfile(BusinessProfile profile) async {
    state = profile;
    await _box.put('current', profile);
    await _firestoreService.saveBusinessProfile(profile);
  }

  /// Updates local state and Hive only (used when syncing from Firestore)
  Future<void> updateProfileLocally(BusinessProfile profile) async {
    state = profile;
    await _box.put('current', profile);
  }

  void loadFromLocal() {
    state = _box.get('current') ?? BusinessProfile.empty();
  }

  void clear() {
    state = BusinessProfile.empty();
    _box.delete('current');
  }
}
