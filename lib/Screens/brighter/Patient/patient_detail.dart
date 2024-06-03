import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:flutter_auth/shared_pref.dart';
import 'package:flutter_auth/constants.dart';
import 'prescription_page.dart'; // Placeholder for prescription page
import 'treatment_page.dart'; // Placeholder for treatment page
import 'appointment_page.dart'; // Placeholder for appointment page
import 'invoice_page.dart'; // Placeholder for invoice page
import 'consent_page.dart'; // Placeholder for consent page

class PatientDetail extends StatefulWidget {
  final int patientId;

  const PatientDetail({Key? key, required this.patientId}) : super(key: key);

  @override
  _PatientDetailState createState() => _PatientDetailState();
}

class _PatientDetailState extends State<PatientDetail> {
  Map<String, dynamic>? _patient;
  bool _loading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchPatientDetail();
  }

  Future<void> _fetchPatientDetail() async {
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
        'args': [
          [
            ['id', '=', widget.patientId]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['name', 'code', 'gender', 'email', 'birthday', 'age', 'image_1920'],
        },
      });

      setState(() {
        if (res.isNotEmpty) {
          _patient = res[0];
        }
        _loading = false;
      });

      print('Patient detail response: $res');
    } catch (e) {
      client.close();
      print('Error fetching patient detail: $e');
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_patient?['name'] ?? 'Patient Detail'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _patient == null
              ? const Center(child: Text('Patient not found.'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: <Widget>[
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _buildNavigationButton('Prescriptions', Icons.medical_services, () {
                            Get.to(() => PrescriptionPage(patientId: widget.patientId));
                          }),
                          _buildNavigationButton('Treatments', Icons.local_hospital, () {
                            Get.to(() => TreatmentPage(patientId: widget.patientId));
                          }),
                          _buildNavigationButton('Appointments', Icons.calendar_today, () {
                            Get.to(() => AppointmentPage(patientId: widget.patientId));
                          }),
                          _buildNavigationButton('Invoices', Icons.receipt_long, () {
                            Get.to(() => InvoicePage(patientId: widget.patientId));
                          }),
                          _buildNavigationButton('Consent', Icons.description, () {
                            Get.to(() => ConsentPage(patientId: widget.patientId));
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_patient!['image_1920'] != null)
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              height: 150,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    '$_baseUrl/web/image?model=hms.patient&id=${widget.patientId}&field=image_1920',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildDetailCard('Name', _patient!['name']),
                      _buildDetailCard('Code', _patient!['code']),
                      _buildDetailCard('Gender', _patient!['gender']),
                      _buildDetailCard('Email', _patient!['email']),
                      _buildDetailCard('Birthday', _patient!['birthday']),
                      _buildDetailCard('Age', _patient!['age'].toString()),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNavigationButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: 100, // Wider buttons
      height: 80,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10), // Smaller font size
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, String? value) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              value ?? 'N/A',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
