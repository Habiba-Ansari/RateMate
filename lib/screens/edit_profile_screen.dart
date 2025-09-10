import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  late String name;
  late String gender;
  late int age;
  late String city;
  late String bio;
  late String interests;
  late String lookingFor;
  late String occupation;
  late String education;
  late int height;
  late String relationshipGoals;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    name = widget.user.name;
    gender = widget.user.gender;
    lookingFor = widget.user.lookingFor; // Add this
    age = widget.user.age;
    city = widget.user.city;
    bio = widget.user.bio;
    interests = widget.user.interests.join(", ");
    occupation = widget.user.occupation; // Add this
    education = widget.user.education; // Add this
    height = widget.user.height; // Add this
    relationshipGoals = widget.user.relationshipGoals; // Add this
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      UserModel updatedUser = UserModel(
        uid: widget.user.uid,
        name: name,
        gender: gender,
        lookingFor: lookingFor, // Add this
        age: age,
        city: city,
        bio: bio,
        interests: interests.split(",").map((e) => e.trim()).toList(),
        profilePics: widget.user.profilePics,
        averageRating: widget.user.averageRating,
        occupation: occupation, // Add this
        education: education, // Add this
        height: height, // Add this
        relationshipGoals: relationshipGoals, // Add this
      );

      try {
        await _profileService.createOrUpdateProfile(updatedUser);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully!")),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            // ✅ Updated brand colors from your logo
            colors: [Color(0xFF8E44AD), Color(0xFFE67E22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const Text(
                        "Edit Your Profile",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8E44AD), // ✅ brand color
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: "Name",
                        initialValue: name,
                        icon: Icons.person,
                        onSaved: (val) => name = val!,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Gender",
                        initialValue: gender,
                        icon: Icons.wc,
                        onSaved: (val) => gender = val!,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Age",
                        initialValue: age.toString(),
                        icon: Icons.calendar_today,
                        keyboardType: TextInputType.number,
                        onSaved: (val) => age = int.parse(val!),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "City",
                        initialValue: city,
                        icon: Icons.location_city,
                        onSaved: (val) => city = val!,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Interests",
                        initialValue: interests,
                        icon: Icons.star,
                        onSaved: (val) => interests = val!,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: "Bio",
                        initialValue: bio,
                        icon: Icons.info,
                        onSaved: (val) => bio = val!,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF8E44AD,
                            ), // ✅ brand purple
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child:
                              isLoading
                                  ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                  : const Text(
                                    "Save Changes",
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Helper method for DRY code
  Widget _buildTextField({
    required String label,
    required String initialValue,
    required IconData icon,
    required FormFieldSetter<String> onSaved,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF8E44AD)), // brand purple
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      validator: (val) => val!.isEmpty ? "Enter $label" : null,
      onSaved: onSaved,
    );
  }
}
