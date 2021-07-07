import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class WalletInfo extends StatelessWidget{

  WalletInfo({Key? key, required this.walletAddress}) : super(key: key);

  final walletAddress;

  Widget build(BuildContext context) {
    return new Center(child: new Column(
        children: [
          Expanded(child: 
          Container(
            child: MyApp(address: walletAddress),
          ),),
        ]
    ));
  }
}

Future<Address> fetchAddressInfo(String address) async {
  final response =
      await get(Uri.parse('https://explorer.sbercoin.com/api/address/$address'));

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    return Address.fromJson(jsonDecode(response.body));
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    throw Exception('Failed to load album');
  }
}

class Address {
  final String address;
  final String totalBalance;
  final String matureBalance;

  Address({
    required this.address,
    required this.totalBalance,
    required this.matureBalance,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      address: json['addrStr'],
      totalBalance: json['coinBalance'],
      matureBalance: json['mature'],

    );
  }
}

class MyApp extends StatefulWidget {
  MyApp({Key? key, required this.address}) : super(key: key);

  final String address;

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Address> futureAlbum;

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAddressInfo(widget.address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: FutureBuilder<Address>(
            future: futureAlbum,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return 
                Container(child: Column(children: [   
                  Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: 
                      Text(
                        AppLocalizations.of(context)!.availableBalance,
                        style: TextStyle(
                          fontSize: 16
                        ),
                      ),
                  ),
                  Text(
                    (double.parse(snapshot.data!.totalBalance)).toString() + ' SBER',
                    style: TextStyle(
                      fontSize: 24,
                      color: Color.fromRGBO(26, 159, 41, 1.0),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: Text(AppLocalizations.of(context)!.immatureBalance),
                  ),
                  Text(
                    (double.parse(snapshot.data!.totalBalance) - double.parse(snapshot.data!.matureBalance)/1e7).toString() + ' SBER',
                    style: TextStyle(color: Color.fromRGBO(183, 184, 20, 1.0)),
                  ),
                  Padding(
                    padding: EdgeInsets.only(top: 16.0),
                    child: Text(
                    widget.address,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    )
                  ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                    IconButton(
              icon: const Icon(Icons.content_copy),
              iconSize: 15.0,
              //color: Colors.white,
              onPressed: () {
                Clipboard.setData(new ClipboardData(text: '${widget.address}'));
                final snackBar = SnackBar(
                  content: Text(AppLocalizations.of(context)!.addressCopied),
                  action: SnackBarAction(
                    label: AppLocalizations.of(context)!.undo,
                    textColor: Color.fromRGBO(26, 159, 41, 1.0),
                    onPressed: () {},
                  ),
                );
                // Find the ScaffoldMessenger in the widget tree
                // and use it to show a SnackBar.
                ScaffoldMessenger.of(context).showSnackBar(snackBar);
              },
            ),
            IconButton(
              icon: const Icon(Icons.qr_code),
              iconSize: 15.0,
              //color: Colors.white,
              onPressed: () { 
                showDialog(context: context,
                  builder: (BuildContext context){
                    return AlertDialog(
                      content: Container(
                        child: QrImage(
                          data: 'sbercoin:${widget.address}}',
                          size: 250,
                        ),
                        height: 250,
                        width: 250,
                      ),
                    );
                  }
                );
              },
            ),

                  ],)
                ],));
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              // By default, show a loading spinner.
              return CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0),);
            },
          ),
        ),
      );
  }
}
