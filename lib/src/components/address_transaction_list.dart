import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '/src/constants.dart' as CONSTANTS;

Future<List<Transaction>> fetchTxs(String address) async {
  final response = await http.Client()
      .get(Uri.parse('https://explorer.sbercoin.com/api/address/$address/basic-txs'));

  return compute(parseTxs, response.body);
}

class Transaction {
  final String id;
  final int confirmations;
  final int? blockHeight;
  final String? blockHash;
  final int? timestamp;
  final String type;
  final String amount;

  Transaction({
    required this.id, 
    required this.confirmations, 
    this.blockHeight, 
    this.blockHash, 
    this.timestamp, 
    required this.type, 
    required this.amount
  });

  factory Transaction.fromJson(dynamic json) {
    return Transaction(
      id: json['id'] as String, 
      confirmations: json['confirmations'] as int,
      blockHash: json['blockHash'] as String,
      blockHeight: json['blockHeight'] as int,
      timestamp: json['timestamp'] as int,
      type: json['type'] as String,
      amount: json['amount'] as String,
    );
  }
}

List<Transaction> parseTxs(String responseBody) {
  final objsJson = jsonDecode(responseBody)['transactions'] as List;
  List<Transaction> objs = objsJson.map((txJson) => Transaction.fromJson(txJson)).toList();
  return objs;
}

class TxsListPage extends StatelessWidget {

  TxsListPage(this.address);

  final String address;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Transaction>>(
      future: fetchTxs(address),
      builder: (context, snapshot) {
        if (snapshot.hasError) 
          print(snapshot.error);
        return snapshot.hasData
          ? TxsList(txs: snapshot.data!)
          : Center(child: CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0)));
      },
    );
  }
}

class TxsList extends StatelessWidget {
  final List<Transaction> txs;

  late String txType;

  TxsList({Key? key, required this.txs}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    FocusScope.of(context).unfocus();
    if (txs.length > 0)
    return ListView.builder(
      itemCount: txs.length,
      itemBuilder: (context, index) {
        if(txs[index].type == 'send')
          txType = AppLocalizations.of(context)!.sentTx;
        else if(txs[index].type == 'receive')
          txType = AppLocalizations.of(context)!.received;
        else if(txs[index].type == 'contract')
          txType = AppLocalizations.of(context)!.sentToContract;
        else if(txs[index].type == 'gas-refund')
          txType = AppLocalizations.of(context)!.gasRefunded;
        else if(txs[index].type == 'block-reward')
          txType = AppLocalizations.of(context)!.mined;

        bool isOutTx = double.parse(txs[index].amount) < 0;

        return ListTile(
          title: Wrap(
            children: [
              Row (
                children: [
                  Text(txs[index].id.substring(0, 35) + '...'),
                ]
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(txType,
                    textAlign: TextAlign.right,
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text((double.parse(txs[index].amount) / CONSTANTS.SBER_DECIMALS).toStringAsFixed(7) + ' SBER',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: isOutTx ? Colors.red[300] : Colors.green[800],
                    )
                  )
                ],
              ),              
              Divider()
            ]
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(tx: txs[index]),
              ),
            );
          },
        );
      }  
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
  final Transaction tx;

  DetailScreen({Key? key, required this.tx}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.txDetailes),
      ),
      body: Column(
        children: [
          Divider(),
          _tile(context, '${tx.id}', AppLocalizations.of(context)!.txID, Icons.paid, 'tx/${tx.id}'),
          Divider(),
          _tile(context, '${tx.blockHash}', AppLocalizations.of(context)!.blockHash, Icons.tag, 'block/${tx.blockHash}'),
          Divider(),
          _tile(context, '${tx.blockHeight}', AppLocalizations.of(context)!.blockHeight, Icons.confirmation_number, 'block/${tx.blockHeight}'),
          Divider(),
          _tile(context, '${tx.timestamp!=null ? DateTime.fromMillisecondsSinceEpoch(tx.timestamp! * 1000) : '-'}', AppLocalizations.of(context)!.timestamp, Icons.history, null),
          Divider(),
          _tile(context, '${formatAmount(tx.amount)} SBER', AppLocalizations.of(context)!.amount, Icons.payments, null),
          Divider(),
        ]
      )
    );
  }
}

String formatAmount(String amount) {
  double value = double.parse(amount);
  return (value / CONSTANTS.SBER_DECIMALS).toStringAsFixed(7);
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
