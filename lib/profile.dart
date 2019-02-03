import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return ProfilePageState();
  }
}

class ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
      ),
      body: Container(
        child: Center(
          child: Text("data"),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem> [
          BottomNavigationBarItem(icon: Icon(Icons.more_vert), title: Text("TESTING1")),
          BottomNavigationBarItem(icon: Icon(Icons.more_vert), title: Text("TESTING2")),
          BottomNavigationBarItem(icon: Icon(Icons.more_vert), title: Text("TESTING3"))
        ],
      )
    );
  }
}