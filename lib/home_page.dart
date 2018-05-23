import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:news_aggreator/drawer_page.dart';
import 'package:news_aggreator/post.dart';
import 'package:news_aggreator/post_details.dart';
import 'package:news_aggreator/strings.dart';

class DrawerItem {
  String title;
  IconData icon;

  DrawerItem(this.title, this.icon);
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  final drawerItems = [
    new DrawerItem(Strings.appName, Icons.rss_feed),
    new DrawerItem("Fragment 2", Icons.local_pizza),
    new DrawerItem("Fragment 3", Icons.info)
  ];

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isRequestSent = false;
  bool _isRequestFailed = false;
  List<Post> postList = [];

  String currentProfilePic =
      "https://avatars3.githubusercontent.com/u/16825392?s=460&v=4";
  String otherProfilePic =
      "https://yt3.ggpht.com/-2_2skU9e2Cw/AAAAAAAAAAI/AAAAAAAAAAA/6NpH9G8NWf4/s900-c-k-no-mo-rj-c0xffffff/photo.jpg";

  void switchAccounts() {
    String picBackup = currentProfilePic;
    this.setState(() {
      currentProfilePic = otherProfilePic;
      otherProfilePic = picBackup;
    });
  }

  int _selectedDrawerIndex = 0;

  _onSelectItem(int index) {
    setState(() => _selectedDrawerIndex = index);
    Navigator.of(context).pop(); // close the drawer
    if (index > 0)
      Navigator.of(context).push(new PageRouteBuilder(
          opaque: false,
          pageBuilder: (BuildContext context, _, __) {
            return new Page("Page " + index.toString());
          },
          transitionsBuilder:
              (_, Animation<double> animation, __, Widget child) {
            return new FadeTransition(
              opacity: animation,
              child: new SlideTransition(
                  position: new Tween<Offset>(
                    begin: const Offset(0.0, 1.0),
                    end: Offset.zero,
                  )
                      .animate(animation),
                  child: child),
            );
          }));
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    if (!_isRequestSent) {
      sendRequest();
    }

    List<Widget> drawerOptions = [];
    for (var i = 0; i < widget.drawerItems.length; i++) {
      var d = widget.drawerItems[i];
      drawerOptions.add(new ListTile(
        leading: new Icon(d.icon),
        title: new Text(d.title),
        selected: i == _selectedDrawerIndex,
        onTap: () => _onSelectItem(i),
      ));
    }

    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.drawerItems[_selectedDrawerIndex].title),
      ),
      drawer: new Drawer(
        child: new Column(
          children: <Widget>[
            new UserAccountsDrawerHeader(
              accountEmail: new Text("bramvbilsen@gmail.com"),
              accountName: new Text("Bramvbilsen"),
              currentAccountPicture: new GestureDetector(
                child: new CircleAvatar(
                  backgroundImage: new NetworkImage(currentProfilePic),
                ),
                onTap: () => print("This is your current account."),
              ),
              otherAccountsPictures: <Widget>[
                new GestureDetector(
                  child: new CircleAvatar(
                    backgroundImage: new NetworkImage(otherProfilePic),
                  ),
                  onTap: () => switchAccounts(),
                ),
              ],
              decoration: new BoxDecoration(
                  image: new DecorationImage(
                      image: new NetworkImage(
                          "https://img00.deviantart.net/35f0/i/2015/018/2/6/low_poly_landscape__the_river_cut_by_bv_designs-d8eib00.jpg"),
                      fit: BoxFit.fill)),
            ),
            new Column(children: drawerOptions)
          ],
        ),
      ),
      body: new Container(
        alignment: Alignment.center,
        child: !_isRequestSent
            //  Request has not been sent, let's show a progress indicator
            ? new CircularProgressIndicator()
            // Request has been sent but did it fail?
            : _isRequestFailed
                // Yes, it has failed. Show a retry UI
                ? _showRetryUI()
                // No it didn't fail. Show the data
                : new Container(
                    child: new ListView.builder(
                        itemCount: postList.length,
                        scrollDirection: Axis.vertical,
                        itemBuilder: (BuildContext context, int index) {
                          return _getPostWidgets(index);
                        }),
                  ),
      ),
    );
  }

  void sendRequest() async {
    String url =
        "https://api.nytimes.com/svc/topstories/v2/technology.json?api-key=${Strings
        .apiKey}";
    try {
      http.Response response = await http.get(url);
      // Did request succeeded?
      if (response.statusCode == HttpStatus.OK) {
        // We're expecting a Json object as the result
        Map decode = json.decode(response.body);
        parseResponse(decode);
      } else {
        print(response.statusCode);
        handleRequestError();
      }
    } catch (e) {
      print(e);
      handleRequestError();
    }
  }

  Widget _getPostWidgets(int index) {
    var post = postList[index];
    return new GestureDetector(
      onTap: () {
        openDetailsUI(post);
      },
      child: new Container(
        margin: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
        child: new Card(
          elevation: 3.0,
          child: new Row(
            children: <Widget>[
              new Container(
                width: 150.0,
                child: new CachedNetworkImage(
                  imageUrl: post.thumbUrl,
                  fit: BoxFit.cover,
                  placeholder: new Icon(
                    Icons.panorama,
                    color: Colors.grey,
                    size: 120.0,
                  ),
                ),
              ),
              new Expanded(
                  child: new Container(
                margin: new EdgeInsets.all(10.0),
                child: new Text(
                  post.title,
                  style: new TextStyle(color: Colors.black, fontSize: 18.0),
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void parseResponse(Map response) {
    List results = response["results"];
    for (var jsonObject in results) {
      var post = Post.getPostFrmJSONPost(jsonObject);
      postList.add(post);
      //print result
      print(post);
    }
    setState(() => _isRequestSent = true);
  }

  void handleRequestError() {
    setState(() {
      _isRequestSent = true;
      _isRequestFailed = true;
    });
  }

  Widget _showRetryUI() {
    return new Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Text(
            Strings.requestFailed,
            style: new TextStyle(fontSize: 16.0),
          ),
          new Padding(
            padding: new EdgeInsets.only(top: 10.0),
            child: new RaisedButton(
              onPressed: retryRequest,
              child: new Text(
                Strings.retry,
                style: new TextStyle(color: Colors.white),
              ),
              color: Theme.of(context).accentColor,
              splashColor: Colors.deepOrangeAccent,
            ),
          )
        ],
      ),
    );
  }

  void retryRequest() {
    setState(() {
      // Let's just reset the fields.
      _isRequestSent = false;
      _isRequestFailed = false;
    });
  }

  openDetailsUI(Post post) {
//    Navigator.push(
//        context,
//        new MaterialPageRoute(
//            builder: (BuildContext context) => new PostDetails(post)));

    Navigator.of(context).push(new PageRouteBuilder(
        opaque: false,
        pageBuilder: (BuildContext context, _, __) {
          return new PostDetails(post);
        },
        transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
          return new FadeTransition(
            opacity: animation,
            child: new SlideTransition(
                position: new Tween<Offset>(
                  begin: const Offset(0.0, 1.0),
                  end: Offset.zero,
                )
                    .animate(animation),
                child: child),
          );
        }));
  }
}
