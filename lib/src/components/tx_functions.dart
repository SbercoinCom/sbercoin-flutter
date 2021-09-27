import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Uint8List number2Buffer(int num) {
  List<int> buffer = List.empty(growable: true);
  var neg = (num < 0);
  num = num.abs();

  while(num > 0) {
    buffer.add(num & 0xff);
    num = num >> 8;
  }

  var top = buffer[buffer.length - 1];

  if (top & 0x80 != 0x00) {
    buffer[buffer.length] = neg ? 0x80 : 0x00;
  }
  else if (neg) {
    buffer[buffer.length - 1] = top | 0x80;
  }

  return Uint8List.fromList(buffer);
}


void broadcastTx(BuildContext context, String datahex) async {
  Map<String, String> data = {
    'rawtx': datahex,
  };

  var client = new Client();

  try {
    var uriResponse = await client.post(Uri.parse('https://explorer.sbercoin.com/api/tx/send'),
      body: data);
    var res = HttpResponse.fromJson(jsonDecode(uriResponse.body));
    if (uriResponse.statusCode == 200) {
      showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: res.getStatus() == 0 ? Text(AppLocalizations.of(context)!.txSent) : Text(AppLocalizations.of(context)!.txError),
          content: InkWell(
            child: Text(
              res.getTxResult(),
              style: TextStyle(decoration: TextDecoration.underline),
            ),
            onTap: res.getStatus() == 0 ? () async {
              var url = 'https://explorer.sbercoin.com/tx/${res.getTxResult()}';
              if (await canLaunch(url)) {
                await launch(
                  url,
                );
              }
            } : null,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'OK');
              },  
              child: const Text('OK', style: TextStyle(color: Color.fromRGBO(26, 159, 41, 1.0)),),
            ),
          ],
        ),
      );
    }
  } finally {
    client.close();
  }
}

selectP2SHUtxos(context, address, amount, fee) async {
  List<UTXO> unspentTransactions = await fetchUtxos(address);
  List<UTXO> matureList = List.empty(growable: true);
  List<UTXO> immatureList = List.empty(growable: true);

  for(var i = 0; i < unspentTransactions.length; i++) {
    if(unspentTransactions[i].isStake == false || unspentTransactions[i].confirmations >= 500)
      matureList.add(unspentTransactions[i]);
    else
      immatureList.add(unspentTransactions[i]);
  }

  matureList.sort((a, b) {return a.value - b.value;});
  immatureList.sort((a, b) {return b.confirmations - a.confirmations;});

  var value = amount + fee;
  List<UTXO> find = List.empty(growable: true);
  var findTotal = 0;

  for (var i = 0; i < matureList.length; i++) {
    var tx = matureList[i];
    findTotal = findTotal + tx.value;
    find.add(tx);
    if (findTotal >= value) break;
  }

  if (value > findTotal) {
    showDialog<String>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.txError),
        content: InkWell(
          child: Text((AppLocalizations.of(context)!.youDontHaveEnoughCoins))
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context, 'OK');
            },  
            child: const Text('OK', 
              style: TextStyle(color: Color.fromRGBO(26, 159, 41, 1.0))
            )
          )
        ]
      ),
    );
  }
  return find;
}

Future<List<UTXO>> fetchUtxos(String address) async {
  final response = await Client()
      .get(Uri.parse('https://explorer.sbercoin.com/api/address/$address/utxo'));

  return compute(parseUtxos, response.body);
}

class UTXO {
  final String id;
  final int confirmations;
  final int outputIndex;
  final int value;
  final bool isStake;

  UTXO({
    required this.id, 
    required this.confirmations, 
    required this.outputIndex, 
    required this.value, 
    required this.isStake
  });

  factory UTXO.fromJson(dynamic json) {
    return UTXO(
      id: json['transactionId'], 
      confirmations: json['confirmations'] as int,
      outputIndex: json['outputIndex'] as int,
      value: json['value'] as int,
      isStake: json['isStake'] as bool
    );
  }
}

List<UTXO> parseUtxos(String responseBody) {
  final utxoObjsJson = jsonDecode(responseBody) as List;
  List<UTXO> utxoObjs = utxoObjsJson.map((utxoJson) => UTXO.fromJson(utxoJson)).toList();
  return utxoObjs;
}

class HttpResponse {
  final String? message;
  final int status;
  final String? txid;

  HttpResponse({
    this.message, 
    required this.status, 
    this.txid, 
  });

  factory HttpResponse.fromJson(dynamic json) {
    return HttpResponse(
      message: json['message'], 
      status: json['status'] as int,
      txid: json['txid']
      );
  }

  String getTxResult() {
    if (txid != null)
      return txid!;
    else if (message != null)
      return message!;
    else return 'Something gone wrong!';
  }

  int getStatus() {
    return status;
  }
}