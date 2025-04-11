import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../domain/repositories/user_info_respository.dart';
import '../../domain/entities/user_info.dart';

class UserInfoRepositoryFirestoreImpl implements UserInfoRepository {
  final FirebaseFirestore _firestore;
  final firebase_auth.FirebaseAuth _auth;
  final String _collection = 'user_infos';

  UserInfoRepositoryFirestoreImpl(this._firestore, this._auth);

  // Helper method to get the current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Helper method to get the user-specific collection path
  String get _userCollection => 'users/$_userId/$_collection';

  @override
  Future<List<UserInfo>> getSavedUserInfos() async {
    // Check if user is authenticated
    if (_userId == null) {
      return [];
    }

    final snapshot = await _firestore.collection(_userCollection).get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return UserInfo.fromJson(data);
    }).toList();
  }

  @override
  Future<void> saveUserInfo(UserInfo userInfo) async {
    // Check if user is authenticated
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final userInfos = await getSavedUserInfos();
    final isFirstUserInfo = userInfos.isEmpty;

    final newUserInfo = userInfo.copyWith(
      id: userInfo.id,
      isDefault: userInfo.isDefault || isFirstUserInfo,
    );

    if (newUserInfo.id != null) {
      // Update existing user info
      await _firestore
          .collection(_userCollection)
          .doc(newUserInfo.id)
          .set(newUserInfo.toJson());
    } else {
      // Add new user info
      final docRef = await _firestore
          .collection(_userCollection)
          .add(newUserInfo.toJson());

      // Update the document with its ID
      await docRef.update({'id': docRef.id});
    }
  }

  @override
  Future<void> deleteUserInfo(String id) async {
    // Check if user is authenticated
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final userInfos = await getSavedUserInfos();
    final userInfo = userInfos.firstWhere(
      (info) => info.id == id,
      orElse: () => throw Exception('User info not found'),
    );

    if (userInfo.isDefault) {
      return; // Don't delete if is default
    }

    await _firestore.collection(_userCollection).doc(id).delete();
  }

  @override
  Future<void> setDefaultUserInfo(String id) async {
    // Check if user is authenticated
    if (_userId == null) {
      throw Exception('User not authenticated');
    }

    final batch = _firestore.batch();
    final snapshot = await _firestore.collection(_userCollection).get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isDefault': doc.id == id});
    }

    await batch.commit();
  }

  @override
  Future<UserInfo?> getDefaultUserInfo() async {
    // Check if user is authenticated
    if (_userId == null) {
      return null;
    }

    final snapshot =
        await _firestore
            .collection(_userCollection)
            .where('isDefault', isEqualTo: true)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) {
      final allUserInfos = await getSavedUserInfos();
      return allUserInfos.isNotEmpty ? allUserInfos.first : null;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();
    data['id'] = doc.id;
    return UserInfo.fromJson(data);
  }
}
