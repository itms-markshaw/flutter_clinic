import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

import '../../components/controllers.dart';
import '../../constants.dart';
import '../../shared_pref.dart';
import '../brighter/Appointment/appointment_detail.dart';

final Controller c = Get.find();

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    getUsers(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Odoo App',
      theme: ThemeData(
        fontFamily: "Cairo",
        scaffoldBackgroundColor: const Color.fromARGB(255, 72, 75, 199),
        textTheme: Theme.of(context).textTheme.apply(displayColor: kPrimaryColor),
      ),
      home: const HomeScreen(),
    );
  }

  void getUsers(context) async {
    final prefs = SharedPref();
    final sobj = await prefs.readObject('session');
    var baseUrl = await prefs.readString('baseUrl');

    if (sobj == null || baseUrl == null) {
      print('Session or Base URL is null');
      return;
    }

    print('Session: $sobj');
    print('Base URL: $baseUrl');

    final session = OdooSession.fromJson(sobj);
    final client = OdooClient(baseUrl, session);
    try {
      var res = await client.callKw({
        'model': 'res.users',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [
            ['id', '=', session.userId]
          ],
          'fields': ['id', 'name', '__last_update'],
        },
      });

      print('User response: $res');

      if (res.isNotEmpty) {
        c.setCurrentUser(res[0]);
        print('User data set in controller: ${c.currentUser.value}');
      } else {
        print('No user found with the given ID');
      }
    } catch (e) {
      client.close();
      print('Error fetching user data: $e');
      showDialog(context: context, builder: (context) {
        return SimpleDialog(
          children: <Widget>[
            Center(child: Text(e.toString()))
          ],
        );
      });
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _appointments = [];
  bool _loading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    final prefs = SharedPref();
    final sobj = await prefs.readObject('session');
    _baseUrl = await prefs.readString('baseUrl') ?? '';

    if (sobj == null || _baseUrl.isEmpty) {
      print('Session or Base URL is null');
      return;
    }

    final session = OdooSession.fromJson(sobj);
    final client = OdooClient(_baseUrl, session);
    try {
      var res = await client.callKw({
        'model': 'hms.appointment',
        'method': 'search_read',
        'args': [
          [
            ['date', '>', DateTime.now().toIso8601String()]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['id', 'name', 'date', 'patient_id', 'mobile'],
          'order': 'date asc',
          'limit': 3,
        },
      });

      setState(() {
        _appointments = res;
        _loading = false;
      });

      print('Appointments response: $res');
    } catch (e) {
      client.close();
      print('Error fetching appointments: $e');
      showDialog(
        context: context,
        builder: (context) {
          return SimpleDialog(
            children: <Widget>[
              Center(child: Text(e.toString()))
            ],
          );
        },
      );
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Get.toNamed('/patientHome');
    } else if (index == 1) {
      Get.toNamed('/teleHealthHome');
    }
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size; // this gonna give us total height and width of our device
    return Scaffold(
      body: Stack(
        children: <Widget>[
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 20),
                  Obx(() {
                    final user = c.currentUser.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome ${user['name'] ?? 'User'}",
                          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _appointments.isEmpty
                          ? const Center(child: Text('No appointments found.', style: TextStyle(color: Colors.white)))
                          : Expanded(
                              child: ListView(
                                children: [
                                  const Text(
                                    "Upcoming Appointments",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ..._appointments.map((appointment) {
                                    final patientName = appointment['patient_id'] != null
                                        ? appointment['patient_id'][1]
                                        : 'No Patient';
                                    final date = appointment['date'] != null
                                        ? DateTime.parse(appointment['date']).toLocal().toString().substring(0, 16)
                                        : 'No Date';
                                    return GestureDetector(
                                      onTap: () {
                                        Get.to(AppointmentDetail(appointmentId: appointment['id']));
                                      },
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: const Color.fromARGB(255, 72, 75, 199),
                                              child: const Icon(Icons.calendar_today, color: Colors.white),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  appointment['name'],
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Patient: $patientName',
                                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Date: $date',
                                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Mobile: ${appointment['mobile'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Patient',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.health_and_safety),
            label: 'TeleHealth',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }
}

class Body extends StatelessWidget {
  const Body({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              "Welcome",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w100, color: Colors.white),
            ),
            Obx(() {
              final user = c.currentUser.value;
              print('User data in Obx: $user');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${user['name'] ?? 'NULL'}",
                    style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: Colors.white),
                  ),
                ],
              );
            }),
            Expanded(
              child: Container(), // Placeholder for GridMenu removed
            ),
          ],
        ),
      ),
    );
  }
}
