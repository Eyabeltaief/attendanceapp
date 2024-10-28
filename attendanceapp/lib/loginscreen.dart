import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendanceapp/screenhome.dart';
import 'package:attendanceapp/model/user.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart' as Auth;

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController idController = TextEditingController();
  TextEditingController passController = TextEditingController();
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = Colors.blue;
  late SharedPreferences sharedPreferences;
  final LocalAuthentication localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _initializeSharedPreferences();
  }

  Future<void> _initializeSharedPreferences() async {
    sharedPreferences = await SharedPreferences.getInstance();
    print('Employee ID in SharedPreferences: ${sharedPreferences.getString('employeeId')}');
    _checkLoginStatus();
  }

  void _checkLoginStatus() async {
    String? employeeId = sharedPreferences.getString('employeeId');
    if (employeeId != null && employeeId.isNotEmpty) {
      User.employeeid = employeeId;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> authenticateWithPassword(String id, String password) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("Employee")
          .where('id', isEqualTo: id)
          .get();

      if (snap.docs.isNotEmpty) {
        User.id = snap.docs[0].id;
        User.employeeid = id;
        await sharedPreferences.setString('employeeId', id);

        if (password == snap.docs[0]['password']) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          _showSnackbar('Password is incorrect.');
        }
      } else {
        _showSnackbar('Employee ID does not exist.');
      }
    } catch (e) {
      print("Error during query: $e");
      _showSnackbar('An error occurred: $e');
    }
  }

  Future<void> checkAuthentification() async {
    bool isAvailable = await localAuth.canCheckBiometrics;
    if (isAvailable) {
      bool result = await localAuth.authenticate(
        localizedReason: 'Scan your finger to proceed',
      );

      if (result) {
        String? employeeId = sharedPreferences.getString('employeeId');
        if (employeeId != null && employeeId.isNotEmpty) {
          User.employeeid = employeeId;

          // Vérification de l'existence de l'employé dans Firestore
          QuerySnapshot snap = await FirebaseFirestore.instance
              .collection("Employee")
              .where('id', isEqualTo: employeeId)
              .get();

          if (snap.docs.isNotEmpty) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          } else {
            _showSnackbar('No matching employee found.');
          }
        } else {
          _showSnackbar('Employee ID not found in SharedPreferences.');
        }
      } else {
        print('Authentication failed');
      }
    } else {
      print('Biometrics not available');
    }
  }

  Future<void> _fetchAttendanceData(String employeeId) async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("Attendance")
          .where('employeeId', isEqualTo: employeeId)
          .get();

      if (snap.docs.isNotEmpty) {
        for (var doc in snap.docs) {
          print('Check In: ${doc['checkIn']}');
          print('Check Out: ${doc['checkOut']}');
        }
      } else {
        _showSnackbar('No attendance records found.');
      }
    } catch (e) {
      print("Error fetching attendance data: $e");
      _showSnackbar('An error occurred while fetching attendance data.');
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: screenHeight / 3,
              width: screenWidth,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Center(
                child: Image.asset("images/prim.jpg"),
              ),
            ),
            SizedBox(height: screenHeight / 15),
            Text(
              "Login",
              style: TextStyle(
                fontSize: screenWidth / 18,
                fontFamily: "NexaBold",
              ),
            ),
            SizedBox(height: screenHeight / 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth / 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldTitle("Employee ID"),
                  customField("Enter your employee ID", idController, false),
                  fieldTitle("Password"),
                  customField("Enter your password", passController, true),
                  GestureDetector(
                    onTap: () async {
                      String id = idController.text.trim();
                      String password = passController.text.trim();
                      if (id.isEmpty || password.isEmpty) {
                        _showSnackbar("Please fill in all fields");
                        return;
                      }
                      await authenticateWithPassword(id, password);
                    },
                    child: buildButton("Login"),
                  ),
                  SizedBox(height: 20),
                  GestureDetector(
                    onTap: checkAuthentification,
                    child: buildButton("Login with Fingerprint"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget fieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        title,
        style: TextStyle(fontSize: screenWidth / 26, fontFamily: "NexaRegular"),
      ),
    );
  }

  Widget customField(String hint, TextEditingController controller, bool obscure) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight / 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: primary, size: screenWidth / 15),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: screenWidth / 12),
              child: TextFormField(
                obscureText: obscure,
                controller: controller,
                decoration: InputDecoration(
                  hintText: hint,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: screenWidth / 35),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButton(String text) {
    return Container(
      height: 60,
      width: screenWidth,
      margin: EdgeInsets.only(top: screenWidth / 40),
      decoration: BoxDecoration(
        color: primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: "NexaBold",
            fontSize: screenWidth / 25,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
