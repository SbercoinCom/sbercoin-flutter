import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '/src/constants.dart' as CONSTANTS;

class WalletInfo extends StatefulWidget {

  WalletInfo({Key? key, required this.walletAddress}) : super(key: key);

  final walletAddress;

  @override
  WalletInfoState createState() => WalletInfoState();
}

Future<AddressInfo> fetchAddressInfo(String address) async {
  final response =
      await get(Uri.parse('https://explorer.sbercoin.com/api/address/$address'));

  if (response.statusCode == 200) {
    return AddressInfo.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load address info');
  }
}

class AddressInfo {
  final String address;
  final String totalBalance;
  final String matureBalance;

  AddressInfo({
    required this.address,
    required this.totalBalance,
    required this.matureBalance,
  });

  factory AddressInfo.fromJson(Map<String, dynamic> json) {
    return AddressInfo(
      address: json['addrStr'],
      totalBalance: json['coinBalance'],
      matureBalance: json['mature'],

    );
  }
}

class WalletInfoState extends State<WalletInfo> {

  late Future<AddressInfo> addressInfo;

  @override
  void initState() {
    super.initState();
    addressInfo = fetchAddressInfo(widget.walletAddress);
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: FutureBuilder<AddressInfo>(
          future: addressInfo,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Column(
                  children: [   
                    Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
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
                      (double.parse(snapshot.data!.totalBalance) - double.parse(snapshot.data!.matureBalance) / CONSTANTS.SBER_DECIMALS).toString() + ' SBER',
                      style: TextStyle(color: Color.fromRGBO(183, 184, 20, 1.0)),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 16.0),
                      child: Text(
                        widget.walletAddress,
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
                          onPressed: () {
                            Clipboard.setData(new ClipboardData(text: '${widget.walletAddress}'));
                            final snackBar = SnackBar(
                              content: Text(AppLocalizations.of(context)!.addressCopied),
                              action: SnackBarAction(
                                label: AppLocalizations.of(context)!.undo,
                                textColor: Color.fromRGBO(26, 159, 41, 1.0),
                                onPressed: () {},
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.qr_code),
                          iconSize: 15.0,
                          onPressed: () { 
                            showDialog(context: context,
                              builder: (BuildContext context){
                                return AlertDialog(
                                  content: Container(
                                    child: QrImage(
                                      data: 'sbercoin:${widget.walletAddress}}',
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
                      ],
                    )
                  ]
                
              );
            } else if (snapshot.hasError) {
              return Text("${snapshot.error}");
            }
            // By default, show a loading spinner.
            return CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0),);
          },
        ),
    );
  }
}
