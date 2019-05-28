library my_prj.globals;
import 'dart:math' as math;
import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_explorer/explore_map.dart';
import 'package:smart_explorer/main.dart';

int subindex = 0;
int chapindex = 0;
int score = 0;
List<String> subjects = ["H2 Economics", "H2 Math", "H2 Chemistry", "H2 Physics"];
String studentID = "";
String studentName = "";
String studentEmail = "";

List<double> overallProgress = [0,0,0,0];
List<int> totalScore = [0,0,0,0];

String cookie = "";

//! Shared Preferences key values
String pref_cookie = "cookie";        //Just purely cookie
String auth_details = "AuthDetails";  //Includes studentID, Name and Email

//! Parameters
double phoneHeight = 0.0;
double phoneWidth = 0.0;
double statusBarHeight = 0.0;
double navBarHeight = 200;
double bottomAppBarHeight = 56.0;

//! Colours:
Color blue = const Color(0xFF78B2FA);
Color appBarLightBlue = const Color(0xFFCDD6F0);
Color backgroundWhite = const Color(0xFFF6F8FC);
Color darkBlue = const Color(0xFF1B417C);

LinearGradient blueGradient = LinearGradient(
  colors: [Color(0xFF78B5FA), Color(0xFF7DA2FF)]
);

LinearGradient blueButtonGradient = LinearGradient(
  colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]
);

LinearGradient redGradient = LinearGradient(
  colors: [Color(0xFFEB4956), Color(0xFFF48149)]
);

LinearGradient greenGradient = LinearGradient(
  colors: [Color(0xFF57CDDB), Color(0xFF4AE296)]
);

LinearGradient redDiagonalGradient = LinearGradient(
  begin: FractionalOffset.topRight,
  end: FractionalOffset.bottomLeft,
  colors: [Color(0xFFEB4956), Color(0xFFF48149)]
);

LinearGradient greenDiagonalGradient = LinearGradient(
  begin: FractionalOffset.topRight,
  end: FractionalOffset.bottomLeft,
  colors: [Color(0xFF4AE296), Color(0xFF57CDDB)]
);

Gradient orangeDiagonalGradient = LinearGradient(
  begin: FractionalOffset.topRight,
  end: FractionalOffset.bottomLeft,
  colors: [Color(0xFFFAD87B), Color(0xFFF28752)]
);

LinearGradient bluePurpleDiagonalGradient = LinearGradient(
  begin: FractionalOffset.bottomLeft,
  end: FractionalOffset.topRight,
  colors: [Color(0xFF78B5FA), Color(0xFF9586FD)]
);

Gradient pinkDiagonalGradient = LinearGradient(
  begin: FractionalOffset.bottomLeft,
  end: FractionalOffset.topRight,
  colors: [Color(0xFFED4264), Color(0xFFff9472)]
);

Widget createGradientButton(LinearGradient gradient, double height, double width, BuildContext context, Widget route, String content){
  return Container(
    decoration: BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(height/2),
      boxShadow: [
        BoxShadow(
            color: Colors.grey, blurRadius: 4.0, offset: Offset(2.0, 2.0)),
      ],
    ),
      height: height,
      width: width,
      child: Material(
        borderRadius: BorderRadius.circular(height/2),
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) { 
                return route;
              }),
            );
          },
          borderRadius: BorderRadius.circular(24.0),
          child: Center(
              child: Text(
                content,
                style: TextStyle(
                  fontFamily: "Nunito",
                  fontSize: 20.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
    );
}

Widget bottomAppBar(){
  return null;
}

class LoginInfo {
  String studentID;
  String studentClass;
  String username;
  String name;
  String email;
  Map activityProgress;
  List<dynamic> subjects;
  List<dynamic> submissions;
  String _id;
  
  LoginInfo(response){
    // print("DEBUG RESPONSE: ");
    // print(response);
    //this.studentID = response["studentId"];
    //this.studentClass = response["studentClass"];
    //this.username = response["username"];
    //this.name = response["name"];
    //this.email = response["email"];
    //this.activityProgress = response["activityProgress"];
    this.subjects = response; 
    // print(this.subjects);
    //this.submissions = response["submissions"]; 
    //this._id = response["_id"];
    // print("Survived!");
   }
}

class ExploreMapInfo {
  String subjectName;
  List chapData;
  Map<String, List<ExploreMapActivity>> chapters = new Map();

  ExploreMapInfo(response){
    this.subjectName = response["name"];
    this.chapData = response["children"];
    final chapterList = response["children"];

    List<ExploreMapActivity> tempActivity = [];
    chapterList.forEach((chap) {
      final chapName = chap["name"];
      final activityList = chap["children"];

      activityList.forEach((act) {
        final activity = ExploreMapActivity(act["name"], act["type"], act["dsc"], 
        act["ord"], act["maxScore"], act["id"]);
        tempActivity.add(activity);
      });

      chapters[chapName] = tempActivity;
    });
  }
}

class ExploreMapActivity {
  String activityName;
  String activityType;
  String activityDesc;
  int activityProg;
  int activityMaxScore;
  int activityId;

  ExploreMapActivity(this.activityName, this.activityType, this.activityDesc, 
  this.activityProg, this.activityMaxScore, this.activityId);
}

int randomRange(int n1, int n2, int seed) {
  math.Random random = math.Random(seed);

  int minInt, maxInt;

  if (n1 > n2) {
    maxInt = n1;
    minInt = n2;
  } else if (n1 < n2) {
    minInt = n1;
    maxInt = n2;
  } else return n1;

  int number = random.nextInt(maxInt);
  while (number < minInt) 
    number = random.nextInt(maxInt);

  return number;
}

//Part to copy from the source code.
const Duration _kUnconfirmedSplashDuration = const Duration(milliseconds: 2000);
const Duration _kSplashFadeDuration = const Duration(milliseconds: 400);

const double _kSplashInitialSize = 0.0; // logical pixels
const double _kSplashConfirmedVelocity = 0.2;

class CustomSplashFactory extends InteractiveInkFeatureFactory {
  const CustomSplashFactory();

  @override
  InteractiveInkFeature create({MaterialInkController controller, RenderBox referenceBox, Offset position, Color color, TextDirection textDirection, bool containedInkWell = false, rectCallback, BorderRadius borderRadius, ShapeBorder customBorder, double radius, onRemoved}) {
    return new CustomSplash(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}

class CustomSplash extends InteractiveInkFeature {
  static const InteractiveInkFeatureFactory splashFactory = const CustomSplashFactory();

  CustomSplash({
    @required MaterialInkController controller,
    @required RenderBox referenceBox,
    Offset position,
    Color color,
    bool containedInkWell = false,
    RectCallback rectCallback,
    BorderRadius borderRadius,
    double radius,
    VoidCallback onRemoved,
  }) : _position = position,
        _borderRadius = borderRadius ?? BorderRadius.zero,
        _targetRadius = radius ?? _getTargetRadius(referenceBox, containedInkWell, rectCallback, position),
        _clipCallback = _getClipCallback(referenceBox, containedInkWell, rectCallback),
        _repositionToReferenceBox = !containedInkWell,
        super(controller: controller, referenceBox: referenceBox, color: color, onRemoved: onRemoved) {
    assert(_borderRadius != null);
    _radiusController = new AnimationController(duration: _kUnconfirmedSplashDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..forward();
    _radius = new Tween<double>(
        begin: _kSplashInitialSize,
        end: _targetRadius
    ).animate(_radiusController);
    _alphaController = new AnimationController(duration: _kSplashFadeDuration, vsync: controller.vsync)
      ..addListener(controller.markNeedsPaint)
      ..addStatusListener(_handleAlphaStatusChanged);
    _alpha = new IntTween(
        begin: color.alpha,
        end: 0
    ).animate(_alphaController);

    controller.addInkFeature(this);
  }

  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  final RectCallback _clipCallback;
  final bool _repositionToReferenceBox;

  Animation<double> _radius;
  AnimationController _radiusController;

  Animation<int> _alpha;
  AnimationController _alphaController;

  @override
  void confirm() {
    final int duration = (_targetRadius / _kSplashConfirmedVelocity).floor();
    _radiusController
      ..duration = new Duration(milliseconds: duration)
      ..forward();
    _alphaController.forward();
  }

  @override
  void cancel() {
    _alphaController?.forward();
  }

  void _handleAlphaStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed)
      dispose();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _alphaController.dispose();
    _alphaController = null;
    super.dispose();
  }

  RRect _clipRRectFromRect(Rect rect) {
    return new RRect.fromRectAndCorners(
      rect,
      topLeft: _borderRadius.topLeft, topRight: _borderRadius.topRight,
      bottomLeft: _borderRadius.bottomLeft, bottomRight: _borderRadius.bottomRight,
    );
  }

  void _clipCanvasWithRect(Canvas canvas, Rect rect, {Offset offset}) {
    Rect clipRect = rect;
    if (offset != null) {
      clipRect = clipRect.shift(offset);
    }
    if (_borderRadius != BorderRadius.zero) {
      canvas.clipRRect(_clipRRectFromRect(clipRect));
    } else {
      canvas.clipRect(clipRect);
    }
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final Paint paint = new Paint()..color = color.withAlpha(_alpha.value);
    Offset center = _position;
    if (_repositionToReferenceBox)
      center = Offset.lerp(center, referenceBox.size.center(Offset.zero), _radiusController.value);
    final Offset originOffset = MatrixUtils.getAsTranslation(transform);
    if (originOffset == null) {
      canvas.save();
      canvas.transform(transform.storage);
      if (_clipCallback != null) {
        _clipCanvasWithRect(canvas, _clipCallback());
      }
      canvas.drawCircle(center, _radius.value, paint);
      canvas.restore();
    } else {
      if (_clipCallback != null) {
        canvas.save();
        _clipCanvasWithRect(canvas, _clipCallback(), offset: originOffset);
      }
      canvas.drawCircle(center + originOffset, _radius.value, paint);
      if (_clipCallback != null)
        canvas.restore();
    }
  }
}

double _getTargetRadius(RenderBox referenceBox, bool containedInkWell, RectCallback rectCallback, Offset position) {
  if (containedInkWell) {
    final Size size = rectCallback != null ? rectCallback().size : referenceBox.size;
    return _getSplashRadiusForPositionInSize(size, position);
  }
  return Material.defaultSplashRadius;
}

double _getSplashRadiusForPositionInSize(Size bounds, Offset position) {
  final double d1 = (position - bounds.topLeft(Offset.zero)).distance;
  final double d2 = (position - bounds.topRight(Offset.zero)).distance;
  final double d3 = (position - bounds.bottomLeft(Offset.zero)).distance;
  final double d4 = (position - bounds.bottomRight(Offset.zero)).distance;
  return math.max(math.max(d1, d2), math.max(d3, d4)).ceilToDouble();
}

RectCallback _getClipCallback(RenderBox referenceBox, bool containedInkWell, RectCallback rectCallback) {
  if (rectCallback != null) {
    assert(containedInkWell);
    return rectCallback;
  }
  if (containedInkWell)
    return () => Offset.zero & referenceBox.size;
  return null;
}