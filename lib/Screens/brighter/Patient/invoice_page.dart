import 'package:flutter/material.dart';

class InvoicePage extends StatelessWidget {
  final int patientId;

  const InvoicePage({Key? key, required this.patientId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
      ),
      body: Center(
        child: Text('Invoices for Patient ID: $patientId'),
      ),
    );
  }
}
