import 'package:flutter/material.dart';
import 'package:attendanceapp/model/user.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String employeeid; // employeeid required

  const ProfileScreen({Key? key, required this.employeeid}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late String employeeid;
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = Colors.blue;
  DateTime? selectedDate;
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController birthDateController = TextEditingController();
  File? _image; // to store the selected image

  @override
  void initState() {
    super.initState();
    employeeid = widget.employeeid;
    loadProfileData(); // Load data at startup
  }

  void loadProfileData() async {
    String userId = User.id; // Utiliser toujours User.id pour Firestore

    DocumentReference docRef = FirebaseFirestore.instance.collection("Employee").doc(userId);
    DocumentSnapshot docSnapshot = await docRef.get();

    print("User ID: $userId");
    print("Document exists: ${docSnapshot.exists}");

    if (docSnapshot.exists) {
      var data = docSnapshot.data() as Map<String, dynamic>;
      setState(() {
        firstNameController.text = data['firstName'] ?? '';
        lastNameController.text = data['lastName'] ?? '';
        addressController.text = data['address'] ?? '';
        selectedDate = DateTime.tryParse(data['birthDate'] ?? '');
        if (selectedDate != null) {
          birthDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!);
        }
      });
    } else {
      showSnackBar("Aucun profil trouvé, veuillez le créer.");
    }
  }



  Future<void> updateProfile() async {
    try {
      // Fetch the data from the text controllers
      String firstName = firstNameController.text.trim();
      String lastName = lastNameController.text.trim();
      String address = addressController.text.trim();
      String birthDate = selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : '';

      // Document reference in Firestore for the specific employee
      DocumentReference documentRef = FirebaseFirestore.instance.collection('Employee').doc(widget.employeeid);

      // Update or add fields without overwriting existing ones
      await documentRef.set({
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate,
        'address': address,
      }, SetOptions(merge: true)); // Use merge:true to avoid overwriting 'id' and 'password'

      showSnackBar("Profile updated successfully!");

    } catch (e) {
      showSnackBar("Error updating profile: $e");
    }
  }



  Future<void> saveProfile() async {
    await updateProfile(); // Appel de la méthode updateProfile
  }

  Future<void> pickUploadProfilePic() async {
    final ImagePicker picker = ImagePicker(); // Initialize ImagePicker
    final pickedFile = await picker.pickImage(source: ImageSource.gallery); // Choose an image from gallery

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the selected image
      });
    } else {
      showSnackBar("Aucune image sélectionnée.");
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile image
            Center(
              child: GestureDetector(
                onTap: pickUploadProfilePic,
                child: Container(
                  margin: const EdgeInsets.only(top: 20, bottom: 24),
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: _image == null
                        ? Icon(Icons.person, color: Colors.white, size: 88)
                        : Image.file(
                      _image!,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: Text(
                "Employé $employeeid",
                style: const TextStyle(
                  fontFamily: "NexaBold",
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Personal information
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // First name
                    TextField(
                      controller: firstNameController,
                      decoration: InputDecoration(labelText: "Prénom"),
                    ),
                    const SizedBox(height: 10),
                    // Last name
                    TextField(
                      controller: lastNameController,
                      decoration: InputDecoration(labelText: "Nom de famille"),
                    ),
                    const SizedBox(height: 10),
                    // Address
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(labelText: "Adresse"),
                    ),
                    const SizedBox(height: 10),
                    // Birth date
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextField(
                          controller: birthDateController,
                          decoration: InputDecoration(
                            labelText: "Date de naissance",
                            hintText: selectedDate != null
                                ? DateFormat('yyyy-MM-dd').format(selectedDate!)
                                : "Sélectionnez une date",
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Save button
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await saveProfile(); // Save profile
                        },
                        child: const Text("ENREGISTRER"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          textStyle: const TextStyle(fontSize: 16, fontFamily: 'NexaBold'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // Use current date if no date is selected
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        birthDateController.text = DateFormat('yyyy-MM-dd').format(selectedDate!); // Update text field
      });
    }
  }

  void showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
