import 'dart:convert';
import 'dart:typed_data';
import 'package:base58check/base58.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:flutter/material.dart';
import 'send_transaction_page.dart';
import '/src/configuration_service.dart';
import '/src/constants.dart' as CONSTANTS;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart';
import 'package:keccak/keccak.dart';
import 'package:hex/hex.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bitcoin_flutter/src/utils/constants/op.dart';
import 'package:bitcoin_flutter/src/utils/script.dart';
import 'package:url_launcher/url_launcher.dart';

class SmartContractPage extends StatefulWidget {
  @override
  SmartContractPageState createState() => SmartContractPageState();
}

class SmartContractPageState extends State<SmartContractPage> {

  final addressController = TextEditingController();
  final valueController = TextEditingController();
  final abiController = TextEditingController();
  final FocusNode addressFocusNode = FocusNode();
  final FocusNode abiFocusNode = FocusNode();
  final FocusNode valueFocusNode = FocusNode();

  List<String> dropdownItems = List.empty(growable: true);
  String dropdownValue = '';
  List<ABIObject> abi = List.empty(growable: true);
  List<TextEditingController> inputControllers = List.empty(growable: true);
  List<FocusNode> inputFocusNodes = List.empty(growable: true);

  double _feeValue = 0.003;
  double _gasLimitValue = 200000;
  double _gasPriceValue = 20;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.callSmartContract),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  focusNode: addressFocusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: AppLocalizations.of(context)!.smartContractAddress,
                    labelStyle: addressFocusNode.hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey),
                    hoverColor: Color.fromRGBO(26, 159, 41, 1.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromRGBO(26, 159, 41, 1.0),
                      )
                    )
                  ),
                  minLines: 1,
                  maxLines: 1,
                  controller: addressController,
                  cursorColor: Color.fromRGBO(26, 159, 41, 1.0),
                  onTap: () => {
                    setState(() {
                      FocusScope.of(context).requestFocus(addressFocusNode);
                    })
                  },
                )
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  focusNode: abiFocusNode,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: AppLocalizations.of(context)!.pasteABI,
                    labelStyle: abiFocusNode.hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey),
                    hoverColor: Color.fromRGBO(26, 159, 41, 1.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromRGBO(26, 159, 41, 1.0),
                      )
                    )
                  ),
                  minLines: 5,
                  maxLines: 5,
                  controller: abiController,
                  cursorColor: Color.fromRGBO(26, 159, 41, 1.0),
                  onTap: () => {
                    setState(() {
                      FocusScope.of(context).requestFocus(abiFocusNode);
                    })
                  },
                  onChanged: (String value) => parseAbi(value),
                )
              ),
              DropdownButton<String>(
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
                items: dropdownItems.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              FutureBuilder<List<Object>?>(
                future: _getInputsOfSelectedDropdown(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    for (int i=0; i< snapshot.data!.length; i++) {
                      inputControllers.add(new TextEditingController());
                      inputFocusNodes.add(new FocusNode());
                    }
                  }
                  if (snapshot.hasData) 
                    return Column(
                      children: [
                        for(int i=0; i<snapshot.data!.length; i++)
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              controller: inputControllers[i],
                              focusNode: inputFocusNodes[i],
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: (snapshot.data![i] as Map)['name'] + ' (' + (snapshot.data![i] as Map)['type'] + ')',
                                labelStyle: inputFocusNodes[i].hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey),
                                hoverColor: Color.fromRGBO(26, 159, 41, 1.0),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(26, 159, 41, 1.0),
                                  )
                                )
                              ),
                              onTap: () => {
                                setState(() {
                                  FocusScope.of(context).requestFocus(inputFocusNodes[i]);
                                })
                              },
                            ),
                          ),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability == 'payable') ? Padding(
                            padding: EdgeInsets.all(10),
                            child: TextField(
                              controller: valueController,
                              focusNode: valueFocusNode,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: AppLocalizations.of(context)!.value_sber,
                                labelStyle: valueFocusNode.hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey),
                                hoverColor: Color.fromRGBO(26, 159, 41, 1.0),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Color.fromRGBO(26, 159, 41, 1.0),
                                  )
                                )
                              ),
                              onTap: () => {
                                setState(() {
                                  FocusScope.of(context).requestFocus(valueFocusNode);
                                })
                              },
                            )
                          ) : Text(''),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability != 'view') ? Text(AppLocalizations.of(context)!.fee_greph) : Text(''),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability != 'view') ? Slider(
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
                          ) : Text(''),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability != 'view') ? Text(AppLocalizations.of(context)!.gasLimit) : Text(''),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability != 'view') ? Slider(
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
                          ) : Text(''),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability != 'view') ? Text(AppLocalizations.of(context)!.gasPrice_greph_per_gas) : Text(''),
                          (abi[dropdownItems.indexOf(dropdownValue)].stateMutability != 'view') ? Slider(
                            value: _gasPriceValue,
                            min: 18,
                            max: 40,
                            divisions: 22,
                            label: _gasPriceValue.round().toString(),
                            activeColor: Color.fromRGBO(26, 159, 41, 1.0),
                            inactiveColor: Color.fromRGBO(26, 159, 41, 0.3),
                            onChanged: (double value) {
                              setState(() {
                                _gasPriceValue = value;
                              });
                            },
                          ) : Text(''),
                          ElevatedButton(
                            onPressed: () => sendTx(context, abi[dropdownItems.indexOf(dropdownValue)].stateMutability == 'view'), 
                            child: abi[dropdownItems.indexOf(dropdownValue)].stateMutability == 'view' ? Text('Call contract') : Text('Send to contract')
                          )
                      ],
                    ); 
                  else return Text('');
                }
              )
            ]
          )
        )
      )
    );
  }

  void parseAbi(String responseBody) {
    final abiObjsJson = jsonDecode(responseBody) as List;
    List<ABIObject> abiObjs = abiObjsJson.map((abiJson) => ABIObject.fromJson(abiJson)).toList();
    for (int i=0; i< abiObjs.length; i++) {
      if(abiObjs[i].type == 'function') {
        dropdownItems.add(abiObjs[i].name);
        abi.add(abiObjs[i]);
      }
    }
    setState(() {
      dropdownValue = dropdownItems[0];
    });
  }

  Future<List<Object>?> _getInputsOfSelectedDropdown() async {
    var selectedIndex = dropdownItems.indexOf(dropdownValue);
    return abi[selectedIndex].inputs;
  }

  void sendTx(BuildContext context, bool isView) async {
    if (isView)
      callViewFunction();
    else
      sendToContract();
  }

  callViewFunction() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    Wallet wallet =  Wallet.fromWIF(configurationService.getWIF(), CONSTANTS.sbercoinNetwork);
    String sender = HEX.encode(Base58Decoder('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz').convert(wallet.address)).substring(2,42);
    var client = new Client();

    var selectedIndex = dropdownItems.indexOf(dropdownValue);
    String data = encodeData();

    try {
      var uriResponse = await client.get(Uri.parse('https://explorer.sbercoin.com/api/contract/${addressController.text}/call?data=$data&sender=$sender'));
      var res = json.decode(uriResponse.body);
      Map? response = {};
      if (res['executionResult']['output'] != '') {
        for (int i = 0; i < abi[selectedIndex].outputs!.length; i++) {
          var key = (abi[selectedIndex].outputs![i] as Map)['name'] != '' ? (abi[selectedIndex].outputs![i] as Map)['name'] : 'value';
          if ((abi[selectedIndex].outputs![i] as Map)['type'] == 'address')
            response[key] = res['executionResult']['output'].substring(64*i, 64*(i+1));
          else if ((abi[selectedIndex].outputs![i] as Map)['type'] == 'bool')
            response[key] = res['executionResult']['output'].substring(64*(i+1)-1, 64*(i+1)) == '1' ? true : false;
          else if ((abi[selectedIndex].outputs![i] as Map)['type'].startsWith('int') || (abi[selectedIndex].outputs![i] as Map)['type'].startsWith('uint'))
            response[key] = BigInt.parse(res['executionResult']['output'].substring(64*i, 64*(i+1)), radix: 16);
          else {
            if ((abi[selectedIndex].outputs![i] as Map)['type'] == 'string') {
              var offset = int.parse(res['executionResult']['output'].substring(64*i, 64*(i+1)), radix: 16) * 2;
              var length = int.parse(res['executionResult']['output'].substring(64*i + offset, 64*(i+1) + offset), radix: 16) * 2;
              String hexString = res['executionResult']['output'].substring(64*(i+1) + offset, 64*(i+1) + offset + length);
              List<String> splitted = [];
              for (int k = 0; k < hexString.length; k = k + 2) {
                splitted.add(hexString.substring(k, k + 2));
              }
              String ascii = List.generate(splitted.length,
                  (k) => String.fromCharCode(int.parse(splitted[k], radix: 16))).join();
              response[key] = ascii;
            }
            else {
              var offset = int.parse(res['executionResult']['output'].substring(64*i, 64*(i+1)), radix: 16) * 2;
              var length = int.parse(res['executionResult']['output'].substring(64*i + offset, 64*(i+1) + offset), radix: 16) * 2;
              String hexString = res['executionResult']['output'].substring(64*(i+1) + offset, 64*(i+1) + offset + length);
              response[key] = hexString;
            }
          }
        }
      }
      else {
        response['result'] = 'error';
      }
      
      if (uriResponse.statusCode == 200) {
        showDialog<String>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title:Text(AppLocalizations.of(context)!.txSent),
            content: InkWell(
              child: Text(
                response.toString(),
                style: TextStyle(decoration: TextDecoration.underline),
              ),
          ),
        ));
      }
    } finally {
      client.close();
    }
  }

  sendToContract() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    final keyPair = ECPair.fromWIF(configurationService.getWIF(), network: CONSTANTS.sbercoinNetwork);
    final address = Wallet.fromWIF(configurationService.getWIF(), CONSTANTS.sbercoinNetwork).address;
    var fee = (_feeValue * CONSTANTS.SBER_DECIMALS).toInt();
    var totalValue = 0;
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

      var chunks = List<dynamic>.generate(6, (_) => null);
      chunks[0] = OPS['OP_4'];
      chunks[1] = number2Buffer(_gasLimitValue.toInt());
      chunks[2] = number2Buffer(_gasPriceValue.toInt());
      chunks[3] = Uint8List.fromList(HEX.decode(encodeData()));
      chunks[4] = Uint8List.fromList(HEX.decode(addressController.text));
      chunks[5] = 0xc2; //OP_CALL

      var contract =  compile(chunks);
      txb.addOutput(contract, (double.parse(valueController.text) * CONSTANTS.SBER_DECIMALS).toInt());

      if (totalValue > fee + _gasLimitValue.toInt()*_gasPriceValue.toInt())
        txb.addOutput(address, totalValue - fee - _gasLimitValue.toInt()*_gasPriceValue.toInt());

      for (var i = 0; i < inputs.length; i++) {
        txb.sign(vin: i, keyPair: keyPair);
      }

      _broadcastTx(txb.build().toHex());
    }

  }

  void _broadcastTx(String datahex) async {
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
              onTap:res.getStatus() == 0 ? () async {
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

  String encodeData() {
    String data = getMethodId();
    var selectedIndex = dropdownItems.indexOf(dropdownValue);
    var typeList = [];
    var dynamicTypeList = [];
    int dynamicParamsCounter = 0;
    int deletedItemsCounter = 0;
    for (int i = 0; i < abi[selectedIndex].inputs!.length; i++) {
      typeList.add((abi[selectedIndex].inputs![i] as Map)['type']);
    }
    while (typeList.isNotEmpty) {
      for (int i = 0; i < typeList.length; i++) {
        if (typeList[i].startsWith('uint') || typeList[i].startsWith('int')) {
          data += int.parse(inputControllers[i + deletedItemsCounter].text).toRadixString(16).padLeft(64, '0');
          typeList.removeAt(i);
          deletedItemsCounter++;
        }
        else if (typeList[i] == 'address') {
          var address;
          if (inputControllers[i + deletedItemsCounter].text.startsWith('S') && inputControllers[i + deletedItemsCounter].text.length == 34)
            address = HEX.encode(Base58Decoder('123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz').convert(inputControllers[i].text)).substring(2,42);
          else
            address = inputControllers[i + deletedItemsCounter].text;
          data += address.padLeft(64, '0');
          typeList.removeAt(i);
          deletedItemsCounter++;
        }
        else if (typeList[i] == 'bool') {
          inputControllers[i + deletedItemsCounter].text == 'true' ? data += '1'.padLeft(64, '0') : data += '0'.padLeft(64, '0');
          typeList.removeAt(i);
          deletedItemsCounter++;
        }
        else {
          var offset = HEX.encode([abi[selectedIndex].inputs!.length + dynamicParamsCounter]).padLeft(64, '0');
          dynamicParamsCounter++;
          data += offset;
          dynamicTypeList.add([i, typeList[i]]);
          typeList.removeAt(i);
          deletedItemsCounter++;
        }
      }
      while (dynamicTypeList.isNotEmpty) {
        for (int i = 0; i < dynamicTypeList.length; i++) {
          data += HEX.encode([inputControllers[dynamicTypeList[i][0]].text.length]).padLeft(64, '0');
          if (dynamicTypeList[i][1] == 'string') {
            var encodedString = Utf8Encoder().convert(inputControllers[dynamicTypeList[i][0]].text);
            data += HEX.encode(encodedString).padRight((encodedString.length/64).ceil()*64, '0');
          }
          else 
            data += inputControllers[dynamicTypeList[i][0]].text;
          dynamicTypeList.removeAt(i);
        }
      }
    }
    return data;
  }

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

  

  String getMethodId() {
    var selectedIndex = dropdownItems.indexOf(dropdownValue);
    var typeList = [];
    String sign;
    for (int i = 0; i < abi[selectedIndex].inputs!.length; i++) {
      typeList.add((abi[selectedIndex].inputs![i] as Map)['type']);
    }
    sign = abi[selectedIndex].name + '(' + typeList.join(',') + ')';
    return HEX.encode(keccak(Uint8List.fromList(sign.codeUnits))).substring(0,8);
  }
}

class ABIObject {
  final String name;
  final List<Object>? inputs;
  final List<Object>? outputs;
  final String? stateMutability;
  final String? type;

  ABIObject({
    required this.name, 
    this.inputs, 
    this.outputs, 
    this.stateMutability, 
    this.type, 
  });

  factory ABIObject.fromJson(dynamic json) {
    return ABIObject(
      name: json['name'] as String, 
      inputs: json['inputs'] as List<Object>,
      outputs: json['outputs'] as List<Object>,
      stateMutability: json['stateMutability'] as String,
      type: json['type'] as String,
      );
  }
}
