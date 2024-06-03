import 'package:flutter/material.dart';

class AppointmentPage extends StatelessWidget {
  final int patientId;

  const AppointmentPage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appointments'),
      ),
      body: Center(
        child: Text('Appointments for Patient ID: $patientId'),
      ),
    );
  }
}
