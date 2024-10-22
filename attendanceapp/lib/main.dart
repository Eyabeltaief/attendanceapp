import 'package:attendanceapp/model/user.dart' as local_user;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:attendanceapp/loginscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attendanceapp/screenhome.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: FirebaseOptions(
    apiKey: "AIzaSyA5MRACQw23nKgNtp_LhR5hkPt4ZF8btXk",
    appId: "1:75858592860:android:56d59d653bd5122df49299",
    messagingSenderId: "75858592860",
    projectId: "app-attendance1",
  ));

  runApp(const MyApp());
}

Future<void> _signOut() async {
  auth.FirebaseAuth authInstance = auth.FirebaseAuth.instance;
  await authInstance.signOut(); // Déconnexion forcée
  // Aucune réauthentification automatique
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home:LoginScreen(),
      localizationsDelegates: const [
        MonthYearPickerLocalizations
            .delegate, // Nécessaire pour le sélecteur de mois
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'), // Ajouter d'autres locales si nécessaire
      ],
    );
  }
}

// Vérification de la disponibilité de l'utilisateur à partir des SharedPreferences
class AuthCheck extends StatefulWidget {
  const AuthCheck({Key? key}) : super(key: key);

  @override
  _AuthCheckState createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool userAvailable = false;
  late SharedPreferences sharedPreferences;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  void _getCurrentUser() async {
    sharedPreferences = await SharedPreferences.getInstance();
    try {
      if (sharedPreferences.getString('employeeId') != null) {
        setState(() {
          local_user.User.employeeid = sharedPreferences.getString('employeeId')!;
          auth.User? currentUser = auth.FirebaseAuth.instance.currentUser;
          userAvailable = true;
        });
      }
    } catch (e) {
      setState(() {
        userAvailable = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return userAvailable ? const HomeScreen() : const LoginScreen();
  }
}
