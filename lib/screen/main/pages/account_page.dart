import 'package:axion/screen/main/setting_page.dart';
import 'package:axion/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(Icons.settings),
              color: mainColor,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => SettingPage()),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Image.asset("assets/Group 162615.png", height: 120)),
          Text(
            "Ashutosh Pandey",
            style: GoogleFonts.workSans(
              color: Color(0xff1C1F34),
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          Text(
            "ashutosh@provider.com",
            style: GoogleFonts.workSans(
              color: Color(0xff6C757D),
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Text(
            "Digital goodies designer @pixsellz \n Everything is designed.",
            style: GoogleFonts.inter(
              color: black,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(
            height: 400,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: constraints.maxWidth > 700 ? 4 : 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: 4,
                  itemBuilder: (context, index) {
                    return Card(
                      color: Colors.amber,
                      child: Center(child: Text('$index')),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
