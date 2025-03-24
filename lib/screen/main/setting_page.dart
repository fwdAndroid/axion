import 'package:axion/screen/auth/login_screen.dart';
import 'package:axion/utils/colors.dart';
import 'package:flutter/material.dart';

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text("Settings")),
      body: Column(
        children: [
          Image.asset("assets/logo.png", height: 200, fit: BoxFit.cover),
          Card(
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Favourite"),
              leading: Icon(Icons.favorite),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Payments"),
              leading: Icon(Icons.payment),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Notifications"),
              leading: Icon(Icons.notifications),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Edit Profile"),
              leading: Icon(Icons.person),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Language"),
              leading: Icon(Icons.language),
            ),
          ),
          Card(
            child: ListTile(
              trailing: Icon(Icons.arrow_forward_ios),
              title: Text("Invite Friends"),
              leading: Icon(Icons.share),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: ElevatedButton(
                onPressed: () async {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // <-- Radius
                  ),
                  backgroundColor: mainColor,
                  fixedSize: const Size(320, 60),
                ),
                child: Text("Log Out", style: TextStyle(color: colorWhite)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
