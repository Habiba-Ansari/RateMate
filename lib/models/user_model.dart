class UserModel {
  final String uid;
  final String name;
  final String gender;
  final String lookingFor; // New: Who they're looking for
  final int age;
  final String city;
  final String bio;
  final List<String> interests;
  final List<String> profilePics;
  final double averageRating;
  final String occupation; // New
  final String education; // New
  final int height; // New: in cm
  final String relationshipGoals; // New: Casual, Serious, etc.

  UserModel({
    required this.uid,
    required this.name,
    required this.gender,
    required this.lookingFor,
    required this.age,
    required this.city,
    required this.bio,
    required this.interests,
    required this.profilePics,
    required this.averageRating,
    required this.occupation,
    required this.education,
    required this.height,
    required this.relationshipGoals,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      name: data['name'] ?? '',
      gender: data['gender'] ?? '',
      lookingFor: data['lookingFor'] ?? 'Everyone',
      age: data['age'] ?? 0,
      city: data['city'] ?? '',
      bio: data['bio'] ?? '',
      interests: List<String>.from(data['interests'] ?? []),
      profilePics: List<String>.from(data['profilePics'] ?? []),
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      occupation: data['occupation'] ?? '',
      education: data['education'] ?? '',
      height: data['height'] ?? 0,
      relationshipGoals: data['relationshipGoals'] ?? 'Not specified',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'gender': gender,
      'lookingFor': lookingFor,
      'age': age,
      'city': city,
      'bio': bio,
      'interests': interests,
      'profilePics': profilePics,
      'averageRating': averageRating,
      'occupation': occupation,
      'education': education,
      'height': height,
      'relationshipGoals': relationshipGoals,
    };
  }
}