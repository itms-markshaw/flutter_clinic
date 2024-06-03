import 'package:flutter/material.dart';

class PrescriptionHome extends StatelessWidget {
  const PrescriptionHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
      ),
      body: const Center(
        child: Text('Prescription Home'),
      ),
    );
  }
}
