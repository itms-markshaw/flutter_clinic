import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

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

    final session = Map<String, dynamic>.from(sobj);
    // Handle user fetching logic here if needed

    c.setCurrentUser({
      'name': session['name'],
      'userLogin': session['userLogin'],
      'baseUrl': baseUrl,
      'sessionToken': session['session_sid'],
      'db': session['db']
    });
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> _appointments = [];
  List<dynamic> _filteredAppointments = [];
  bool _loading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  void _filterAppointments(String query) {
    setState(() {
      _filteredAppointments = _appointments.where((appointment) {
        final patientName = appointment['patient_id'] != null
            ? appointment['patient_id'][1].toLowerCase()
            : '';
        final appointmentDate = appointment['date'] != null
            ? DateTime.parse(appointment['date']).toLocal().toString().substring(0, 10)
            : '';
        return patientName.contains(query.toLowerCase()) || appointmentDate.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchAppointments() async {
    final prefs = SharedPref();
    final sobj = await prefs.readObject('session');
    _baseUrl = await prefs.readString('baseUrl') ?? '';

    if (sobj == null || _baseUrl.isEmpty) {
      print('Session or Base URL is null');
      return;
    }

    final session = Map<String, dynamic>.from(sobj);
    // Fetch appointments using session information

    try {
      // Simulate fetching appointments
      await Future.delayed(Duration(seconds: 2));
      // Replace the following with actual API call
      var res = [
        {
          'id': 1,
          'name': 'Appointment 1',
          'date': DateTime.now().add(Duration(days: 1)).toIso8601String(),
          'patient_id': [1, 'John Doe'],
          'mobile': '123456789',
          'age': '25',
          'email': 'john.doe@example.com'
        }
      ];

      setState(() {
        _appointments = res;
        _filteredAppointments = res;
        _loading = false;
      });

      print('Appointments response: $res');
    } catch (e) {
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

  void _launchCaller(String mobile) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: mobile,
    );
    await launch(launchUri.toString());
  }

  void _launchEmail(String email) async {
    final Uri launchUri = Uri(
      scheme: 'mailto',
      path: email,
    );
    await launch(launchUri.toString());
  }

  void _launchSMS(String mobile) async {
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: mobile,
    );
    await launch(launchUri.toString());
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
                        SessionInfoCard(),
                        const SizedBox(height: 10),
                      ],
                    );
                  }),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by patient or date',
                      hintStyle: TextStyle(color: Colors.white54),
                      prefixIcon: Icon(Icons.search, color: Colors.white54),
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: _filterAppointments,
                  ),
                  const SizedBox(height: 10),
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredAppointments.isEmpty
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
                                  ..._filteredAppointments.map((appointment) {
                                    final patientName = appointment['patient_id'] != null
                                        ? appointment['patient_id'][1]
                                        : 'No Patient';
                                    final date = appointment['date'] != null
                                        ? DateTime.parse(appointment['date']).toLocal().toString().substring(0, 16)
                                        : 'No Date';
                                    final mobile = appointment['mobile'] ?? 'N/A';
                                    final age = appointment['age'] ?? 'N/A';
                                    final email = appointment['email'] ?? 'N/A';

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
                                            Expanded(
                                              child: Column(
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
                                                    'Age: $age',
                                                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Mobile: $mobile',
                                                    style: const TextStyle(color: Colors.black87, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.phone, color: Colors.green),
                                                  onPressed: () {
                                                    _launchCaller(mobile);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.email, color: Colors.blue),
                                                  onPressed: () {
                                                    _launchEmail(email);
                                                  },
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.message, color: Colors.orange),
                                                  onPressed: () {
                                                    _launchSMS(mobile);
                                                  },
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

class SessionInfoCard extends StatefulWidget {
  @override
  _SessionInfoCardState createState() => _SessionInfoCardState();
}

class _SessionInfoCardState extends State<SessionInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _fetchSessionInfo(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (snapshot.hasData) {
          final sessionInfo = snapshot.data!;
          return Card(
            child: Column(
              children: [
                ListTile(
                  title: Text('Session Info'),
                  trailing: IconButton(
                    icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                  ),
                ),
                if (_isExpanded)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sessionInfo.entries.map((entry) {
                        return Text('${entry.key}: ${entry.value}');
                      }).toList(),
                    ),
                  ),
              ],
            ),
          );
        } else {
          return Text('No session info available');
        }
      },
    );
  }

  Future<Map<String, dynamic>?> _fetchSessionInfo() async {
    final prefs = SharedPref();
    final session = await prefs.readObject('session');
    return session != null ? Map<String, dynamic>.from(session) : null;
  }
}
