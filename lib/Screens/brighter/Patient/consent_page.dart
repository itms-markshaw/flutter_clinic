import 'package:flutter/material.dart';

class ConsentPage extends StatelessWidget {
  final int patientId;

  const ConsentPage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consents'),
      ),
      body: Center(
        child: Text('Consents for Patient ID: $patientId'),
      ),
    );
  }
}
