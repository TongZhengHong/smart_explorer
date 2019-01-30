import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/subject_map.dart';

import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

//!Run splash screen on load!
void main() => runApp(new Splash());

const timeout = const Duration(seconds: 5);

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return new MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  var _context;

  Widget _buildPage({int index}) {
    update(index);
    return Container(
      alignment: AlignmentDirectional.center,
      child: Text(
        global.subjects[index],
        style: TextStyle(fontFamily: "Nunito", color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      body: PageView(
        onPageChanged: (index) {
          global.subindex = index;
        },
        children: [
          _buildPage(index: 0),
          _buildPage(index: 1),
          _buildPage(index: 2),
          _buildPage(index: 3),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: new Container(
          height: 48.0,
          width: 180.0,
          child: new Material(
            borderRadius: BorderRadius.circular(24.0),
            shadowColor: Colors.lightBlueAccent,
            color: Colors.lightBlue,
            elevation: 4.0,
            child: new InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SubjectMap()),
                );
              },
              borderRadius: BorderRadius.circular(24.0),
              child: new Center(
                child: new Center(
                  child: new Text(
                    "Explore!",
                    style: new TextStyle(
                      fontFamily: "Nunito",
                      fontSize: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          )),
      bottomNavigationBar: BottomAppBar(
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            PopupMenuButton<Choice>(
              icon: new Icon(Icons.more_vert),
              onSelected: _select,
              offset: Offset(0, -120),
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                    value: choice,
                    child: Text(choice.title),
                  );
                }).toList();
              },
            ),
          ],
        ),
      ),
      drawer: Drawer(
        elevation: 20.0,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(global.studentName),
              accountEmail: Text(global.studentEmail),
              decoration: BoxDecoration(color: Colors.blueAccent),
            ),
            ListTile(
              leading: Icon(Icons.account_circle),
              title: Text('Logout'),
              onTap: () {
                print("hi");
                global.studentID = "";
                global.cookie = "";
                Route route =
                    MaterialPageRoute(builder: (context) => LoginPage());
                Navigator.pushReplacement(context, route);
              },
            ),
          ],
        ),
      ),
    );
  }
}

void update(int index) async {
  String url = 'https://tinypingu.infocommsociety.com/subjectprogress';
  print(global.studentID);
  await http.post(url,
      body: {"ID": global.studentID},
      headers: {"cookie": global.cookie}).then((dynamic response) {
    if (response.statusCode == 200) {
      //_showDialog("Successful Login");
      print("Successful Data Transfer");
      Post temp = new Post.fromJson(json.decode(response.body));
      global.overallProgress[index] = temp.overallProgress;
      global.totalScore[index] = temp.tScore;
    } else {
      print(response.statusCode);
      print(":(");
    }
  });
}

class Post {
  final int overallProgress;
  final int tScore;

  Post({this.overallProgress, this.tScore});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      overallProgress: json['percent'],
      tScore: json['score'],
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(title: 'Settings', icon: Icons.settings),
  const Choice(title: 'Log out', icon: Icons.power_settings_new),
];

void _select(Choice choice) {
  // Causes the app to rebuild with the new _selectedChoice.
  print(choice.title);
  // if (choice.title == "Log out") {
  //   global.studentID = "";
  //   global.cookie = "";
  //   Route route = MaterialPageRoute(builder: (context) => LoginPage());
  //   Navigator.pushReplacement(context, route);
  // }
  return;
}


