import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:flutter_auth/shared_pref.dart';
import 'package:flutter_auth/constants.dart';

class TreatmentPage extends StatefulWidget {
  final int patientId;

  const TreatmentPage({Key? key, required this.patientId}) : super(key: key);

  @override
  _TreatmentPageState createState() => _TreatmentPageState();
}

class _TreatmentPageState extends State<TreatmentPage> {
  List<dynamic> _treatments = [];
  bool _loading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchTreatments();
  }

  Future<void> _fetchTreatments() async {
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
        'model': 'hms.treatment',
        'method': 'search_read',
        'args': [
          [
            ['patient_id', '=', widget.patientId]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['id', 'name', 'treatment_date', 'details'],
          'order': 'treatment_date desc',
        },
      });

      setState(() {
        _treatments = res;
        _loading = false;
      });

      print('Treatments response: $res');
    } catch (e) {
      client.close();
      print('Error fetching treatments: $e');
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

  void _addTreatment() {
    // Logic for adding a new treatment can be implemented here.
    // For now, we'll just show a message.
    print('Add new treatment');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatments'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addTreatment,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _treatments.isEmpty
              ? const Center(child: Text('No treatments found.'))
              : ListView.builder(
                  itemCount: _treatments.length,
                  itemBuilder: (context, index) {
                    final treatment = _treatments[index] as Map<String, dynamic>;
                    final treatmentId = treatment['id'] as int;
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(
                          treatment['name'] ?? 'No Name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.blue,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date: ${treatment['treatment_date'] ?? 'No Date'}',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              treatment['details'] ?? 'No Details',
                              style: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
