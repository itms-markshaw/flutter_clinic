import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import 'package:flutter_auth/shared_pref.dart';
import 'package:flutter_auth/constants.dart';

class PrescriptionPage extends StatefulWidget {
  final int patientId;

  const PrescriptionPage({Key? key, required this.patientId}) : super(key: key);

  @override
  _PrescriptionPageState createState() => _PrescriptionPageState();
}

class _PrescriptionPageState extends State<PrescriptionPage> {
  List<dynamic> _prescriptions = [];
  bool _loading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptions();
  }

  Future<void> _fetchPrescriptions() async {
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
        'model': 'prescription.order',
        'method': 'search_read',
        'args': [
          [
            ['patient_id', '=', widget.patientId]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['id', 'name', 'prescription_date', 'first_product_id'],
          'order': 'prescription_date desc',
        },
      });

      setState(() {
        _prescriptions = res;
        _loading = false;
      });

      print('Prescriptions response: $res');
    } catch (e) {
      client.close();
      print('Error fetching prescriptions: $e');
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

  Future<List<dynamic>> _fetchPrescriptionLines(int prescriptionId) async {
    final prefs = SharedPref();
    final sobj = await prefs.readObject('session');
    final baseUrl = await prefs.readString('baseUrl') ?? '';

    if (sobj == null || baseUrl.isEmpty) {
      print('Session or Base URL is null');
      return [];
    }

    final session = OdooSession.fromJson(sobj);
    final client = OdooClient(baseUrl, session);
    try {
      var res = await client.callKw({
        'model': 'prescription.line',
        'method': 'search_read',
        'args': [
          [
            ['prescription_id', '=', prescriptionId]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['name', 'display_name', 'dose', 'quantity', 'medicine_area', 'medicine_depth', 'medicine_method', 'medicine_technique', 'expiration_batch_date'],
        },
      });
      return res;
    } catch (e) {
      client.close();
      print('Error fetching prescription lines: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescriptions'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _prescriptions.isEmpty
              ? const Center(child: Text('No prescriptions found.'))
              : ListView.builder(
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = _prescriptions[index] as Map<String, dynamic>;
                    final prescriptionId = prescription['id'] as int;
                    return FutureBuilder<List<dynamic>>(
                      future: _fetchPrescriptionLines(prescriptionId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return const Center(child: Text('Error loading details'));
                        }
                        final lines = snapshot.data ?? [];
                        return Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          margin: const EdgeInsets.all(10),
                          child: ExpansionTile(
                            backgroundColor: Colors.lightBlue[50],
                            title: Text(
                              prescription['name'] ?? 'No Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.blue,
                              ),
                            ),
                            subtitle: Text(
                              'Product: ${prescription['first_product_id'] ?? 'No Product'}\nDate: ${prescription['prescription_date'] ?? 'No Date'}',
                              style: const TextStyle(color: Colors.blueGrey),
                            ),
                            children: lines.map<Widget>((line) {
                              return ListTile(
                                title: Text(
                                  line['display_name'] ?? 'No Display Name',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 5),
                                    Text(
                                      'Dose: ${line['dose'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      'Quantity: ${line['quantity'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      'Area: ${line['medicine_area'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      'Depth: ${line['medicine_depth'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      'Method: ${line['medicine_method'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      'Technique: ${line['medicine_technique'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                    Text(
                                      'Expiry Date: ${line['expiration_batch_date'] ?? 'N/A'}',
                                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                                    ),
                                  ],
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                tileColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
