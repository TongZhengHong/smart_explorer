import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smart_explorer/main.dart';
import 'package:smart_explorer/subject_map.dart';
import 'package:smart_explorer/login_page.dart';
import 'dart:convert';
import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

const timeout = const Duration(seconds: 5);

class MainPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState(){
    return new MainPageState();
  }
}

void update(int index) async{
  String url = 'https://tinypingu.infocommsociety.com/subjectprogress';
  print(global.studentID);
      await http.post(url, body: {
        "ID": global.studentID
      },headers: {
        "cookie":global.cookie
      }
      ).then((dynamic response){
        if (response.statusCode == 200) {
          //_showDialog("Successful Login");
          print("Successful Data Transfer");
          Post temp = new Post.fromJson(json.decode(response.body));
          global.overallProgress[index] = temp.overallProgress;
          global.totalScore[index] = temp.tScore;
          print(global.overallProgress[index]);
          print(global.totalScore[index]);
        }
        else{
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
class MainPageState extends State<MainPage> {
  var _context;

  Widget _buildPage({int index}) {
    print("creating pages");
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
      appBar: AppBar(
        title: const Text("Smart Explorer"),
      ),
      body: PageView(
        onPageChanged: (index){
          global.subindex = index;
        },
        children: [
          _buildPage(index: 0),
          _buildPage(index: 1),
          _buildPage(index: 2),
          _buildPage(index: 3),          
        ],          
      ),
      floatingActionButtonLocation: 
        FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        child: Text(
          'Explore!',
          style: TextStyle(fontFamily: "Nunito", color: Colors.white),                    
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SubjectMap()),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        notchMargin: 4.0,
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            IconButton(icon: Icon(Icons.menu), onPressed: () {},),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                
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
                Route route = MaterialPageRoute(builder: (context) => LoginPage());
                Navigator.pushReplacement(context, route);
              },
            ),
          ],
        ),
      ),
    );
  }
}
