import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_auth/Screens/brighter/Patient/patient_home.dart';
import 'package:flutter_auth/Screens/brighter/TeleHealth/telehealth_home.dart';
import 'package:flutter_auth/Screens/brighter/Prescription/prescription_home.dart';
import 'package:flutter_auth/Screens/brighter/Treatment/treatment_home.dart';
import 'package:flutter_auth/Screens/Welcome/welcome_screen.dart';
import 'package:flutter_auth/constants.dart';
import 'package:flutter_auth/graphql_service.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'Screens/Home/home.dart';
import 'components/controllers.dart';
import 'odoo_session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize GraphQL client
  final GraphQLClient client = await GraphQLService.initClient();
  
  runApp(MyApp(client: client));
}

class MyApp extends StatelessWidget {
  final GraphQLClient client;

  const MyApp({Key? key, required this.client}) : super(key: key);

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
            vertical: defaultPadding,
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
