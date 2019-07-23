import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:html/dom.dart' as dom;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:http/http.dart' as http;

import 'internet.dart';

ConnectionStatusSingleton connectionStatus;

const _wrongPrompt = "Oh no!";
const _correctPrompt = "Good job!";
const _nextQuestionPrompt = "Swipe to the next question!";
const _chooseOptionPrompt = "Choose the best option!";

const _activityAppBarHeight = 64.0; //? Extended height for app bar
const _extraStatusBarHeight = 10.0; //? Extra height between the appbar and status bar
const _promptTextHeight = 28.0; //? Height of prompt text

//? Dots variables
const _dotsHeight = 22.0; //? Height for the horizontal row of question dot indicators
double _dotsContainerWidth = global.phoneWidth * 0.5;
const _dotsPadding = 12.0;
const _bigDotDiameter = 16.0;
const _smallDotDiameter = 12.0;

double _customPaintHeight = global.phoneHeight * 0.5;
double _questionCardMinHeight = global.phoneHeight * 0.25;
double _questionCardMaxHeight = global.phoneHeight * 0.70;
double _questionCardWidth = global.phoneWidth * 0.86;

const animDuration = Duration(milliseconds: 300);

class McqPage extends StatefulWidget {
  final int actId;
  final pageData;
  final userData;
  final title;
  final maxScore;

  McqPage({this.actId, this.pageData, this.userData, this.title, this.maxScore});

  @override
  State<StatefulWidget> createState() {
    return McqPageState();
  }
}

class McqPageState extends State<McqPage> {
  List questions;
  List<Map> options;
  List reasons;
  Map questionNo = {};     //? Maps each page number to the question number

  int score;          //? Keeps track of the score of the user
  int questionCount;  //? Number of questions
  int currentPage;    //? Keeps track of the current page

  PageController _question_controller;
  PageController _options_controller;
  ScrollController _dots_controller;

  String promptText = "";
  String _expandText = "Show more";

  bool dotSwipe = false;
  bool questionOpen = false;
  bool _completed = false;
  bool _marked = true;
  bool _submitLoading = false;

  double _questionCardHeight = _questionCardMinHeight;
  double _backgroundOpacity = 0.0;
  double _submitOpacity = 0.0;

  Icon _correctIcon; 
  Icon _wrongIcon;

  void _toggleQuestionCard() {
    setState(() {
      questionOpen = !questionOpen;
      _questionCardHeight = (questionOpen) ? _questionCardMaxHeight : _questionCardMinHeight; 
      _backgroundOpacity = (questionOpen) ? 1.0 : 0.0;
      _expandText = (questionOpen) ? "Show less" : "Show more";
    });
  }

  void _centerDotIndicator() {
    if ((_bigDotDiameter + _dotsPadding) * (questionNo[currentPage]-1) + (_bigDotDiameter + _dotsPadding)/2 - _dotsContainerWidth/2 + _dotsHeight > _dots_controller.position.minScrollExtent - _smallDotDiameter/2
      && (_bigDotDiameter + _dotsPadding) * (questionNo[currentPage]-1) + (_bigDotDiameter + _dotsPadding)/2 - _dotsContainerWidth/2 + _dotsHeight < _dots_controller.position.maxScrollExtent + _smallDotDiameter/2) {
      _dots_controller.animateTo(
        (_bigDotDiameter + _dotsPadding) * (questionNo[currentPage]-1) + (_bigDotDiameter + _dotsPadding)/2 - _dotsContainerWidth/2 + _dotsHeight,
        duration: animDuration,
        curve: Curves.ease
      );
    } else {
      if ((_bigDotDiameter + _dotsPadding) * (questionNo[currentPage]-1) < _dots_controller.offset) {
        _dots_controller.animateTo(_dots_controller.position.minScrollExtent, duration: animDuration, curve: Curves.ease);
      } else if ((_bigDotDiameter + _dotsPadding) * questionNo[currentPage] - _dots_controller.position.viewportDimension > _dots_controller.offset) {
        _dots_controller.animateTo(_dots_controller.position.maxScrollExtent, duration: animDuration, curve: Curves.ease);
      }
    }
  }

  void _updatePromptText() {
    promptText = (options[currentPage]["submitted"]) 
      ? (options[currentPage]["choice"] == options[currentPage]["correct"]) 
        ? _correctPrompt
        : _wrongPrompt
      : (options[currentPage]["choice"] == -1) 
        ? _chooseOptionPrompt
        : _nextQuestionPrompt;
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          actions: <Widget>[
            FlatButton(
              child: Text("OKAY"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showReasonDialog(String question, String reason) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: animDuration,
      barrierDismissible: true,
      barrierLabel: 'barrier',
      pageBuilder: (context, animation1, animation2) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
          contentPadding: EdgeInsets.all(16.0),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: global.phoneHeight * 0.5
            ),
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(question, style: TextStyle(color: global.amber, fontFamily: "PoppinsSemiBold"),),
                  ),
                  Text(reason)
                ],
              )
            ),
          )
        );
      },
      transitionBuilder: (context, anim1, anim2, widget) {
        return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(anim1),
            child: widget
          );
      },
    );
  }

  void _showSubmitDialog(String title, String content) {
    showGeneralDialog(
      barrierColor: Colors.black.withOpacity(0.5),
      context: context,
      transitionDuration: animDuration,
      barrierDismissible: true,
      barrierLabel: 'barrier',
      pageBuilder: (context, animation1, animation2) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8.0))),
          actions: <Widget>[
            FlatButton(
              child: Text((_completed) ? "CANCEL" : "CLOSE", style: TextStyle(fontFamily: "PoppinsSemiBold")),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            (_completed) 
              ? FlatButton(
                child: Text("SUBMIT", style: TextStyle(fontFamily: "PoppinsSemiBold")),
                onPressed: () {
                  int count = 0;
                  var tempData = widget.userData;
                  options.forEach((question) {
                    if (question != null) {
                      tempData[count]["score"] = 
                      (question["choice"] == question["correct"]) 
                        ? question["maxScore"] 
                        : 0.0;
                      tempData[count]["answer"] = question["choice"];
                      count++;
                    }
                  });
                  setState(() {
                    _submitLoading = true;
                  });
                  sendAttempt(tempData);
                },
              )
              : Container(),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, widget) {
        return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(anim1),
            child: widget
          );
      },
    );
  }

  void sendAttempt(List attData) async {
    double totalScore = 0.0;
    print(attData);
    if (!await connectionStatus.checkConnection()) { //If not connected!
      print("MCQ submit: Not connected!");
      _showDialog("Oh no!",
          "Something went wrong! Please check your Internet connection!");
      setState(() {
        _submitLoading = false;
      });
      return;
    }

    //! Compute score:
    attData.forEach((question) {
      totalScore += question["score"].toDouble() ?? 0.0;
    });

    final String mapUrl = "https://tinypingu.infocommsociety.com/api/submit-activity";
    await http.post(mapUrl,
        headers: {"Cookie": global.cookie, "Content-Type": "application/json"},
        body: json.encode({"activityId": widget.actId, "data": attData})).then((dynamic response) {
      // print(json.encode({"activityId": widget.actId, "data": attData}));
      if (response.statusCode == 200) {
        print("Send Attempt: Success!");
        Route route = MaterialPageRoute(
            builder: (context) => SubmittedMCQ(
              actId: widget.actId,
              title: widget.title,
              score: totalScore,
              maxScore: widget.maxScore,
            ));
        Navigator.pop(context);
        Navigator.pushReplacement(context, route);
      } else {
        print("Send Attempt: Error! Attempt data not retrieved!");
      }
    });
  }

  @override
  void initState() {
    super.initState();

    connectionStatus = ConnectionStatusSingleton.getInstance();

    _correctIcon = Icon(Icons.done, size: 12.0, color: Colors.white);
    _wrongIcon = Icon(Icons.close, size: 12.0, color: Colors.white);

    score = 0;
    questionCount = 0;
    currentPage = 0;

    _question_controller = PageController();
    _options_controller = PageController();
    _dots_controller = ScrollController();

    questions = [];
    options = [];
    reasons = [];

    int tempQuestionNo = 1;
    for (int i = 0; i < widget.pageData.length; i++) {
      var page = widget.pageData[i];
      if (page["type"] == "mcq") {
        questions.add(page["text"]);
        reasons.add(page["reason"]);
        questionCount += 1;
        
        Map optionMap = {};
        List textOptions = [];
        List borderColors = [];

        var userChoice = widget.userData[i]["answer"];
        optionMap["choice"] = userChoice;             //? This is to keep track of user's choice during the mcq
        _marked = (userChoice != -1);

        optionMap["submitted"] = (userChoice != -1);  //? Check if already submitted before

        optionMap["correct"] = -1; //? For if there is no correct answer (error)
        for (int j = 0; j < page["options"].length; j++) {
          var option = page["options"][j]; //? This is each individuals option for a question
          var optionColor = Colors.transparent;

          if (option["correct"] == true) {
            optionMap["correct"] = j;
            if (userChoice != -1) optionColor = Color(0xFF22C8AD); //Colour green for correct
          }

          textOptions.add(option["text"]);
          borderColors.add(optionColor);
        }

        //? Mark the red/wrong option
        if (userChoice != -1 && optionMap["correct"] != userChoice) {
          borderColors[userChoice] = Colors.red;
        }

        optionMap["maxScore"] = page["maxScore"];
        optionMap["texts"] = textOptions;
        optionMap["colors"] = borderColors;
        options.add(optionMap);

        questionNo[i] = tempQuestionNo;
        tempQuestionNo += 1;
      } else if (page["type"] == "information") {
        questions.add(page["text"]);
        reasons.add(null);
        options.add(null);
        questionNo[i] = null;
      }
    }
    _updatePromptText();
    widget.userData.forEach((question) {
      if (question["answer"] != -1) score += question["score"];
    });
    print(options);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: AnimatedOpacity(
        duration: animDuration,
        opacity: _submitOpacity,
        child: IgnorePointer(
          ignoring: (_submitOpacity != 1.0),
          child: Container(
            width: global.phoneWidth * 0.8,
            height: 52.0,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                onTap: (_submitOpacity == 1.0) 
                  ? () {
                    if (_completed) {
                      _showSubmitDialog("Are you sure?", "Always check through your answers before submitting!");
                    } else {
                      _showSubmitDialog("You've missed something...", "Please answer all questions before submitting again.");
                    }
                  }
                  : null,
                child: Center(
                  child: (_submitLoading)  
                  ? SizedBox(
                      height: global.phoneHeight * 0.03,
                      width: global.phoneHeight * 0.03,
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(accentColor: Colors.white),
                        child: CircularProgressIndicator(
                          strokeWidth: 3.0,
                        ),
                      ),
                    )
                  : Text(
                      "Submit!",
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: "PoppinsSemiBold",
                        fontSize: 14.0
                      ),
                    ),
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: global.amber,
              borderRadius: BorderRadius.circular(8.0),
              boxShadow: global.elevationShadow4
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      backgroundColor: global.backgroundWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: Stack(
          children: <Widget>[
            //! Custom Painter with Curved region
            CustomPaint(
              size: Size(global.phoneWidth, _customPaintHeight),
              painter: CurvePainter(),
            ),
            //! Options PAGEVIEW
            GestureDetector(
              onTap: () {
                if (questionOpen) {
                  _toggleQuestionCard();
                }
              },
              child: ScrollConfiguration(
                behavior: MyBehavior(),
                child: PageView.builder(
                  onPageChanged: (page) {
                    if (dotSwipe) return;
                    _question_controller.animateToPage(page, duration: animDuration, curve: Curves.ease);
                    setState(() {
                      currentPage = page;
                      setState(() {
                        _updatePromptText();
                      });
                    });
                    _centerDotIndicator();
                    _submitOpacity = ((questionNo[currentPage] == questionCount || _completed) && !_marked) ? 1.0 : 0.0;
                  },
                  physics: BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  controller: _options_controller,
                  itemCount: options.length,
                  itemBuilder: (context, i) {
                    return Column(
                      children: <Widget>[
                        Container(height: global.phoneHeight * 0.5),
                        SizedBox(height: _promptTextHeight),
                        Expanded(
                          child: ScrollConfiguration(
                            behavior: MyBehavior(),
                            //! Listview to hold options for each question
                            child: ListView.builder(
                              padding: EdgeInsets.all(0.0),
                              shrinkWrap: true,
                              physics: BouncingScrollPhysics(),
                              itemCount: options[i]["texts"].length,
                              itemBuilder: (context, j) {
                                return Padding(
                                  padding: (j == 0) //? Padding for the FIRST option LEFT & RIGHT is 10% of phone width
                                    ? EdgeInsets.only(left: global.phoneWidth * 0.1, right: global.phoneWidth * 0.1, bottom: 8.0, top: 8.0) 
                                    : (j == options[i]["texts"].length-1) //? Padding for the LAST option
                                      ? EdgeInsets.only(left: global.phoneWidth * 0.1, right: global.phoneWidth * 0.1, top: 8.0, bottom: global.appBarHeight + global.phoneWidth * 0.1)
                                      : EdgeInsets.symmetric(horizontal: global.phoneWidth * 0.1, vertical: 8.0),
                                  child: Material(
                                    color: Colors.white,
                                    elevation: 2.0,
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: InkWell(
                                      splashFactory: global.CustomSplashFactory(),
                                      onTap: (options[i]["submitted"] == false && !questionOpen && !_submitLoading) 
                                        ? () {
                                          setState(() {
                                            if (options[i]["choice"] != -1) {
                                              for (int k = 0; k < options[i]["colors"].length; k++) {
                                                options[i]["colors"][k] = (k == j) ? Colors.amber : Colors.transparent;
                                              }
                                            }
                                            options[i]["choice"] = j;
                                            options[i]["colors"][j] = Colors.amber;

                                            var tempOpacity = 1.0;
                                            options.forEach((question) {
                                              if (question["choice"] == -1) tempOpacity = 0.0;
                                            });
                                            _submitOpacity = tempOpacity;
                                            _completed = (tempOpacity == 1.0);

                                            promptText = _nextQuestionPrompt;
                                          });
                                        }
                                        : null,
                                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                                      child: AnimatedContainer(
                                        padding: EdgeInsets.all(12.0),
                                        duration: animDuration,
                                        width: global.phoneWidth * 0.8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8.0),
                                          border: Border.all(
                                            color: options[i]["colors"][j],
                                            width: 2.0,
                                            style: BorderStyle.solid,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            options[i]["texts"][j],
                                            style: TextStyle(
                                              fontFamily: "PoppinsSemiBold"
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    )
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ); 
                  },
                ),
              ),
            ),
            //! Appbar
            Positioned(
              top: global.statusBarHeight + _extraStatusBarHeight,
              left: (global.phoneWidth - _questionCardWidth) / 2,
              child: Container(
                width: _questionCardWidth,
                height: _activityAppBarHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    //!Exit button
                    Container(
                        height: global.phoneWidth * 0.12,
                        width: global.phoneWidth * 0.12,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8.0)),
                        child: Material(
                            borderRadius: BorderRadius.circular(8.0),
                            elevation: 0.0,
                            color: Color(0x25ffffff),
                            child: InkWell(
                                borderRadius: BorderRadius.circular(8.0),
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: Center(
                                    child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 20.0,
                                    ),
                                    Text("Exit",
                                        style: TextStyle(
                                          fontFamily: "PoppinsSemiBold",
                                          fontSize: 9.0,
                                          color: Colors.white,
                                        ))
                                  ],
                                ))))),
                    //! Title text
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      width: global.phoneWidth * 0.6,
                      child: AutoSizeText(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontFamily: "PoppinsSemiBold",
                            fontSize: 16.0),
                        maxLines: 3,
                        minFontSize: 12.0,
                        maxFontSize: 16.0,
                      ),
                    ),
                    //! Score container
                    Container(
                        height: global.phoneWidth * 0.12,
                        width: global.phoneWidth * 0.12,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8.0),
                          color: Color(0x25ffffff),
                        ),
                        child: Center(
                            child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text("Score",
                                style: TextStyle(
                                  fontFamily: "PoppinsSemiBold",
                                  fontSize: 9.0,
                                  color: Colors.white,
                                )),
                            Text(score.toString(),
                                style: TextStyle(
                                  fontFamily: "PoppinsSemiBold",
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ))
                          ],
                        ))),
                  ],
                )),
            ),
            //! Options pageview top blur
            Positioned(
              top: global.phoneHeight * 0.5 + _promptTextHeight/2,
              child: Container(
                height: _promptTextHeight/2,
                width: global.phoneWidth,
                decoration: BoxDecoration(
                    color: global.backgroundWhite,
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 4.0,
                          color: global.backgroundWhite,
                          offset: Offset(0.0, 0.0),
                          spreadRadius: 6.0)
                    ]),
              ),
            ),
            //! Expanded Backdrop
            IgnorePointer(
              child: AnimatedOpacity(
                duration: animDuration,
                opacity: _backgroundOpacity,
                child: Container(
                  color: Color(0x60000000),
                  height: global.phoneHeight,
                  width: global.phoneWidth,
                ),
              ),
            ),
            //! Prompt text + Reason button
            Positioned(
              top: global.phoneHeight * 0.5,
              left: global.phoneWidth * 0.2,
              child: Container(
                padding: EdgeInsets.only(bottom: 6.0),
                width: global.phoneWidth * 0.6,
                height: _promptTextHeight,
                child: Center(
                  child: Wrap(
                    direction: Axis.horizontal,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: (options[currentPage]["submitted"])
                      ? [Text(
                          promptText,
                          style: TextStyle(fontFamily: "PoppinsSemiBold", fontSize: 14.0, color: Colors.black38),
                        ), Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _showReasonDialog((questionNo[currentPage] <= 9) ? "Question 0${questionNo[currentPage]}": "Question ${questionNo[currentPage]}", reasons[currentPage]);
                            },
                            borderRadius: BorderRadius.all(Radius.circular(2.0)),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 4.0),
                              child: Text(
                                (reasons[currentPage] != null && reasons[currentPage] != "") ? "Why?" : "",
                                style: TextStyle(
                                  fontFamily: "PoppinsSemiBold",
                                  color: Colors.black45
                                ),
                                ),
                            ),
                          ),
                        )]
                      : [Text(
                          promptText,
                          style: TextStyle(fontFamily: "PoppinsSemiBold", fontSize: 14.0, color: Colors.black38),
                        )],
                  ),
                ),
              ),
            ),
            //! Dots question indicator
            Positioned( //? Need to add 12.0 for the horizontal paddings
              left: ((_bigDotDiameter + _dotsPadding) * questionCount + _dotsHeight*2 < _dotsContainerWidth) 
                ? (global.phoneWidth - (_bigDotDiameter + _dotsPadding) * questionCount - _dotsHeight*2)/2 
                : (global.phoneWidth - _dotsContainerWidth)/2,
              top: (global.phoneHeight * 0.45 + _questionCardMinHeight + global.statusBarHeight + _extraStatusBarHeight*2 + _activityAppBarHeight + 10.0) / 2, //? Height of: background card + padding
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: _dotsContainerWidth,
                  minHeight: _dotsHeight,
                  maxHeight: _dotsHeight,
                ),
                child: Row(
                  children: <Widget>[
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          _question_controller.previousPage(duration: animDuration, curve: Curves.ease);
                        },
                        borderRadius: BorderRadius.all(Radius.circular(_dotsHeight/2)),
                        child: Icon(Icons.keyboard_arrow_left, size: _dotsHeight, color: Colors.white54)
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: _dots_controller,
                        physics: ClampingScrollPhysics(),
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        itemCount: questionCount,
                        itemBuilder: (context, i) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: _dotsPadding/2),
                            child: CircleAvatar(
                              backgroundColor: Colors.transparent,
                              radius: _bigDotDiameter/2,
                              child: GestureDetector(
                                onTap: () async {
                                  setState(() {
                                    dotSwipe = true;
                                  });
                                  int pageDest;
                                  questionNo.forEach((page, no) {
                                    if (i+1 == no) pageDest = page;
                                  });
                                  _options_controller.animateToPage(pageDest, duration: animDuration, curve: Curves.ease);
                                  _question_controller.animateToPage(pageDest, duration: animDuration, curve: Curves.ease);
                                  setState(() {
                                    currentPage = pageDest; 
                                    _updatePromptText();
                                    _submitOpacity = ((questionNo[currentPage] == questionCount || _completed) && !_marked) ? 1.0 : 0.0;
                                  });
                                  await Future.delayed(animDuration);
                                  setState(() {
                                    dotSwipe = false;
                                  });
                                  _centerDotIndicator();
                                },
                                child: AnimatedContainer(
                                  duration: animDuration,
                                  height: (i+1 == questionNo[currentPage]) ? _bigDotDiameter : _smallDotDiameter,
                                  width: (i+1 == questionNo[currentPage]) ? _bigDotDiameter : _smallDotDiameter,
                                  decoration: BoxDecoration(
                                    color: (options[i]["submitted"]) 
                                      ? (options[i]["choice"] == options[i]["correct"]) 
                                        ? (i+1 == questionNo[currentPage]) ? Color(0xFF1DE9B6) : Color(0x751DE9B6) //? GREEN for correct
                                        : (i+1 == questionNo[currentPage]) ? Color(0xFFF44336) : Color(0x90E57373) //? RED for wrong
                                      : (options[i]["choice"] == -1) 
                                        ? Colors.white
                                        : (i+1 == questionNo[currentPage]) ? Color(0xFFFFC400) : Color(0xD8FFC400),
                                    borderRadius: BorderRadius.all(Radius.circular((i+1 == questionNo[currentPage]) ? _bigDotDiameter/2 : _smallDotDiameter/2,)),
                                    boxShadow: (i+1 == questionNo[currentPage] || !options[i]["submitted"]) 
                                    ? global.elevationShadow2
                                    : [],
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        width: 2.0,
                                        color: (i+1 == questionNo[currentPage]) 
                                          ? Color(0x5FFFFFFFF)
                                          : Colors.transparent
                                      ),
                                      shape: BoxShape.circle
                                    ),
                                    child: (i+1 == questionNo[currentPage] && options[i]["submitted"]) 
                                    ? Center(
                                        child: (options[i]["choice"] == options[i]["correct"])
                                          ? _correctIcon
                                          : _wrongIcon,
                                      )
                                    : Container(),
                                  )
                                ),
                              )
                            ),
                          );
                        },
                      ), 
                    ),
                    Material(
                      type: MaterialType.transparency,
                      child: InkWell(
                        onTap: () {
                          _question_controller.nextPage(duration: animDuration, curve: Curves.ease);
                        },
                        borderRadius: BorderRadius.all(Radius.circular(_dotsHeight/2)),
                        child: Icon(Icons.keyboard_arrow_right, size: _dotsHeight, color: Colors.white54)
                      ),
                    )
                  ],
                ),
              ),
            ),
          //! Background card container
          Positioned(
            left: (global.phoneWidth - _questionCardWidth * 0.86) / 2,
            top: _questionCardMinHeight + global.statusBarHeight + _extraStatusBarHeight*2 + _activityAppBarHeight,
            child: Container(
              height: 10.0,
              width: _questionCardWidth * 0.86,
              child: Material(
                elevation: 2.0,
                color: Colors.white70,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0)),
              ),
            ),
          ),
            //! Question container
            Positioned(
              left: (global.phoneWidth - _questionCardWidth) / 2,
              top: global.statusBarHeight + _extraStatusBarHeight*2 + _activityAppBarHeight,
              child: AnimatedContainer(
                //? Animation applied to only the height of the container
                duration: animDuration,
                height: _questionCardHeight,
                width: _questionCardWidth,
                child: Material(
                  color: global.backgroundWhite,
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Stack(
                    children: <Widget>[
                      //! Question PAGEVIEW
                      AnimatedContainer(
                        duration: animDuration,
                        margin: EdgeInsets.only(top: 24.0), //? Margin = Question text height
                        height: _questionCardHeight - 30.0, //? Offset top margin + extra to clip the pageview
                        child: ScrollConfiguration(
                          behavior: MyBehavior(),
                          child: PageView.builder(
                            onPageChanged: (page) {
                              if (dotSwipe) return; //? Don't execute if user uses dots for navigation
                              _options_controller.animateToPage(page, duration: animDuration, curve: Curves.ease);
                              currentPage = page;
                              setState(() {
                                _updatePromptText();
                              });
                              _centerDotIndicator();
                              _submitOpacity = ((questionNo[currentPage] == questionCount || _completed) && !_marked) ? 1.0 : 0.0;
                            },
                            physics: BouncingScrollPhysics(),
                            controller: _question_controller,
                            itemCount: questions.length,
                            itemBuilder: (context, i) {
                              return ScrollConfiguration(
                                  behavior: MyBehavior(),
                                  child: SingleChildScrollView(
                                    physics: BouncingScrollPhysics(),
                                    padding: EdgeInsets.all(0.0),
                                      child: Padding(
                                        padding: EdgeInsets.only(bottom: 8.0,left: global.phoneWidth * 0.05, right: global.phoneWidth * 0.05),
                                        child: Html(
                                          data: questions[i],
                                          defaultTextStyle: TextStyle(
                                            fontFamily: "PoppinsSemiBold",
                                            fontSize: 14.0,
                                          ),
                                        ),
                                      ),
                                    ));
                            },
                          ),
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                              Radius.circular(8.0))),
                      ),
                      //! BOTTOM Blur 
                      Positioned(
                        bottom: 0.0,
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(8.0),
                            bottomLeft: Radius.circular(8.0)
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            heightFactor: 2,
                            child: Container(
                              height: 20.0,
                              width: _questionCardWidth,
                              decoration: BoxDecoration(
                                  color: global.backgroundWhite,
                                  boxShadow: [
                                    BoxShadow(
                                        blurRadius: 4.0,
                                        color: global.backgroundWhite,
                                        offset: Offset(0.0, -6.0),
                                        spreadRadius: 4.0)
                                  ]),
                            ),
                          )
                        ),
                      ),
                      //! Expand text
                      AnimatedPositioned(
                        top: _questionCardHeight - 12.0 - 10.0,
                        left: _questionCardWidth * 0.25,
                        duration: animDuration,
                        child: Container(
                          width: _questionCardWidth * 0.5,
                          child: Center(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashFactory: global.CustomSplashFactory(),
                                onTap: () {
                                  _toggleQuestionCard();
                                },
                                borderRadius: BorderRadius.all(Radius.circular(4.0)),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Text(
                                    _expandText, 
                                    style: TextStyle(
                                      fontSize: 12.0,
                                      fontFamily: "PoppinsSemiBold",
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      //! TOP Blur
                      Positioned(
                        left: _questionCardWidth * 0.05,
                        top: 14.0,
                        child: Container(
                          height: 4.0,
                          width: _questionCardWidth * 0.9,
                          decoration: BoxDecoration(
                              color: global.backgroundWhite,
                              boxShadow: [
                                BoxShadow(
                                  blurRadius: 4.0,
                                  color: global.backgroundWhite,
                                  offset: Offset(0.0, 2.0),
                                  spreadRadius: _questionCardWidth * 0.04,
                                )
                              ]),
                        ),
                      ),
                      //! Question number text
                      Container(
                        height: 24.0, //? Height of question text field
                        width: _questionCardWidth,
                        padding: EdgeInsets.only(top: 6.0),
                        child: Center(
                          child: Text(
                            (questionNo[currentPage] <= 9) ? "Question 0${questionNo[currentPage]}": "Question ${questionNo[currentPage]}",
                            style: TextStyle(
                              fontFamily: "PoppinsSemiBold",
                              fontSize: 14.0,
                              color: global.amber
                            ),
                          textAlign: TextAlign.center,
                        )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Path path = Path();
    path.moveTo(0, 0);
    path.lineTo(0, size.height);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width, size.height);
    path.lineTo(size.width, 0);
    path.close();

    Rect rect = Rect.fromLTWH(0.0, 0.0, size.width, size.height * 0.55);
    Gradient gradient = LinearGradient(
        begin: FractionalOffset.bottomCenter,
        end: FractionalOffset.topCenter,
        colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]);
    Paint paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawShadow(path, Colors.black, 2.0, true);
    canvas.drawPath(path, paint);     
  }

  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    return child;
  }
}

class SubmittedMCQ extends StatefulWidget {
  final int actId;
  final String title;
  final double score;
  final int maxScore;

  SubmittedMCQ({this.actId, this.title, this.score, this.maxScore});

  @override
  State<StatefulWidget> createState() {
    return SubmittedMCQState();
  }
}

//TODO Use _loading to show the circular progress indicator
class SubmittedMCQState extends State<SubmittedMCQ> {
  Random random = Random();
  bool _loading = false;

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(content),
          actions: <Widget>[
            FlatButton(
              child: Text("OKAY"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void getPageData() async {
    var userData;

    if (!await connectionStatus.checkConnection()) { //If not connected!
      print("MCQ submit: Not connected!");
      _showDialog("Oh no!",
          "Something went wrong! Please check your Internet connection!");
      setState(() {
        _loading = false;
      });
      return;
    }

    final String url = "https://tinypingu.infocommsociety.com/api/get-activity-attempt";
    await http.post(url,
        headers: {"Cookie": global.cookie, "Content-Type": "application/json"},
        body: json.encode({"activityId": widget.actId})).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body);
        
        userData = responseArr["data"];
        print("SubmitMCQ: Get attempt success!");
      } else {
        print("SubmitMCQ: Error! Attempt data not retrieved!");
      }
    });

    final String mapUrl = "https://tinypingu.infocommsociety.com/api/getactivity";
    await http.post(mapUrl,
        headers: {"Cookie": global.cookie},
        body: {"id": widget.actId.toString()}).then((dynamic response) {
      if (response.statusCode == 200) {
        final responseArr = json.decode(response.body);
        var pages = responseArr["pages"];
        print("SubmitMCQ: Get activity success!");

        Route route = MaterialPageRoute(
            builder: (context) => McqPage(
              actId: responseArr["id"],
              title: widget.title, 
              pageData: pages,
              userData: userData,
            ));
        Navigator.pushReplacement(context, route);
      } else {
        print("SubmitMCQ: Error! Page data not retrieved!");
      }

      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    connectionStatus = ConnectionStatusSingleton.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 1,
              child: SizedBox(
                width: double.infinity,
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    "Congrats!",
                    style: TextStyle(
                      fontFamily: "CarterOne",
                      fontSize: 40.0,
                    ),
                  ),
                  SvgPicture.asset(
                    (random.nextInt(2) == 0) ? 'images/trophy.svg' : "images/finish.svg",
                    width: global.phoneWidth * 0.8,
                  ),
                  Text(
                    "Score: ${widget.score}/${widget.maxScore}",
                    style: TextStyle(
                      fontFamily: "CarterOne",
                      fontSize: 16.0,
                    ),
                  ),
                  
                ],
              ),
            ),
            Column(
              children: <Widget>[
                //! Review questions button 
                Container(
                  margin: EdgeInsets.only(bottom: 20.0),
                  width: global.phoneWidth * 0.8,
                  height: 52.0,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      onTap: () {
                        setState(() {
                          _loading = true; 
                        });
                        getPageData();
                      },
                      child: Center(
                        child: (_loading)  
                        ? SizedBox(
                            height: global.phoneHeight * 0.03,
                            width: global.phoneHeight * 0.03,
                            child: Theme(
                              data: Theme.of(context)
                                  .copyWith(accentColor: Colors.white),
                              child: CircularProgressIndicator(
                                strokeWidth: 3.0,
                              ),
                            ),
                          )
                        : Text(
                            "Review questions",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: "PoppinsSemiBold",
                              fontSize: 14.0
                            ),
                          ),
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    gradient: global.blueButtonGradient,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: global.elevationShadow4
                  ),
                ),
                //! Back button
                Container(
                  margin: EdgeInsets.only(bottom: 56.0),
                  width: global.phoneWidth * 0.8,
                  height: 52.0,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.all(Radius.circular(8.0)),
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Center(
                        child: Text(
                            "Or continue exploring!",
                            style: TextStyle(
                              color: Colors.black54,
                              fontFamily: "PoppinsSemiBold",
                              fontSize: 12.0
                            ),
                          ),
                      ),
                    ),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8.0),
                    boxShadow: global.elevationShadow2
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}