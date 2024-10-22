import 'package:attendanceapp/services/location_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:attendanceapp/model/user.dart';
import 'package:attendanceapp/calendarscreen.dart';
import 'package:attendanceapp/profilescreen.dart';
import 'package:attendanceapp/todayscreen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  int currentIndex = 1;
  Color primary = Colors.blue;
  List<IconData> navigationIcons = [
    FontAwesomeIcons.calendarDays,
    FontAwesomeIcons.check,
    FontAwesomeIcons.user,
  ];

  String locationAddress = 'Localisation non trouvée';
  final LocationService locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _startLocationService();
    getId().then((value) {});
    _getCredentials();
    _getProfilePic();
  }

  void _getCredentials() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection("Employee")
          .doc(User.id)
          .get();
      setState(() {
        User.canEdit = doc['canEdit'];
        User.firstName = doc['firstName'];
        User.birthDate = doc['birthDate'];
        User.address = doc['address'];
      });
    } catch (e) {
      return;
    }
  }

  Future<void> _getProfilePic() async {
    DocumentReference docRef = FirebaseFirestore.instance
        .collection("Employee")
        .doc(User.employeeid);

    try {
      DocumentSnapshot doc = await docRef.get();

      if (doc.exists) {
        setState(() {
          var data = doc.data() as Map<String, dynamic>?;

          if (data != null && data.containsKey('profilePic')) {
            User.profilePicLink = data['profilePic'];
          } else {
            User.profilePicLink = 'default_url';
          }
        });
      } else {
        _showSnackBar("Document does not exist.");
      }
    } catch (e) {
      _showSnackBar("Error loading profile picture: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _startLocationService() async {
    await locationService.initialize();
    double? longitude = await locationService.getLongitude();
    double? latitude = await locationService.getLatitude();

    if (longitude != null && latitude != null) {
      String address =
          await locationService.getAddressFromCoordinates(latitude, longitude) ?? 'Adresse non trouvée';
      setState(() {
        locationAddress = address;
        User.long = longitude;
        User.lat = latitude;
      });
    }
  }

  Future<void> getId() async {
    QuerySnapshot snap = await FirebaseFirestore.instance
        .collection("Employee")
        .where('id', isEqualTo: User.employeeid)
        .get();
    if (snap.docs.isNotEmpty) {
      setState(() {
        User.id = snap.docs[0].id;
      });
    }
  }

  void _clearLoginData() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.remove('employeeId');
  }

  @override
  void dispose() {
    _clearLoginData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          CalendarScreen(),
          TodayScreen(locationAddress: locationAddress),
          ProfileScreen(employeeid: User.employeeid),
        ],
      ),
      bottomNavigationBar: Container(
        height: 70,
        margin: const EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: 24,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(40)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int i = 0; i < navigationIcons.length; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        currentIndex = i;
                      });
                    },
                    child: Container(
                      height: screenHeight,
                      width: screenWidth,
                      color: Colors.white,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              navigationIcons[i],
                              color: i == currentIndex ? primary : Colors.black54,
                              size: i == currentIndex ? 30 : 26,
                            ),
                            i == currentIndex
                                ? Container(
                              margin: const EdgeInsets.only(top: 6),
                              height: 3,
                              width: 22,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.all(Radius.circular(40)),
                                color: primary,
                              ),
                            )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
