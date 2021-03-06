import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final server = 'http://127.0.0.1:8081/';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Alert me',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Press the message to send'),
    );
  }
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

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<List<Reason>> reasons;

  fetch() {
    setState(() {
      reasons = fetchReasons();
    });
    return reasons;
  }


  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text(widget.title),
        ),
        body: new Center(
            child: new FutureBuilder<List<Reason>>(
          future: fetch(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return new ListView.builder(
                itemCount: snapshot.data.length,
                itemBuilder: (context, index) {
                  final value = snapshot.data[index];
                  return new Column(
                    children: <Widget>[
                      new RaisedButton(
                        onPressed: () => send(context, value.text),
                        child: new Text(value.text, textScaleFactor: 2.0),
                      ),
                      new Divider()
                    ],
                  );
                },
              );
            } else if (snapshot.hasError) {
              return new Column(children: [
                new Text("Unexpected error: \n\n${snapshot.error}\n\nTry reloading the app?"),
                new RaisedButton(
                  onPressed: () => fetch(),
                  child: new Text('Reload', textScaleFactor: 2.0),
                )
              ]);
            }
            return new CircularProgressIndicator();
          })
        )
    );
  }
}

Future<List<Reason>> fetchReasons() async {
  final response = await http.get(server);

  if (response.statusCode == 200) {
    Iterable l = json.decode(response.body);
    return l.map((model) => Reason.fromJson(model)).toList();
  } else {
    throw new Exception("unexpected error code ${response.statusCode}");
  }
}

Future send(BuildContext context, String msg) async {
  final data = json.encode({"msg": msg});
  var response;
  try {
    response = await http.post(server,
        body: data, headers: {"Content-Type": "application/json"});
  } catch (e) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      backgroundColor: Color.fromRGBO(255, 20, 20, 1.0),
      content: new Text("Failed to send message"),
    ));
    return;
  }

  if (response.statusCode != 201) {
    Scaffold.of(context).showSnackBar(new SnackBar(
      backgroundColor: Color.fromRGBO(255, 20, 20, 1.0),
      content: new Text("Failed to send message"),
    ));
    throw Exception('Failed to send');
  } else {
    Scaffold.of(context).showSnackBar(new SnackBar(
      content: new Text("Message '$msg' sent!"),
    ));
  }
}

class Reason {
  final String text;

  Reason({this.text});

  factory Reason.fromJson(Map<String, dynamic> json) {
    return Reason(text: json['text']);
  }
}
