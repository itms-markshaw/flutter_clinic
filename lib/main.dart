import 'package:flutter/material.dart';
import 'package:flutter_auth/Screens/brighter/Patient/patient_home.dart';
import 'package:flutter_auth/Screens/brighter/TeleHealth/telehealth_home.dart';
import 'package:flutter_auth/Screens/brighter/Prescription/prescription_home.dart'; // Fixed this line
import 'package:flutter_auth/Screens/brighter/Treatment/treatment_home.dart';
import 'package:flutter_auth/Screens/Welcome/welcome_screen.dart';
import 'package:flutter_auth/constants.dart';
import 'package:get/get.dart';
import 'Screens/Home/home.dart';
import 'components/controllers.dart';
import 'odoo_session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure Flutter is initialized
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Controller c = Get.put(Controller());
    final OdooSessionManager _sessionManager = OdooSessionManager();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth',
      theme: ThemeData(
        primaryColor: kPrimaryColor,
        scaffoldBackgroundColor: Colors.white,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: kPrimaryColor,
            shape: const StadiumBorder(),
            maximumSize: const Size(double.infinity, 56),
            minimumSize: const Size(double.infinity, 56),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: kPrimaryLightColor,
          iconColor: kPrimaryColor,
          prefixIconColor: kPrimaryColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: defaultPadding, 
            vertical: defaultPadding
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(30)),
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: _sessionManager.isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasData && snapshot.data == true) {
            return const Home();
          } else {
            return const WelcomeScreen();
          }
        },
      ),
      getPages: [
        GetPage(name: '/home', page: () => const Home()),
        GetPage(name: '/patientHome', page: () => const PatientHome()),
        GetPage(name: '/teleHealthHome', page: () => const TeleHealthHome()),
        GetPage(name: '/prescriptionHome', page: () => const PrescriptionHome()),
        GetPage(name: '/treatmentHome', page: () => const TreatmentHome()),
      ],
    );
  }
}

class LoginPage extends StatelessWidget {
  final OdooSessionManager _sessionManager = OdooSessionManager();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dbNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _dbNameController,
              decoration: InputDecoration(labelText: 'Database Name'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _sessionManager.login(
                    _dbNameController.text,
                    _usernameController.text,
                    _passwordController.text,
                  );
                  Get.offNamed('/home');
                } catch (e) {
                  Get.snackbar('Error', 'Login failed');
                }
              },
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  final OdooSessionManager _sessionManager = OdooSessionManager();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _sessionManager.logout();
              Get.offAllNamed('/welcome');
            },
          ),
        ],
      ),
      body: Center(
        child: Text('Welcome to Odoo!'),
      ),
    );
  }
}
