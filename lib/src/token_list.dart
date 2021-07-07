import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<List<Token>> fetchAddressInfo(String address) async {
  final response = await http.Client()
      .get(Uri.parse('https://explorer.sbercoin.com/api/address/$address/'));

  // Use the compute function to run parseResponse in a separate isolate.
  return compute(parseResponse, response.body);
}
class Token {
  final String address;
  final int decimals;
  final String balance;
  final String name;
  final String symbol;

  Token({
    required this.address, 
    required this.decimals, 
    required this.balance, 
    required this.name, 
    required this.symbol, 
  });

  factory Token.fromJson(dynamic json) {
    return Token(
      address: json['address'] as String, 
      decimals: json['decimals'] as int,
      name: json['name'] as String,
      symbol: json['symbol'] as String,
      balance: json['balance'] as String,
      );
  }

  @override
  String toString() {
    return '{ ${this.symbol}, ${this.balance} }';
  }
}
// A function that converts a response body into a List<Photo>.
List<Token> parseResponse(String responseBody) {
  final tokenObjsJson = jsonDecode(responseBody)['qrc20Balances'] as List;
  List<Token> tokenObjs = tokenObjsJson.map((tokenJson) => Token.fromJson(tokenJson)).toList();
  return tokenObjs;

  //return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
}


class TokenList extends StatelessWidget {

  TokenList(this.address);

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
    return FutureBuilder<List<Token>>(
        future: fetchAddressInfo(address),
        builder: (context, snapshot) {
          if (snapshot.hasError) print(snapshot.error);

          return snapshot.hasData
              ? TodosScreen(todos: snapshot.data!)
              : Center(child: CircularProgressIndicator(color: Color.fromRGBO(26, 159, 41, 1.0),));
        },
      );
  }
}

class TodosScreen extends StatelessWidget {
  final List<Token> todos;

  TodosScreen({Key? key, required this.todos}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: todos.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Wrap(children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(todos[index].name),
                  Text((double.parse(todos[index].balance)/(pow(10, todos[index].decimals))).toString() + ' ' + todos[index].symbol)
                ],
              ),
            ],),
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
  }
}

class DetailScreen extends StatelessWidget {
  // Declare a field that holds the Todo.
  final Token todo;

  // In the constructor, require a Todo.
  DetailScreen({Key? key, required this.todo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the Todo to create the UI.
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.your + '${todo.name}'),
      ),
      body: Column(children: [
        Divider(),
        _tile(context, '${todo.address}', AppLocalizations.of(context)!.contractAddress, Icons.paid, 'contract/${todo.address}'),
        Divider(),
        _tile(context, '${todo.name}', AppLocalizations.of(context)!.name, Icons.tag, null),
        Divider(),
        _tile(context, '${todo.symbol}', AppLocalizations.of(context)!.symbol, Icons.confirmation_number, null),
        Divider(),
        _tile(context, '${todo.decimals}', AppLocalizations.of(context)!.decimals, Icons.history, null),
        Divider(),
        _tile(context, '${double.parse(todo.balance)/(pow(10, todo.decimals))}', AppLocalizations.of(context)!.amount, Icons.payments, null),
        Divider(),
      ],)
    );
  }
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
