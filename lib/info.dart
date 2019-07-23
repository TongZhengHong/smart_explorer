import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:smart_explorer/global.dart' as global;
import 'package:flutter/services.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InfoPage extends StatefulWidget {
  final int actId;
  final pageData;
  final title;

  InfoPage({this.actId, this.pageData, this.title});

  @override
  State<StatefulWidget> createState() {
    return InfoPageState();
  }
}

class InfoPageState extends State<InfoPage> {
  ScrollController _scrollController;
  GlobalKey _titleHeightKey = GlobalKey();
  double _titleHeight = 0;

  int _currentPage = 0;
  int _picturePage = 0;

  double _titleLeftPadding = 24.0;
  double _titleBottomPadding = 16.0;
  double _headerMaxHeight = global.phoneHeight * 0.3;
  double _headerOpacity = 1.0;
  double _progressHeight = 4.0;

  List<Widget> _headerImages = [];

  _launchURL(url) async {
    if (await canLaunch(url)) {
      await launch(url, forceWebView: true);
    } else {
      throw 'Could not launch $url';
    }
  }

  void _onScroll() {
    setState(() {
      if (_scrollController.offset <= _headerMaxHeight - global.appBarHeight) {
        _titleLeftPadding = (_scrollController.offset / (_headerMaxHeight - global.appBarHeight)) * 36.0 + 24.0;
        if (_titleHeight == 0) {
          final RenderBox renderBoxRed = _titleHeightKey.currentContext.findRenderObject();
          _titleHeight = renderBoxRed.size.height;
        }
        double bottomPadding = (global.appBarHeight - _titleHeight) / 2;
        _titleBottomPadding = (1-(_scrollController.offset / (_headerMaxHeight - global.appBarHeight))) * (16.0 - bottomPadding) + bottomPadding;
      }
    });
  }

  @override
  void initState() {    
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    widget.pageData.forEach((page) {
      if (page["headerImage"] != null) {
        _headerImages.add(FadeInImage.memoryNetwork(
          image: "https://tinypingu.infocommsociety.com" + page["headerImage"],
          fadeInDuration: Duration(milliseconds: 300),
          placeholder: kTransparentImage,
          fit: BoxFit.cover,
          height: _headerMaxHeight,
          width: global.phoneWidth,
        ));
      } else {
        _headerImages.add(Container(
          color: Colors.transparent,
        ));
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: global.backgroundWhite,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, scrolled) {
            return <Widget> [
              //! Sliver AppBar
              SliverAppBar(
                pinned: true,
                elevation: 0.0,
                forceElevated: scrolled,
                backgroundColor: Color(0xFF7DA2FF),
                expandedHeight: _headerMaxHeight,
                //! Progress Indicator
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0.0),
                  child: Stack(
                    children: <Widget>[
                      Container(
                        height: _progressHeight,
                        width: global.phoneWidth,
                        color: global.backgroundWhite,
                      ),
                      AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      height: _progressHeight,
                      width: ((_currentPage+1) / widget.pageData.length) * global.phoneWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: FractionalOffset.bottomLeft,
                          end: FractionalOffset.topRight,
                          colors: [Color(0xFFFAD87B), Color(0xFFF28752)]
                        ),
                        borderRadius: ((_currentPage+1) != widget.pageData.length) 
                          ? BorderRadius.only(topRight: Radius.circular(_progressHeight/2), bottomRight: Radius.circular(_progressHeight/2)) 
                          : null 
                        ),
                      ),
                    ],
                  )
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: _titleLeftPadding, bottom: _titleBottomPadding),
                  centerTitle: false,
                  title: Container(
                    width: global.phoneWidth * 0.5,
                    child: AutoSizeText(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14.0,
                        fontFamily: "PoppinsSemiBold"
                      ),
                      key: _titleHeightKey,
                      maxLines: 2,
                      maxFontSize: 16.0,
                      minFontSize: 12.0,
                    ),
                  ),
                  background: AnimatedOpacity(
                    duration: Duration(milliseconds: 300),
                    opacity: _headerOpacity,
                    child: Stack(
                      children: <Widget>[
                        Container(
                          height: _headerMaxHeight + global.statusBarHeight,
                          child: _headerImages[_picturePage],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: FractionalOffset.bottomCenter,
                              end: FractionalOffset.topCenter,
                              colors: [Color(0xE678B5FA), Color(0x809586FD)]
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ),
                actions: <Widget>[
                  IconButton(
                    icon: Icon(Icons.more_vert),
                    onPressed: () {},
                  )
                ],
              ),
            ];
          },
          body: PageView.builder(
            onPageChanged: (page) async {
              setState(() {
                _headerOpacity = 0.0;
                _currentPage = page;
              });
              await Future.delayed(Duration(milliseconds: 300));
              setState(() {
                _picturePage = page;
                _headerOpacity = 1.0;
              });
            },
            itemCount: widget.pageData.length,
            itemBuilder: (context, i) {
              return SingleChildScrollView(
                physics: ClampingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.only(top: 8.0, bottom: 56.0, left: 24.0, right: 24.0),
                  child: Html(
                    onLinkTap: (url) {
                      _launchURL(url);
                    },
                    data: widget.pageData[i]["text"],
                    defaultTextStyle: TextStyle(
                      fontFamily: "PoppinsSemiBold",
                      fontSize: 16.0,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}