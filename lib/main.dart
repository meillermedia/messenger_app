import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() {
  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: Firebase.initializeApp(),
        builder: (context, snapshot) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                title: Text("Messenger App"),
              ),
              body: Note(),
            ),
            debugShowCheckedModeBanner: false,
          );
        });
  }
}

class Note extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return NoteState();
  }
}

class NoteState extends State<Note> {
  final txtController = new TextEditingController();
  final scrollController = new ScrollController();
  final nickController = new TextEditingController();

  var messages;
  var users;
  var dates;

  @override
  void initState() {
    super.initState();
    _clearAll();
    _loadAll();
  }

  _clearAll() {
    setState(() {
      messages = <String>[];
      dates = <Timestamp>[];
      users = <String>[];
    });
  }

  _loadAll() {
    var stream = FirebaseFirestore.instance
        .collection('messages')
        .orderBy('date')
        .snapshots();
    stream.forEach((QuerySnapshot snap) {
      snap.docs.forEach((el) {
        var doc = el.data();
        if (doc != null) {
          _addMessage(doc['user'], doc['message'], doc['date']);
        }
      });
    });
  }

  void _addMessage(String user, String value, Timestamp date) {
    setState(() {
      messages.insert(0, value);
      users.insert(0, user);
      dates.insert(0, date);
      if (messages.length > 200) {
        messages.removeLast();
        users.removeLast();
        dates.removeLast();
      }
    });
  }

  String _date(Timestamp ts) {
    DateTime d = ts.toDate();
    return "${d.day}.${d.month}. ${d.hour}:${d.minute}.${d.second}";
  }

  void _saveMsg(String msg) async {
    CollectionReference fire =
        FirebaseFirestore.instance.collection('messages');
    String usern = nickController.text == "" ? "NN" : nickController.text;
    await fire
        .add({"message": msg, "user": usern, "date": DateTime.now().toLocal()});
  }

  void sendMsg(String msg) {
    if (msg.length == 0) return;
    _saveMsg(msg);
    scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500),
      curve: ElasticInCurve(),
    );
    txtController.clear();
  }

  Color _getColor(String nick) {
    if (nick.length > 0) {
      int code = nick.codeUnitAt(0) % 50;
      return Color.fromARGB(255, code * 5, code * 5, 255 - code * 5);
    } else {
      return Colors.brown.shade800;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
            flex: 4,
            child: ListView.builder(
                reverse: true,
                controller: scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  var col = _getColor(users[index]);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: col,
                      child: Text('${users[index].substring(0, 1)}'),
                    ),
                    title: Container(
                      child: Text('${messages[index]}'),
                      decoration: BoxDecoration(
                        color: col.withAlpha(50),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(10.0),
                          topLeft: Radius.circular(10.0),
                          bottomRight: Radius.circular(10.0),
                        ),
                      ),
                      padding: EdgeInsets.all(10),
                    ),
                    subtitle: Text(_date(dates[index])),
                  );
                })),
        Expanded(
          flex: 1,
          child: Row(
            children: [
              Expanded(
                  flex: 1,
                  child: TextField(
                    controller: nickController,
                    decoration: InputDecoration(hintText: "Nickname"),
                  )),
              Expanded(
                  flex: 2,
                  child: TextField(
                    controller: txtController,
                    onSubmitted: (txt) => sendMsg(txtController.text),
                    decoration: InputDecoration(hintText: "Enter Message"),
                  )),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: () => sendMsg(txtController.text),
          child: Text("Send!"),
          style: ButtonStyle(
              elevation: MaterialStateProperty.all(4.0),
              backgroundColor: MaterialStateProperty.all(Colors.blueGrey)),
        ),
      ],
    );
  }
}
