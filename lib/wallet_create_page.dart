import 'dart:math';
import 'package:bitcoin_flutter/bitcoin_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:shared_preferences/shared_preferences.dart';
import './src/configuration_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'src/components/pin.dart' as Test;
import 'src/constants.dart' as CONSTANTS;

class CreateSeed extends StatelessWidget {

  late final mnemonicCode;

  @override
  Widget build(BuildContext context) {

    var mnemonic = bip39.generateMnemonic();
    this.mnemonicCode = mnemonic;
    print(mnemonic);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.saveSeedPhrase),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: EdgeInsets.all(10),
              child: Text('$mnemonic',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(new ClipboardData(text: '$mnemonic'));
                    final snackBar = SnackBar(
                      content: Text(AppLocalizations.of(context)!.seedPhraseCopied),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undo,
                        textColor: Color.fromRGBO(26, 159, 41, 1.0),
                        onPressed: () {
                          // Some code to undo the change.
                        },
                      ),
                    );
                    // Find the ScaffoldMessenger in the widget tree
                    // and use it to show a SnackBar.
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  },
                  child: Text(AppLocalizations.of(context)!.copy),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
                  ),
                ),
                ElevatedButton(
                  child: Text(AppLocalizations.of(context)!.next),
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmSeed(mnemonic: mnemonicCode),
                      ));
                  },
                )
              ],
            ) 
          ],
        )
      ),
    );
  }
}

class ConfirmSeed extends StatefulWidget {
  ConfirmSeed({Key? key, required this.mnemonic}) : super(key: key);

  final String mnemonic;

  @override
  _ConfirmSeedState createState() => _ConfirmSeedState();
}

class _ConfirmSeedState extends State<ConfirmSeed> {

  late String mnemonic;
  bool mnemonicFilled = false;

  List<String> reportList = List.empty(growable: true);

  List<String> selectedReportList = List.empty(growable: true);

  fillMnemonic() {
    mnemonic = widget.mnemonic;
    var wordList = this.mnemonic
              .split(' ')                       // split the text into an array
              .map((String text) => text) // put the text inside a widget
              .toList();
    reportList = transformWordList(wordList);
    mnemonicFilled = true;
  }

  transformWordList(wordList) {
    List<String> res = List.empty(growable: true);
    var random = new Random();
    while (wordList.length != 0) {
      var index = random.nextInt(wordList.length);
      res.add(wordList[index].toString());
      wordList.remove(wordList[index]);
    }
    return res;
  }

  checkMnemonic(selectedList) {
    return selectedList == this.mnemonic;
  }

  @override
  Widget build(BuildContext context) {
    if (!mnemonicFilled)
      fillMnemonic();
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.confirmSeedPhrase),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            MultiSelectChip(
              reportList,
              onSelectionChanged: (selectedList) {
                setState(() {
                  selectedReportList = selectedList;
                });
              },
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(selectedReportList.join(" "),
                style: TextStyle(fontSize: 20),
              ),
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.confirm),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                  (Set<MaterialState> states) {
                    if (!states.contains(MaterialState.disabled))
                      return Color.fromRGBO(26, 159, 41, 1.0);
                    return Colors.grey; // Use the component's default.
                  },
                ),
              ),
              onPressed: checkMnemonic(selectedReportList.join(" ")) ? () async {
                SharedPreferences _prefs = await SharedPreferences.getInstance();
                var configurationService = ConfigurationService(_prefs);
                configurationService.setupDone(true);
                configurationService.setMnemonic(mnemonic);
                var seed = bip39.mnemonicToSeed(mnemonic);
                  var hdWallet = new HDWallet.fromSeed(seed, network: CONSTANTS.sbercoinNetwork);
                configurationService.setWIF(hdWallet.wif);
                Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (BuildContext ctx) => Test.MyHomePage())
                );
              } : null,
            )
          ],
        ),
      ),
    );
  }
}

class MultiSelectChip extends StatefulWidget {
  final List<String> reportList;
  final Function(List<String>) onSelectionChanged;

  MultiSelectChip(this.reportList, {required this.onSelectionChanged});

  @override
  _MultiSelectChipState createState() => _MultiSelectChipState();
}

class _MultiSelectChipState extends State<MultiSelectChip> {
  // String selectedChoice = "";
  List<String> selectedChoices = List.empty(growable: true);

  _buildChoiceList() {
    List<Widget> choices = List.empty(growable: true);

    widget.reportList.forEach((item) {
      choices.add(Container(
        padding: const EdgeInsets.all(2.0),
        child: ChoiceChip(
          label: Text(item),
          selected: selectedChoices.contains(item),
          onSelected: (selected) {
            setState(() {
              selectedChoices.contains(item)
                  ? selectedChoices.remove(item)
                  : selectedChoices.add(item);
              widget.onSelectionChanged(selectedChoices);
            });
          },
        ),
      ));
    });

    return choices;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: _buildChoiceList(),
    );
  }
}