import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '/src/components/qr_scan.dart';
import '/src/configuration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:coinslib/coinslib.dart';
import 'package:coinslib/src/utils/script.dart';
import 'package:coinslib/src/utils/constants/op.dart';
import "package:hex/hex.dart";
import 'package:base58check/base58.dart';
import '/src/constants.dart' as CONSTANTS;
import 'token_list_page.dart' as TokenList;
import 'screen_lock_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '/src/components/tx_functions.dart';

class SendTransaction extends StatefulWidget {
  SendTransaction(this.address);

  final String address;

  @override
  State<StatefulWidget> createState() => SendTransactionState(address, inputAddress: null, inputValue: null);
}

class SendTransactionState extends State<SendTransaction> {

  SendTransactionState(this.address, {this.inputAddress, this.inputValue});

  final String address;

  String? inputAddress;
  String? inputValue;

  late String alertText;
  late TextEditingController addressController;
  late TextEditingController valueController;

  FocusNode addressFocusNode = new FocusNode();
  FocusNode valueFocusNode = new FocusNode();
  late String dropdownValue;
  Map<String, String> dropdownItems = new Map();//List.filled(1, 'SBER', growable: true);

  late List<TokenList.Token>? tokens;

  double _feeValue = 0.003;
  double _gasLimitValue = 200000;
  double _gasPriceValue = 3;
  bool? addressValidator;
  bool? valueValidator;

  @override
  void initState() {
    super.initState();
    addressController = TextEditingController(text: inputAddress);
    valueController = TextEditingController(text: inputValue);
    dropdownItems['SBER'] = 'SBER';
    dropdownValue = 'SBER';
  }

  void _requestValueFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(valueFocusNode);
    });
  }

  void _requestAddressFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(addressFocusNode);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TokenList.Token>>(
      future: fillTokens(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          tokens = snapshot.data;
          return Scaffold(
            body: SingleChildScrollView(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: TextField(
                        focusNode: addressFocusNode,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: AppLocalizations.of(context)!.to,
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
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: TextField(
                              focusNode: valueFocusNode,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: AppLocalizations.of(context)!.value,
                                labelStyle: (valueValidator != true) ? (valueFocusNode.hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey)) : TextStyle(color:Colors.red),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: (valueValidator != true) ? Color.fromRGBO(26, 159, 41, 1.0) : Colors.red),
                                ),
                              ),
                              minLines: 1,
                              maxLines: 1,
                              controller: valueController,
                              keyboardType: TextInputType.number,
                              cursorColor: Color.fromRGBO(26, 159, 41, 1.0),
                              onTap: _requestValueFocus,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp('[0-9.]'))
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 15.0),
                            child: Center(
                              child: DropdownButton<String>(
                                value: dropdownValue,
                                icon: const Icon(Icons.arrow_downward),
                                iconSize: 24,
                                elevation: 16,
                                underline: Container(
                                  height: 2,
                                ),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    dropdownValue = newValue!;
                                  });
                                },
                                items: dropdownItems.entries.map((item) {
                                  var temp = Map();
                                  temp.addAll(dropdownItems);
                                  temp.remove(item.key);
                                  var isTokenListHasDuplicateSymbols = temp.containsValue(item.value);
                                  return DropdownMenuItem(
                                  value: item.key, 
                                  child: Text(
                                    item.value + (
                                      (item.key != 'SBER' && isTokenListHasDuplicateSymbols) ? (' (' + item.key.substring(0, 5) + '...)') : ''
                                    )
                                  )
                                );}).toList(),
                              )
                            )
                          )
                        ]
                      )
                    ),
                    Divider(
                      height: 30,
                      thickness: 0,
                      indent: 1000,
                      endIndent: 1000,
                    ),
                    Text(AppLocalizations.of(context)!.fee_greph),
                    Slider(
                      value: _feeValue,
                      min: 0.001,
                      max: 0.010001,
                      divisions: 9,
                      label: _feeValue.toStringAsFixed(3),
                      activeColor: Color.fromRGBO(26, 159, 41, 1.0),
                      inactiveColor: Color.fromRGBO(26, 159, 41, 0.3),
                      onChanged: (double value) {
                        setState(() {
                          _feeValue = value;
                        });
                      },
                    ),
                    if (dropdownValue != 'SBER') Text(AppLocalizations.of(context)!.gasLimit),
                    if (dropdownValue != 'SBER') Slider(
                      value: _gasLimitValue,
                      min: 100000,
                      max: 1000000.1,
                      divisions: 18,
                      label: _gasLimitValue.round().toString(),
                      activeColor: Color.fromRGBO(26, 159, 41, 1.0),
                      inactiveColor: Color.fromRGBO(26, 159, 41, 0.3),
                      onChanged: (double value) {
                        setState(() {
                          _gasLimitValue = value;
                        });
                      },
                    ),
                    if (dropdownValue != 'SBER') Text(AppLocalizations.of(context)!.gasPrice_greph_per_gas),
                    if (dropdownValue != 'SBER') Slider(
                      value: _gasPriceValue,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: _gasPriceValue.round().toString(),
                      activeColor: Color.fromRGBO(26, 159, 41, 1.0),
                      inactiveColor: Color.fromRGBO(26, 159, 41, 0.3),
                      onChanged: (double value) {
                        setState(() {
                          _gasPriceValue = value;
                        });
                      },
                    ),
                    ElevatedButton(
                      child: Text(AppLocalizations.of(context)!.confirm),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
                      ),
                      onPressed: () => _navigate(context),
                    )
                  ]
                )
              )
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Color.fromRGBO(26, 159, 41, 1.0),
              onPressed: () => _scanQR(context),
              child: const Icon(Icons.qr_code_scanner),
            )
          );
        }
        else 
          return Center(
            child: CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0))
          );
      }
    );
  }

  void _navigate(BuildContext context) async {
    try {
      double.parse(valueController.text);
      setState(() {
        valueValidator = false;
      });
    }
    catch (e) {
      setState(() {
        valueValidator = true;
      });
    } 
    if (addressController.text.length < 34)
      setState(() {
        addressValidator = true;
      });
    else
      setState(() {
        addressValidator = false;
      });

    bool? result;

    if (!addressValidator! && !valueValidator!) 
      result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ScreenLockPage())
      );

    if (result == true)
      if (dropdownValue == 'SBER')
        _buildSendCoinTx();
      else _buildTokenTransferTx(dropdownValue);
  }

  void _buildSendCoinTx() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    final keyPair = ECPair.fromWIF(configurationService.getWIF()!, network: CONSTANTS.sbercoinNetwork);
    var fee = (_feeValue * CONSTANTS.SBER_DECIMALS).toInt();
    var totalValue = 0;
    var value = (double.parse(valueController.text) * CONSTANTS.SBER_DECIMALS).toInt();
    List<UTXO> inputs = await selectP2SHUtxos(context, address, value, fee);
                
    if (inputs.isNotEmpty) {
      final txb = new TransactionBuilder(network: CONSTANTS.sbercoinNetwork);
      txb.setVersion(1);
      for (var i = 0; i < inputs.length; i++) {
        txb.addInput(
          inputs[i].id,
          inputs[i].outputIndex
        );
        totalValue += inputs[i].value;
      }

      txb.addOutput(addressController.text, value);

      if (totalValue > value + fee)
        txb.addOutput(address, totalValue - value - fee);

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, keyPair: keyPair);
      }

      addressController.clear();
      valueController.clear();

      broadcastTx(context, txb.build().toHex());
    }
  }

  void _buildTokenTransferTx(String tokenAddress) async {
    var index;
    for (int i = 0; i < tokens!.length; i++)
      if (tokens![i].address == tokenAddress)
        index = i;
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    const transfer = 'a9059cbb';
    final keyPair = ECPair.fromWIF(configurationService.getWIF()!, network: CONSTANTS.sbercoinNetwork);
    var fee = (_feeValue * CONSTANTS.SBER_DECIMALS).toInt() + _gasLimitValue.toInt() * _gasPriceValue.toInt();
    var totalValue = 0;
    var value = (double.parse(valueController.text) * pow(10, tokens![index].decimals)).toInt().toRadixString(16).padLeft(64, '0');
    var receiverAddress = HEX.encode(Base58Decoder('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz').convert(addressController.text)).substring(2,42).padLeft(64, '0');
    List<UTXO> inputs = await selectP2SHUtxos(context, address, 0, fee);
                
    if (inputs.isNotEmpty) {
      final txb = new TransactionBuilder(network: CONSTANTS.sbercoinNetwork);
      txb.setVersion(1);
      for (var i = 0; i < inputs.length; i++) {
        txb.addInput(
          inputs[i].id,
          inputs[i].outputIndex
        );
        totalValue += inputs[i].value;
      }

      var contract =  compile([
        OPS['OP_4'],
        number2Buffer(_gasLimitValue.toInt()),
        (_gasPriceValue.toInt() > 16) ? number2Buffer(_gasPriceValue.toInt()) : Uint8List.fromList([_gasPriceValue.toInt(), 0]),
        Uint8List.fromList(HEX.decode(transfer + receiverAddress + value)),
        Uint8List.fromList(HEX.decode(tokens![index].address)),
        0xc2 //OP_CALL
      ]);

      txb.addOutput(contract, 0);

      if (totalValue > fee)
        txb.addOutput(address, totalValue - fee);

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, keyPair: keyPair);
      }
      
      addressController.clear();
      valueController.clear();

      broadcastTx(context, txb.build().toHex());
    }
  }

  Future<List<TokenList.Token>> fillTokens() async {
    var res = await TokenList.fetchData(address);
    for(int i = 0; i < res.length; i++)
      dropdownItems[res[i].address] = res[i].symbol;
    return res;
  }

  void _scanQR(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRScannerPage()),
    );

    if (result != null && result != []) {
      setState(() {
        addressController = TextEditingController(text: result[0]);
        valueController = TextEditingController(text: result[1]);
      });
    }
  }
}