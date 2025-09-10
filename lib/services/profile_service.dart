import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class ProfileService {
  // Strongly-typed collection using withConverter
  final CollectionReference<UserModel> usersCollection =
      FirebaseFirestore.instance
          .collection("users")
          .withConverter<UserModel>(
            fromFirestore: (snap, _) =>
                // 👇 Pass BOTH the map and the doc id to your factory
                UserModel.fromMap(snap.data()!, snap.id),
            toFirestore: (user, _) => user.toMap(),
          );

  /// Create or update user profile
  Future<void> createOrUpdateProfile(UserModel user) async {
    try {
      await usersCollection.doc(user.uid).set(user, SetOptions(merge: true));
    } catch (e) {
      throw Exception("❌ Failed to save profile: $e");
    }
  }

  /// Get user profile by UID
  Future<UserModel?> getProfile(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception("❌ Failed to fetch profile: $e");
    }
  }

  /// Update some fields only (optional helper)
  Future<void> updateProfileFields(String uid, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection("users").doc(uid).update(data);
    } catch (e) {
      throw Exception("❌ Failed to update profile fields: $e");
    }
  }

  /// Delete user profile
  Future<void> deleteProfile(String uid) async {
    try {
      await usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception("❌ Failed to delete profile: $e");
    }
  }

  /// Check if profile exists
  Future<bool> profileExists(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      throw Exception("❌ Failed to check profile: $e");
    }
  }
}
