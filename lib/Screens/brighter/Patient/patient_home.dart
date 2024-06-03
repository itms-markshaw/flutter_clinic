import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:flutter_auth/shared_pref.dart';
import 'package:flutter_auth/constants.dart';
import 'package:flutter_auth/Screens/brighter/Patient/patient_detail.dart';

class PatientHome extends StatelessWidget {
  const PatientHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      body: const PatientList(),
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
  bool _loading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchPatients();
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
          'fields': ['name', 'image_1920'],
          'order': 'name asc',  // Sort alphabetically by name
        },
      });

      setState(() {
        _patients = res;
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_patients.isEmpty) {
      return const Center(child: Text('No patients found.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      itemCount: _patients.length,
      itemBuilder: (context, index) {
        final patient = _patients[index] as Map<String, dynamic>;
        final imageUrl = patient['image_1920'] != null
            ? '$_baseUrl/web/image?model=hms.patient&id=${patient['id']}&field=image_1920'
            : null;
        final imageWidget = (imageUrl != null)
            ? Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: NetworkImage(imageUrl),
                  ),
                ),
              )
            : const CircleAvatar(
                radius: 40, // Larger placeholder
                backgroundColor: kPrimaryColor,
                child: Icon(Icons.person, color: Colors.white, size: 40),
              );

        return Padding(
          key: ValueKey(patient['id']),
          padding: const EdgeInsets.symmetric(vertical: 5), // Less vertical spacing
          child: Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(10),
              leading: imageWidget,
              title: Text(
                patient['name'] ?? 'Unnamed',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                // Navigate to the patient detail page
                Get.to(() => PatientDetail(patientId: patient['id']));
              },
            ),
          ),
        );
      },
    );
  }
}
