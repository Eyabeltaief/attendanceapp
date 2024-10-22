import 'package:attendanceapp/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:slide_to_act/slide_to_act.dart';
import 'package:geocoding/geocoding.dart';
import 'package:attendanceapp/services/location_service.dart';
//import 'package:geolocator/geolocator.dart';

class TodayScreen extends StatefulWidget {
  final String locationAddress;

  const TodayScreen({Key? key, required this.locationAddress})
      : super(key: key);

  @override
  _TodayScreenState createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  String checkIn = "--/--";
  String checkOut = "--/--";
  String location = "";
  Color primary = Colors.blue;

  @override
  void initState() {
    super.initState();
    _getRecord();
  }

  // Récupérer la localisation

  // Récupérer les enregistrements de l'employé
  void _getRecord() async {
    try {
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("Employee")
          .where('id', isEqualTo: User.employeeid.trim())
          .get();

      if (snap.docs.isNotEmpty) {
        DocumentSnapshot employeeDoc = snap.docs[0];
        DocumentSnapshot recordDoc = await FirebaseFirestore.instance
            .collection("Employee")
            .doc(employeeDoc.id)
            .collection('Record')
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()))
            .get();

        Map<String, dynamic>? data = recordDoc.data() as Map<String, dynamic>?;

        setState(() {
          checkIn = data?['checkIn'] ?? "--/--";
          checkOut = data?['checkOut'] ?? "--/--";
        });
      } else {
        setState(() {
          checkIn = "--/--";
          checkOut = "--/--";
        });
      }
    } catch (e) {
      setState(() {
        checkIn = "--/--";
        checkOut = "--/--";
      });
    }
  }

  // Gérer l'action de glissement pour Check In/Out
  // Gérer l'action de glissement pour Check In/Out
  Future<void> _handleSlideAction(bool isCheckIn) async {
    try {
      // Récupérer les informations sur l'employé
      QuerySnapshot snap = await FirebaseFirestore.instance
          .collection("Employee")
          .where('id', isEqualTo: User.employeeid.trim())
          .get();

      if (snap.docs.isNotEmpty) {
        DocumentSnapshot employeeDoc = snap.docs[0];
        DocumentReference recordDocRef = FirebaseFirestore.instance
            .collection("Employee")
            .doc(employeeDoc.id)
            .collection('Record')
            .doc(DateFormat('dd MMMM yyyy').format(DateTime.now()));

        // Créer une instance de LocationService et initialiser
        LocationService locationService = LocationService();
        await locationService.initialize();

        // Obtenir la latitude et la longitude
        double? latitude = await locationService.getLatitude();
        double? longitude = await locationService.getLongitude();

        // Obtenir l'adresse à partir des coordonnées
        String? address;
        if (latitude != null && longitude != null) {
          address = await locationService.getAddressFromCoordinates(
              latitude, longitude);
        }

        if (isCheckIn && checkIn == "--/--") {
          await recordDocRef.set({
            'checkIn': DateFormat('hh:mm').format(DateTime.now()),
            'location': {
              'latitude': latitude,
              'longitude': longitude,
              'address': address,
            }
          }, SetOptions(merge: true));
          setState(() {
            checkIn = DateFormat('hh:mm').format(DateTime.now());
          });
        } else if (!isCheckIn && checkIn != "--/--" && checkOut == "--/--") {
          await recordDocRef.set({
            'checkOut': DateFormat('hh:mm').format(DateTime.now()),
          }, SetOptions(merge: true));
          setState(() {
            checkOut = DateFormat('hh:mm').format(DateTime.now());
          });
        } else {
          print(
              "Opération non valide : déjà check-in/out ou check-in/out non autorisé.");
        }
      } else {
        print("Aucun employé trouvé avec l'ID donné.");
      }
    } catch (e) {
      print("Erreur lors de la mise à jour du record: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre de bienvenue
            Container(
              alignment: Alignment.centerLeft,
              margin: const EdgeInsets.only(top: 32),
              child: Text(
                "Welcome",
                style: TextStyle(
                  color: Colors.black26,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 20,
                ),
              ),
            ),
            // ID de l'employé
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(top: 8),
              child: Text(
                "Employee: ${User.employeeid.isNotEmpty ? User.employeeid : 'Introuvable'}",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            // Titre "Today"
            Container(
              alignment: Alignment.centerLeft,
              margin: EdgeInsets.only(top: 16),
              child: Text(
                "Today's",
                style: TextStyle(
                  color: Colors.black87,
                  fontFamily: "NexaBold",
                  fontSize: screenWidth / 18,
                ),
              ),
            ),
            // Section Check In/Out
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 32),
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(2, 2),
                  ),
                ],
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check In",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkIn,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Check Out",
                          style: TextStyle(
                            fontFamily: "NexaRegular",
                            fontSize: screenWidth / 20,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          checkOut,
                          style: TextStyle(
                            fontFamily: "NexaBold",
                            fontSize: screenWidth / 18,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Date actuelle
            Container(
              alignment: Alignment.centerLeft,
              child: RichText(
                text: TextSpan(
                  text: DateTime.now().day.toString(),
                  style: TextStyle(
                    color: primary,
                    fontSize: screenWidth / 18,
                    fontFamily: "NexaBold",
                  ),
                  children: [
                    TextSpan(
                      text: DateFormat(' MMMM yyyy ').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: screenWidth / 18,
                        fontFamily: "NexaBold",
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Heure actuelle
            StreamBuilder(
                stream: Stream.periodic(const Duration(seconds: 1)),
                builder: (context, snapshot) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      DateFormat('hh:mm:ss').format(DateTime.now()),
                      style: TextStyle(
                        fontFamily: "NexaRegular",
                        fontSize: screenWidth / 20,
                        color: Colors.black54,
                      ),
                    ),
                  );
                }),
            // Action de glissement pour Check In/Out
            Container(
              margin: EdgeInsets.only(top: 24),
              child: Builder(
                builder: (context) {
                  GlobalKey<SlideActionState> key =
                      GlobalKey<SlideActionState>();

                  return SlideAction(
                    text:
                        "Slide to ${checkIn == "--/--" ? 'Check In' : 'Check Out'}",
                    textStyle: TextStyle(
                      fontSize: screenWidth / 20,
                      color: Colors.black54,
                    ),
                    sliderButtonIcon: Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                    innerColor: Colors.blue,
                    outerColor: Colors.white,
                    onSubmit: () {
                      if (checkIn == "--/--") {
                        _handleSlideAction(true);
                      } else if (checkOut == "--/--") {
                        _handleSlideAction(false);
                      }
                      key.currentState?.reset();
                    },
                    key: key,
                  );
                },
              ),
            ),
            // Afficher la localisation
            SizedBox(height: 20),
            Center(
              child: Text(
                'Location: ${widget.locationAddress}', // Afficher la localisation passée depuis HomeScreen
                style: TextStyle(
                  fontFamily: "NexaRegular",
                  fontSize: screenWidth / 18,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
