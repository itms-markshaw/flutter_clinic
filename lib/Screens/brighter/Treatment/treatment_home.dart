import 'package:flutter/material.dart';

class TreatmentHome extends StatelessWidget {
  const TreatmentHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Treatment'),
      ),
      body: const Center(
        child: Text('Treatment Home'),
      ),
    );
  }
}
