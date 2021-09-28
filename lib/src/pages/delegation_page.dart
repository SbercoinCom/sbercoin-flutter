import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/src/configuration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coinslib/coinslib.dart' as BitcoinLibrary;
import 'package:coinslib/src/utils/script.dart';
import 'package:coinslib/src/utils/constants/op.dart';
import "package:hex/hex.dart";
import 'package:base58check/base58.dart';
import '/src/constants.dart' as CONSTANTS;
import 'package:http/http.dart';
import 'screen_lock_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:web3dart/crypto.dart';
import '/src/components/tx_functions.dart';

class Delegation extends StatefulWidget {
  Delegation(this.address);

  final String address;

  @override
  State<StatefulWidget> createState() => DelegationState(address);
}

class DelegationState extends State<Delegation> {

  DelegationState(this.address);

  final String address;

  String? superStaker;

  FocusNode addressFocusNode = new FocusNode();
  TextEditingController addressController= new TextEditingController();
  bool? addressValidator;
  int _feeValue = 10;

  @override
  void initState() {
    super.initState();
  }

  void _requestAddressFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(addressFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Superstaker>(
      future: fetchAddressInfo(address),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data?.address != null) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.superstaker + ':'),
                    Text(snapshot.data!.address),
                    Text(''),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(AppLocalizations.of(context)!.fee + ': '),
                        Text(snapshot.data!.fee.toString() + '%'),
                    ],),
                    Text(''),
                    ElevatedButton(
                      onPressed: () => navigate(true), 
                      child: Text(AppLocalizations.of(context)!.removeDelegation),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
                      ),
                    )
                  ],
                )
              )
            );
          }
          else {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(AppLocalizations.of(context)!.youDontDelegateCoins,
                      style: TextStyle(color: Colors.grey)
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        focusNode: addressFocusNode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: AppLocalizations.of(context)!.superstakerAddress,
                          labelStyle: (addressValidator != true) ? (addressFocusNode.hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey)) : TextStyle(color:Colors.red),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: (addressValidator != true) ? Color.fromRGBO(26, 159, 41, 1.0) : Colors.red),
                          ),
                        ),
                        minLines: 1,
                        maxLines: 1,
                        maxLength: 34,
                        controller: addressController,
                        cursorColor: Color.fromRGBO(26, 159, 41, 1.0),
                        onTap: _requestAddressFocus,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.allow(RegExp(r'^$|^[S][a-km-zA-HJ-NP-Z1-9]{0,33}$')),
                        ],
                      )
                    ),
                    Text(AppLocalizations.of(context)!.superstakerFee + ' = ' + _feeValue.toString() + '%'),
                    Slider(
                      value: _feeValue.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 100,
                      label: _feeValue.toStringAsFixed(0) + '%',
                      activeColor: Color.fromRGBO(26, 159, 41, 1.0),
                      inactiveColor: Color.fromRGBO(26, 159, 41, 0.3),
                      onChanged: (double value) {
                        setState(() {
                          _feeValue = value.round();
                        });
                      },
                    ),
                    ElevatedButton(
                      onPressed: () => navigate(false),
                      child: Text(AppLocalizations.of(context)!.delegateCoins),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
                      ),
                    )
                  ],
                )
              )
            );
          }
        }
        else 
          return Center(
            child: CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0))
          );
      }
    );
  }

  void navigate(bool isDelegationRemoving) async {
    if (addressController.text.length < 34)
      setState(() {
        addressValidator = true;
      });
    else
      setState(() {
        addressValidator = false;
      });

    var screenLockResult;

    if (!addressValidator! || isDelegationRemoving) 
      screenLockResult = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ScreenLockPage())
      );

    if (screenLockResult == true)
      buildTxToDelegationContract(isDelegationRemoving);

  }

  void buildTxToDelegationContract(bool isDelegationRemoving) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    final keyPair = BitcoinLibrary.ECPair.fromWIF(configurationService.getWIF()!, network: CONSTANTS.sbercoinNetwork);
    final fee = (0.001 * CONSTANTS.SBER_DECIMALS).toInt() + 20 * 2500000;
    var totalValue = 0;
    var encodedData;
    if (isDelegationRemoving) {
      encodedData = '3d666e8b';
    }
    else {
      encodedData = '4c0e968c';
      final superstakerAddress = HEX.encode(Base58Decoder('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz').convert(addressController.text)).substring(2,42);
      encodedData += superstakerAddress.padLeft(64, '0');
      final stakerFee = _feeValue.toRadixString(16).padLeft(64, '0');
      encodedData += stakerFee;
      encodedData += '60'.padLeft(64, '0'); //shift for bytes parameter
      final hash = sha256d(Uint8List.fromList(utf8.encode(CONSTANTS.sbercoinNetwork.messagePrefix) + [40] + utf8.encode(superstakerAddress)));
      final signedMsg = sign(hash, keyPair.privateKey!);
      final sig = Uint8List.fromList(unsignedIntToBytes(signedMsg.r)) + Uint8List.fromList(unsignedIntToBytes(signedMsg.s));
      final signature = HEX.encode([signedMsg.v - 27 + (keyPair.compressed ? 31 : 27)] + sig);
      encodedData += (sig.length + 1).toRadixString(16).padLeft(64, '0') + signature.padRight((signature.length / 64).ceil() * 64, '0');
    }

    List<UTXO> inputs = await selectP2SHUtxos(context, address, 0, fee);
                
    if (inputs.isNotEmpty) {
      final txb = new BitcoinLibrary.TransactionBuilder(network: CONSTANTS.sbercoinNetwork);
      txb.setVersion(1);
      for (var i = 0; i < inputs.length; i++) {
        txb.addInput(
          inputs[i].id,
          inputs[i].outputIndex
        );
        totalValue += inputs[i].value;
      }

      var chunks = List<dynamic>.generate(6, (_) => null);
      chunks[0] = OPS['OP_4'];
      chunks[1] = number2Buffer(2500000);
      chunks[2] = number2Buffer(20);
      chunks[3] = Uint8List.fromList(HEX.decode(encodedData));
      chunks[4] = Uint8List.fromList(HEX.decode('0000000000000000000000000000000000000086'));
      chunks[5] = 0xc2; //OP_CALL

      var contract = compile(chunks);
      txb.addOutput(contract, 0);

      if (totalValue > fee)
        txb.addOutput(address, totalValue - fee);

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, keyPair: keyPair);
      }

      addressController.clear();

      broadcastTx(context, txb.build().toHex());
    }
  }

  Uint8List sha256d (Uint8List data) {
    return Uint8List.fromList(crypto.sha256.convert(Uint8List.fromList(crypto.sha256.convert(data).bytes)).bytes);
  }
}


Future<Superstaker> fetchAddressInfo(String address) async {
  final response =
      await get(Uri.parse('https://explorer.sbercoin.com/api/address/$address'));

  if (response.statusCode == 200) {
    return Superstaker.fromJson(jsonDecode(response.body));
  } else {
    throw Exception('Failed to load address info');
  }
}

class Superstaker {
  final String address;
  final int fee;

  Superstaker({
    required this.address,
    required this.fee,
  });

  factory Superstaker.fromJson(Map<String, dynamic> json) {
    return Superstaker(
      address: json['superStaker'],
      fee: json['fee'],
    );
  }
}