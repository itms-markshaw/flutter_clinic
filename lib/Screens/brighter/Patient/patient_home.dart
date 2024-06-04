import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:flutter_auth/shared_pref.dart';
import 'package:flutter_auth/constants.dart';
import 'package:flutter_auth/Screens/brighter/Patient/patient_detail.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 72, 75, 199),
      body: SafeArea(
        child: Column(
          children: const [
            Header(),
            Expanded(
              child: PatientList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class Header extends StatelessWidget {
  const Header({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: const [
          Icon(Icons.contacts, color: Colors.white, size: 24),
          Text(
            'Contacts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class PatientList extends StatefulWidget {
  const PatientList({Key? key}) : super(key: key);

  @override
  _PatientListState createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  List<dynamic> _patients = [];
  List<dynamic> _filteredPatients = [];
  bool _loading = true;
  late String _baseUrl;
  Set<int> _favoritePatients = Set<int>();

  @override
  void initState() {
    super.initState();
    _fetchPatients();
  }

  void _filterPatients(String query) {
    setState(() {
      _filteredPatients = _patients.where((patient) {
        final patientName = patient['name'].toLowerCase();
        return patientName.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _fetchPatients() async {
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
        'model': 'hms.patient',
        'method': 'search_read',
        'args': [],
        'kwargs': {
          'context': {'bin_size': true},
          'domain': [],
          'fields': ['name', 'mobile', 'image_1920'],
          'order': 'name asc',  // Sort alphabetically by name
        },
      });

      setState(() {
        _patients = res;
        _filteredPatients = res;
        _loading = false;
      });

      print('Patients response: $res');
    } catch (e) {
      client.close();
      print('Error fetching patient data: $e');
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

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    for (var n in names) {
      if (n.isNotEmpty) {
        initials += n[0];
      }
    }
    return initials;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search patients',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color.fromARGB(255, 72, 75, 199),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: _filterPatients,
          ),
        ),
        if (_loading)
          const Center(child: CircularProgressIndicator())
        else if (_filteredPatients.isEmpty)
          const Center(child: Text('No patients found.', style: TextStyle(color: Colors.white)))
        else
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index] as Map<String, dynamic>;
                final imageUrl = patient['image_1920'] != null
                    ? '$_baseUrl/web/image?model=hms.patient&id=${patient['id']}&field=image_1920'
                    : null;
                final imageWidget = (imageUrl != null)
                    ? CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(imageUrl),
                      )
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: kPrimaryColor,
                        child: Text(
                          _getInitials(patient['name'] ?? 'U'),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      );

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                  leading: imageWidget,
                  title: Text(
                    patient['name'] ?? 'Unnamed',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                  ),
                  onTap: () {
                    // Navigate to the patient detail page
                    Get.to(() => PatientDetail(patientId: patient['id']));
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Get.toNamed('/home');
    } else if (index == 1) {
      Get.toNamed('/patientHome');
    } else if (index == 2) {
      Get.toNamed('/teleHealthHome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
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
    );
  }
}
