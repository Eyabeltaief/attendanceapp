import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:attendanceapp/model/user.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:month_year_picker/month_year_picker.dart';
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  double screenHeight = 0;
  double screenWidth = 0;
  Color primary = Colors.blue;
  DateTime selectedDate=DateTime.now();

  @override
  void initState() {
    super.initState();
    initializeUserId();
  }

  void initializeUserId() async {
    auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      User.id = currentUser.uid;
      print('User ID initialized: ${User.id}');
    } else {
      print('No user is currently logged in.');
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    print('User ID: ${User.id}');

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            _buildDateSelector(),
            _buildAttendanceList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      alignment: Alignment.centerLeft,
      margin: EdgeInsets.only(top: 32),
      child: Text(
        "My Attendance",
        style: TextStyle(
          fontFamily: "NexaBold",
          fontSize: screenWidth / 18,
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return Stack(
      children: [
        Container(
          alignment: Alignment.centerLeft,
          margin: EdgeInsets.only(top: 32),
          child: Text(
            DateFormat('MMMM yyyy').format(selectedDate),
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final selected = await showMonthYearPicker(
              context: context,
              initialDate: selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (selected != null) {
              setState(() {
                selectedDate = selected;  // Update selectedDate with the chosen month and year
              });
            }
          },
          child: Container(
            alignment: Alignment.centerRight,
            margin: EdgeInsets.only(top: 32),
            child: Text(
              "Pick a month",
              style: TextStyle(
                fontFamily: "NexaBold",
                fontSize: screenWidth / 18,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceList() {
    return Container(
      height: screenHeight - screenHeight / 5,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("Employee")
            .doc(User.id)
            .collection("Record")
            .snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No records found.'));
          }

          final snap = snapshot.data!.docs;
          print('Documents found: ${snap.length}');

          return ListView.builder(
            itemCount: snap.length,
            itemBuilder: (context, index) {
              final data = snap[index].data() as Map<String, dynamic>;

              print('Document ID: ${snap[index].id}');
              print('Check In: ${data['checkIn']}');
              print('Check Out: ${data['checkOut']}');

              return _buildAttendanceCard(data, snap[index].id);
            },
          );
        },
      ),
    );
  }

  Widget _buildAttendanceCard(Map<String, dynamic> data, String documentId) {
    return Container(
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
          _buildDateCard(documentId),
          _buildCheckInDetails(data),
          _buildCheckOutDetails(data),
        ],
      ),
    );
  }

  Widget _buildDateCard(String documentId) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: primary,
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        child: Center(
          child: Text(
            documentId,
            style: TextStyle(
              color: Colors.white,
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInDetails(Map<String, dynamic> data) {
    return Expanded(
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
            data['checkIn'] ?? '--/--',
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutDetails(Map<String, dynamic> data) {
    return Expanded(
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
            data['checkOut'] ?? '--/--',
            style: TextStyle(
              fontFamily: "NexaBold",
              fontSize: screenWidth / 18,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
