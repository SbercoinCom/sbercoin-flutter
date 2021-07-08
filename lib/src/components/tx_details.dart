import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<List<Tag>> fetchPhotos(String address) async {
  final response = await http.Client()
      .get(Uri.parse('https://explorer.sbercoin.com/api/address/$address/basic-txs'));

  // Use the compute function to run parsePhotos in a separate isolate.
  return compute(parsePhotos, response.body);
}
class Tag {
  final String id;
  final int confirmations;
  final int? blockHeight;
  final String? blockHash;
  final int? timestamp;
  final String type;
  final String amount;

  Tag({
    required this.id, 
    required this.confirmations, 
    this.blockHeight, 
    this.blockHash, 
    this.timestamp, 
    required this.type, 
    required this.amount
  });

  factory Tag.fromJson(dynamic json) {
    return Tag(
      id: json['id'] as String, 
      confirmations: json['confirmations'] as int,
      blockHash: json['blockHash'] as String,
      blockHeight: json['blockHeight'] as int,
      timestamp: json['timestamp'] as int,
      type: json['type'] as String,
      amount: json['amount'] as String,
      );
  }

  @override
  String toString() {
    return '{ ${this.id}, ${this.confirmations} }';
  }
}
// A function that converts a response body into a List<Photo>.
List<Tag> parsePhotos(String responseBody) {
  final tagObjsJson = jsonDecode(responseBody)['transactions'] as List;
  List<Tag> tagObjs = tagObjsJson.map((tagJson) => Tag.fromJson(tagJson)).toList();
  return tagObjs;

  //return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}


class MyApp extends StatelessWidget {

  MyApp(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {

    return MyHomePage(address);
  }
}

class MyHomePage extends StatelessWidget {

  MyHomePage(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Tag>>(
        future: fetchPhotos(address),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? TodosScreen(todos: snapshot.data!)
              : Center(child: CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0),));
        },
      );
  }
}

class TodosScreen extends StatelessWidget {
  final List<Tag> todos;
  late String txType;

  TodosScreen({Key? key, required this.todos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (todos.length > 0)
    return ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          if(todos[index].type == 'send')
            txType = AppLocalizations.of(context)!.sentTx;
          else if(todos[index].type == 'receive')
            txType = AppLocalizations.of(context)!.received;
          else if(todos[index].type == 'contract')
            txType = AppLocalizations.of(context)!.sentToContract;
          else if(todos[index].type == 'gas-refund')
            txType = AppLocalizations.of(context)!.gasRefunded;
          else if(todos[index].type == 'block-reward')
            txType = AppLocalizations.of(context)!.mined;
          bool isOutTx = double.parse(todos[index].amount) < 0;
          return ListTile(
            title: Wrap(children: [
              Row (children: [
                Text(todos[index].id.substring(0, 35) + '...'),
              ]),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(txType,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                Text((double.parse(todos[index].amount)/1e7).toStringAsFixed(7) + ' SBER',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: isOutTx ? Colors.red[300] : Colors.green[800],
                  )
                )
                ],
              ),              
              Divider()
            ]),
            // When a user taps the ListTile, navigate to the DetailScreen.
            // Notice that you're not only creating a DetailScreen, you're
            // also passing the current todo through to it.
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailScreen(todo: todos[index]),
                ),
              );
            },
          );
        },
        
    );
    else 
      return Center(
        child: Text(AppLocalizations.of(context)!.youHadNotSentTxs,
          style: TextStyle(color: Colors.grey)
        )
      );
  }
}

class DetailScreen extends StatelessWidget {
  // Declare a field that holds the Todo.
  final Tag todo;

  // In the constructor, require a Todo.
  DetailScreen({Key? key, required this.todo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.txDetailes),
      ),
      body: Column(children: [
        Divider(),
        _tile(context, '${todo.id}', AppLocalizations.of(context)!.txID, Icons.paid, 'tx/${todo.id}'),
        Divider(),
        _tile(context, '${todo.blockHash}', AppLocalizations.of(context)!.blockHash, Icons.tag, 'block/${todo.blockHash}'),
        Divider(),
        _tile(context, '${todo.blockHeight}', AppLocalizations.of(context)!.blockHeight, Icons.confirmation_number, 'block/${todo.blockHeight}'),
        Divider(),
        _tile(context, '${todo.timestamp!=null ? DateTime.fromMillisecondsSinceEpoch(todo.timestamp! * 1000) : '-'}', AppLocalizations.of(context)!.timestamp, Icons.history, null),
        Divider(),
        _tile(context, '${formatAmount(todo.amount)} SBER', AppLocalizations.of(context)!.amount, Icons.payments, null),
        Divider(),
      ],)
    );
  }
}

String formatAmount(String amount) {
  double value = double.parse(amount);
  return (value/1e7).toStringAsFixed(7);
}

ListTile _tile(BuildContext context, String title, String subtitle, IconData icon, String? url) => ListTile(
  title: Text(title,
    style: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 15,
    )
  ),
  subtitle: Text(subtitle),
  leading: Icon(
    icon,
    color: Color.fromRGBO(26, 159, 41, 1.0),
  ),
  onTap: () {
    if (url != null) _launchURL('https://explorer.sbercoin.com/$url');
  },
  onLongPress: () {
    Clipboard.setData(new ClipboardData(text: '$title'));
    final snackBar = SnackBar(
      content: Text(AppLocalizations.of(context)!.copied),
      action: SnackBarAction(
        label: AppLocalizations.of(context)!.undo,
        textColor: Color.fromRGBO(26, 159, 41, 1.0),
        onPressed: () {},
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  },
);

void _launchURL(_url) async =>
    await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';
