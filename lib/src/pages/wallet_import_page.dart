import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/src/configuration_service.dart';
import 'screen_lock_page.dart';
import 'package:coinslib/coinslib.dart';
import 'package:bip39/bip39.dart' as bip39;
import '../constants.dart' as CONSTANTS;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ImportWallet extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.importWallet),
      ),
      body: Center(
        child: Column(
          children: [
            MyStatefulWidget() 
          ]
        )
      )
    );
  }
}

enum ImportType { wif, seed }

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key? key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => _MyStatefulWidgetState();
}

class _MyStatefulWidgetState extends State<MyStatefulWidget> {
  final textController = TextEditingController();
  FocusNode myFocusNode = FocusNode();
  ImportType? _type = ImportType.seed;

  @override
  void initState() {
    super.initState();
  }

  void _requestFocus(){
    setState(() {
      FocusScope.of(context).requestFocus(myFocusNode);
    });
  }

  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(AppLocalizations.of(context)!.seedPhrase),
          leading: Radio<ImportType>(
            value: ImportType.seed,
            activeColor: Color.fromRGBO(26, 159, 41, 1.0),
            groupValue: _type,
            onChanged: (ImportType? value) {
              setState(() {
                _type = value;
              });
            },
          ),
        ),
        ListTile(
          title: Text(AppLocalizations.of(context)!.wif),
          leading: Radio<ImportType>(
            value: ImportType.wif,
            activeColor: Color.fromRGBO(26, 159, 41, 1.0),
            groupValue: _type,
            onChanged: (ImportType? value) {
              setState(() {
                _type = value;
              });
            },
          ),
        ),
        Padding(
          padding: EdgeInsets.all(10),
          child: TextFormField(
            focusNode: myFocusNode,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: AppLocalizations.of(context)!.pasteHere,
              labelStyle: myFocusNode.hasFocus ? TextStyle(color:Color.fromRGBO(26, 159, 41, 1.0)) : TextStyle(color:Colors.grey),
              hoverColor: Color.fromRGBO(26, 159, 41, 1.0),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: Color.fromRGBO(26, 159, 41, 1.0),
                )
              )
            ),
            minLines: 2,
            maxLines: 2,
            controller: textController,
            cursorColor: Color.fromRGBO(26, 159, 41, 1.0),
            onTap: _requestFocus,
          )
        ),
        ElevatedButton(
          child: Text(AppLocalizations.of(context)!.confirm),
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
          ),
          onPressed: () async {
            SharedPreferences _prefs = await SharedPreferences.getInstance();
            var configurationService = ConfigurationService(_prefs);
            if (_type == ImportType.seed) {
              if (bip39.validateMnemonic(textController.text)) {
                await configurationService.setMnemonic(textController.text);
                var seed = bip39.mnemonicToSeed(textController.text);
                var hdWallet = new HDWallet.fromSeed(seed, network: CONSTANTS.sbercoinNetwork);
                await configurationService.setWIF(hdWallet.wif);
              }
              else {
                return showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title:Text(AppLocalizations.of(context)!.warning),
                      content: Text(AppLocalizations.of(context)!.doesNotApplyToBIP39),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, 'OK');
                          },  
                          child: const Text('OK', style: TextStyle(color: Color.fromRGBO(26, 159, 41, 1.0))),
                        ),
                      ],
                    );
                  }
                );
              }
            }
            else
              await configurationService.setWIF(textController.text);

            configurationService.setupDone(true);
            Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (BuildContext ctx) => ScreenLockPage())
            );
          },
        )
      ],
    );
  }
}