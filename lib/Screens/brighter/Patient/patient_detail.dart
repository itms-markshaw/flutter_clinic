import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_auth/constants.dart';
import 'package:flutter_auth/shared_pref.dart';
import 'package:odoo_rpc/odoo_rpc.dart';

class PatientDetail extends StatefulWidget {
  final int patientId;

  const PatientDetail({Key? key, required this.patientId}) : super(key: key);

  @override
  _PatientDetailState createState() => _PatientDetailState();
}

class _PatientDetailState extends State<PatientDetail> {
  Map<String, dynamic>? _patient;
  String? _lastNote;
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
          'fields': [
            'name', 'mobile', 'email', 'image_1920', 'street', 'city',
            'state_id', 'zip', 'gender', 'birthday', 'age', 'allergies_ids', 'primary_physician_id'
          ],
          'limit': 1,
        },
      });

      var noteRes = await client.callKw({
        'model': 'mail.message',
        'method': 'search_read',
        'args': [
          [
            ['res_id', '=', widget.patientId],
            ['model', '=', 'hms.patient']
          ]
        ],
        'kwargs': {
          'context': {'bin_size': true},
          'fields': ['body'],
          'order': 'date desc',
          'limit': 1,
        },
      });

      setState(() {
        if (res.isNotEmpty) {
          _patient = res[0];
        }
        if (noteRes.isNotEmpty) {
          _lastNote = noteRes[0]['body'];
        }
        _loading = false;
      });

      print('Patient detail response: $res');
      print('Patient last note response: $noteRes');
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

  void _launchCaller(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: mobile,
    );
    await launchUrl(launchUri);
  }

  void _launchWhatsApp(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'https',
      path: 'wa.me/$mobile',
    );
    await launchUrl(launchUri);
  }

  void _launchSMS(String? mobile) async {
    if (mobile == null || mobile.isEmpty) return;
    final Uri launchUri = Uri(
      scheme: 'sms',
      path: mobile,
    );
    await launchUrl(launchUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 72, 75, 199),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _patient == null
                ? const Center(child: Text('Patient not found.', style: TextStyle(color: Colors.white)))
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () {
                                Navigator.pop(context);
                              },
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage: _patient!['image_1920'] != null
                                      ? NetworkImage('$_baseUrl/web/image?model=hms.patient&id=${_patient!['id']}&field=image_1920')
                                      : null,
                                  child: _patient!['image_1920'] == null
                                      ? Text(
                                          _getInitials(_patient!['name']),
                                          style: const TextStyle(color: Colors.white, fontSize: 24),
                                        )
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _patient!['name'] ?? 'Unnamed',
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _patient!['mobile'] ?? 'No mobile number',
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _patient!['email'] ?? 'No email',
                                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.call, color: Colors.green),
                                      onPressed: () => _launchCaller(_patient!['mobile']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.message, color: Colors.blue),
                                      onPressed: () => _launchWhatsApp(_patient!['mobile']),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.sms, color: Colors.orange),
                                      onPressed: () => _launchSMS(_patient!['mobile']),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _buildDetailRow('Gender', _patient!['gender']?.toString()),
                                _buildDetailRow('Date of Birth', _patient!['birthday']?.toString()),
                                _buildDetailRow('Age', _patient!['age']?.toString()),
                                _buildDetailRow('Prescriber', _getFieldValue(_patient!['primary_physician_id'])),
                                _buildDetailRow('Allergies', _getAllergies(_patient!['allergies_ids'])),
                                _buildDetailRow('Address', _buildAddress(_patient!)),
                                if (_lastNote != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Card(
                                      color: Colors.white.withOpacity(0.1),
                                      child: ListTile(
                                        title: const Text('Notes', style: TextStyle(color: Colors.white)),
                                        subtitle: Text(_lastNote ?? '', style: const TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const BottomNavBar(),
                    ],
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
          Flexible(
            child: Text(
              value ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.white),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String _buildAddress(Map<String, dynamic> patient) {
    List<String> addressComponents = [
      patient['street'] ?? '',
      patient['city'] ?? '',
      _getFieldValue(patient['state_id']),
      patient['zip'] ?? '',
    ];
    return addressComponents.where((c) => c.isNotEmpty).join(', ');
  }

  String _getFieldValue(dynamic field) {
    if (field == null || field is! List || field.length < 2) {
      return '';
    }
    return field[1].toString();
  }

  String _getAllergies(dynamic allergies) {
    if (allergies == null || allergies is! List) {
      return 'None';
    }
    return allergies.map((a) => _getFieldValue(a)).join(', ');
  }

  String _getInitials(String name) {
    List<String> names = name.split(" ");
    String initials = "";
    for (var n in names) {
      if (n.isNotEmpty) {
        initials += n[0];
      }
    }
    return initials;
  }
}

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Patients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.local_hospital),
          label: 'TeleHealth',
        ),
      ],
      currentIndex: 1,
      selectedItemColor: Colors.amber[800],
      onTap: (index) {
        if (index == 0) {
          Get.toNamed('/home');
        } else if (index == 1) {
          Get.toNamed('/patientHome');
        } else if (index == 2) {
          Get.toNamed('/teleHealthHome');
        }
      },
    );
  }
}
