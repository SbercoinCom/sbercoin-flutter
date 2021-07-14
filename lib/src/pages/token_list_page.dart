import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<List<Token>> fetchData(String address) async {
  final response = await Client()
      .get(Uri.parse('https://explorer.sbercoin.com/api/address/$address/'));

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
}

List<Token> parseResponse(String responseBody) {
  final tokenObjsJson = jsonDecode(responseBody)['qrc20Balances'] as List;
  List<Token> tokenObjs = tokenObjsJson.map((tokenJson) => Token.fromJson(tokenJson)).toList();
  return tokenObjs;
}

class TokenList extends StatelessWidget {

  TokenList(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    return FutureBuilder<List<Token>>(
      future: fetchData(address),
      builder: (context, snapshot) {
        if (snapshot.hasError) print(snapshot.error);
        return snapshot.hasData
          ? TokenListScreen(tokens: snapshot.data!)
          : Center(child: CircularProgressIndicator(color: Color.fromRGBO(26, 159, 41, 1.0)));
      },
    );
  }
}

class TokenListScreen extends StatelessWidget {
  final List<Token> tokens;

  TokenListScreen({Key? key, required this.tokens}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (tokens.length > 0)
      return ListView.builder(
        itemCount: tokens.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Wrap(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(tokens[index].name),
                    Text((double.parse(tokens[index].balance)/(pow(10, tokens[index].decimals))).toString() + ' ' + tokens[index].symbol)
                  ],
                ),
              ]
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TokenDetailScreen(token: tokens[index]),
                ),
              );
            },
          );
        },
      );
    else 
      return Center(
        child: Text(AppLocalizations.of(context)!.youDontHaveTokens,
          style: TextStyle(color: Colors.grey)
        )
      );
  }
}

class TokenDetailScreen extends StatelessWidget {
  final Token token;

  TokenDetailScreen({Key? key, required this.token}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.your + '${token.name}'),
      ),
      body: Column(
        children: [
          Divider(),
          _tile(context, '${token.address}', AppLocalizations.of(context)!.contractAddress, Icons.paid, 'contract/${token.address}'),
          Divider(),
          _tile(context, '${token.name}', AppLocalizations.of(context)!.name, Icons.tag, null),
          Divider(),
          _tile(context, '${token.symbol}', AppLocalizations.of(context)!.symbol, Icons.confirmation_number, null),
          Divider(),
          _tile(context, '${token.decimals}', AppLocalizations.of(context)!.decimals, Icons.history, null),
          Divider(),
          _tile(context, '${double.parse(token.balance)/(pow(10, token.decimals))}', AppLocalizations.of(context)!.amount, Icons.payments, null),
          Divider()
        ]
      )
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
  }
);

void _launchURL(_url) async =>
    await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';
