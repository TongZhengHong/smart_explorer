import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:smart_explorer/splash_screen.dart';
import 'package:smart_explorer/login_page.dart';
import 'package:smart_explorer/subject_map.dart';
import 'package:smart_explorer/subject_popup.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

//!Run splash screen on load!
void main() => runApp(Splash());

const timeout = const Duration(seconds: 5);

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return MainPageState();
  }
}

class MainPageState extends State<MainPage> {
  var _context;
  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    print(choice.title);
    if (choice.title == "Log out") {
      global.studentID = "";
      global.cookie = "";
      Route route = MaterialPageRoute(builder: (context) => LoginPage());
      Navigator.pushReplacement(context, route);
    }
    return;
  }

  Widget _buildPage({int index}) {
    void update(int index) async {
  String url = 'https://tinypingu.infocommsociety.com/subjectprogress';
  print(global.studentID);
  print("TONG IS SMART");
  print(global.cookie);
  await http.post(url,
      body: {"ID": global.studentID},
      headers: {"cookie": global.cookie}).then((dynamic response) {
    if (response.statusCode == 200) {
      //_showDialog("Successful Login");
      print("Successful Data Transfer");
      Post temp = Post.fromJson(json.decode(response.body));
      global.overallProgress[index] = temp.overallProgress;
      global.totalScore[index] = temp.tScore;
    }else{
      print(response.statusCode);
      print("hi2");
      print(":(");
      global.studentID = "";
      global.cookie = "";
      Route route = MaterialPageRoute(builder: (context) => LoginPage());
      Navigator.pushReplacement(context, route);
    }
  });
}
    update(index);
    print(global.overallProgress[index]);
    return Container(
      alignment: AlignmentDirectional.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            child: Text(
              global.subjects[index],
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: "Nunito", color: Colors.grey),
            ),
            //height: 200.0,
          ),
          Hero(
            tag: global.subjects[index],
            child: SizedBox(
              height: global.phoneHeight*0.4,
              width: global.phoneWidth*0.9,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SubjectPopup()),
                    );
                  },
                  borderRadius: BorderRadius.circular(24.0),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.keyboard_arrow_up,
                        color:Colors.grey,
                      ),
                      Text(
                        global.subjects[index],
                        style: TextStyle(fontFamily: "Nunito", fontSize: 30.0),
                      ),
                      Padding(
                        padding:EdgeInsets.fromLTRB(global.phoneWidth*0.30, 0, global.phoneWidth*0.30, 0),
                        child: Divider(
                          color : Colors.grey,
                        ),
                      ),
                      Padding(
                        padding:EdgeInsets.fromLTRB(global.phoneWidth*0.10, 0, global.phoneWidth*0.10, 0),
                        child: LinearPercentIndicator(
                          width: global.phoneWidth*0.60,
                          lineHeight: 8.0,
                          percent: global.overallProgress[index]/100,
                          progressColor: Colors.orange,
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(global.phoneWidth*0.10, global.phoneHeight*0.05, global.phoneWidth*0.10, 0),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              height: global.phoneWidth*0.20,
                              width: global.phoneWidth*0.20,
                              child: Container(
                                decoration: new BoxDecoration(
                                  border: new Border.all(color: Colors.blueAccent)
                                ),
                                child: Column(
                                  children: <Widget>[
                                    Text("hi"),
                                    Text("hi2")
                                  ],
                                )
                              ),
                            )
                          ],
                        )
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _context = context;
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0.0,
        title: Row(
          children: <Widget>[
            Padding(padding: EdgeInsets.only(left: 16.0),),
            Text("Studious", style: TextStyle(color: Colors.black, fontFamily: "Audiowide", fontSize: 24.0),),
          ],
        ),
        centerTitle: false,
      ),
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
      floatingActionButton: global.createGradientButton(
          global.blueGradient, 48, global.phoneWidth*0.5, context, SubjectMap(), "Explore!"),
      bottomNavigationBar: BottomAppBar(
        color: global.appBarLightBlue,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            PopupMenuButton<Choice>(
              icon: Icon(Icons.more_vert, color: Colors.grey.shade700,),
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
    );
  }
}



class Post {
  final double overallProgress;
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
