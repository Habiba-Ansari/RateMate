import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'main_screen.dart';

class CreateProfileScreen extends StatefulWidget {
  final String uid;
  const CreateProfileScreen({super.key, required this.uid});

  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _profileService = ProfileService();

  // Basic Info
  String name = '';
  String gender = 'Male';
  String lookingFor = 'Everyone';
  int age = 18;
  String city = '';
  int height = 160;
  String occupation = '';
  String education = '';
  
  // About
  String bio = '';
  String relationshipGoals = 'Not sure yet';
  String interests = '';
  
  bool isLoading = false;

  final List<String> genderOptions = ['Male', 'Female', 'Non-binary', 'Other'];
  final List<String> lookingForOptions = ['Men', 'Women', 'Everyone'];
  final List<String> relationshipGoalsOptions = [
    'Not sure yet',
    'Something casual',
    'Long-term relationship',
    'Friends first'
  ];

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => isLoading = true);

      try {
        final interestsList = interests
            .split(",")
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        UserModel user = UserModel(
          uid: widget.uid,
          name: name,
          gender: gender,
          lookingFor: lookingFor,
          age: age,
          city: city,
          interests: interestsList,
          bio: bio,
          profilePics: [],
          averageRating: 0.0,
          occupation: occupation,
          education: education,
          height: height,
          relationshipGoals: relationshipGoals,
        );

        await _profileService.createOrUpdateProfile(user);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile created successfully!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainScreen(currentUser: user)),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving profile: ${e.toString()}")),
        );
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: const Color(0xFF7B1E3C),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B1E3C), Color(0xFFF26A6A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: const Color(0xFFFDD8DB),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Basic Information'),
                    _buildTextField('Name', Icons.person, (val) => name = val!),
                    _buildDropdown('Gender', genderOptions, gender, (val) => gender = val!),
                    _buildDropdown('Looking for', lookingForOptions, lookingFor, (val) => lookingFor = val!),
                    _buildNumberField('Age', Icons.cake, (val) => age = int.parse(val!), 18, 100),
                    _buildTextField('City', Icons.location_city, (val) => city = val!),
                    _buildNumberField('Height (cm)', Icons.height, (val) => height = int.parse(val!), 100, 250),
                    _buildTextField('Occupation', Icons.work, (val) => occupation = val!),
                    _buildTextField('Education', Icons.school, (val) => education = val!),

                    const SizedBox(height: 24),
                    _buildSectionTitle('About You'),
                    _buildDropdown('Relationship Goals', relationshipGoalsOptions, relationshipGoals, (val) => relationshipGoals = val!),
                    _buildBioField('Bio', Icons.info, (val) => bio = val!),
                    _buildTextField('Interests (comma separated)', Icons.star, (val) => interests = val!),

                    const SizedBox(height: 32),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF7B1E3C)),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, FormFieldSetter<String> onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF7B1E3C)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        validator: (val) => val!.isEmpty ? 'Please enter your $label' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildNumberField(String label, IconData icon, FormFieldSetter<String> onSaved, int min, int max) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF7B1E3C)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        keyboardType: TextInputType.number,
        validator: (val) {
          if (val!.isEmpty) return 'Please enter your $label';
          final num = int.tryParse(val);
          if (num == null || num < min || num > max) return 'Please enter a valid $label ($min-$max)';
          return null;
        },
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildBioField(String label, IconData icon, FormFieldSetter<String> onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF7B1E3C)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        maxLines: 3,
        validator: (val) => val!.isEmpty ? 'Please tell us about yourself' : null,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String value, FormFieldSetter<String> onSaved) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.arrow_drop_down, color: const Color(0xFF7B1E3C)),
          border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        ),
        value: value,
        items: options.map((option) => DropdownMenuItem(value: option, child: Text(option))).toList(),
        onChanged: (val) => onSaved(val),
        validator: (val) => val == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7B1E3C),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text('Save Profile', style: TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}