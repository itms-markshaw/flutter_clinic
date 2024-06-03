import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:odoo_rpc/odoo_rpc.dart';
import '../../../shared_pref.dart';

class AppointmentDetail extends StatelessWidget {
  final int appointmentId;

  const AppointmentDetail({Key? key, required this.appointmentId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointment Details'),
        backgroundColor: const Color.fromARGB(255, 72, 75, 199),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchAppointmentDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No details found.'));
          } else {
            final appointment = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailCard('Patient', appointment['patient_id']?[1] ?? 'N/A'),
                  _buildDetailCard('Date', appointment['date']?.toString() ?? 'N/A'),
                  _buildDetailCard('Mobile', appointment['mobile'] ?? 'N/A'),
                  const SizedBox(height: 20),
                  const Text('Stages', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildStageButton(context, 'Consent Forms', 'consent.consent', appointment['consent_ids'], Icons.assignment),
                  _buildStageButton(context, 'Medical Checklist', 'medical.checklist', appointment['medical_checklist_answer_ids'], Icons.checklist),
                  _buildStageButton(context, 'Prescription', 'prescription.order', appointment['prescription_ids'], Icons.receipt),
                  _buildStageButton(context, 'Treatment', 'hms.treatment', appointment['treatment_ids'], Icons.local_hospital),
                  _buildStageButton(context, 'Aftercare', 'aftercare.model', appointment['aftercare_ids'], Icons.health_and_safety),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _fetchAppointmentDetails() async {
    final prefs = SharedPref();
    final sobj = await prefs.readObject('session');
    final baseUrl = await prefs.readString('baseUrl');

    if (sobj == null || baseUrl == null) {
      throw Exception('Session or Base URL is null');
    }

    final session = OdooSession.fromJson(sobj);
    final client = OdooClient(baseUrl, session);
    try {
      final res = await client.callKw({
        'model': 'hms.appointment',
        'method': 'search_read',
        'args': [
          [
            ['id', '=', appointmentId]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': [
            'id', 'name', 'date', 'patient_id', 'mobile', 'consent_ids',
            'medical_checklist_answer_ids', 'prescription_ids', 'treatment_ids', 'aftercare_ids'
          ],
        },
      });
      if (res.isNotEmpty) {
        return res[0];
      }
      return {};
    } catch (e) {
      client.close();
      throw Exception('Error fetching appointment details: $e');
    }
  }

  Widget _buildDetailCard(String title, String value) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildStageButton(BuildContext context, String title, String model, List<dynamic> ids, IconData icon) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color.fromARGB(255, 72, 75, 199)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () {
          // Navigate to a page that lists items of the model with the given ids
          Get.to(() => StageDetailPage(model: model, ids: ids));
        },
      ),
    );
  }
}

class StageDetailPage extends StatelessWidget {
  final String model;
  final List<dynamic> ids;

  const StageDetailPage({Key? key, required this.model, required this.ids}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(model.replaceAll('.', ' ').capitalizeFirst!),
        backgroundColor: const Color.fromARGB(255, 72, 75, 199),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _fetchStageDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No details found.'));
          } else {
            final items = snapshot.data!;
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  title: Text(item['display_name'] ?? 'No Name'),
                  subtitle: Text(item.toString()),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<List<dynamic>> _fetchStageDetails() async {
    final prefs = SharedPref();
    final sobj = await prefs.readObject('session');
    final baseUrl = await prefs.readString('baseUrl');

    if (sobj == null || baseUrl == null) {
      throw Exception('Session or Base URL is null');
    }

    final session = OdooSession.fromJson(sobj);
    final client = OdooClient(baseUrl, session);
    try {
      final res = await client.callKw({
        'model': model,
        'method': 'search_read',
        'args': [
          [
            ['id', 'in', ids]
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['id', 'display_name'],
        },
      });
      return res;
    } catch (e) {
      client.close();
      throw Exception('Error fetching stage details: $e');
    }
  }
}
