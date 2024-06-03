import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TeleHealthHome extends StatelessWidget {
  const TeleHealthHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Doctor'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Test Doctor'),
            onTap: () {
              const url = 'https://main.brighterapn.com/chat/145/s3oMWoh57C';
              _launchURL(url);
            },
          ),
        ],
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
