import 'dart:math';
import 'package:coinslib/coinslib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:shared_preferences/shared_preferences.dart';
import '/src/configuration_service.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screen_lock_page.dart';
import '/src/constants.dart' as CONSTANTS;

class CreateSeed extends StatelessWidget {

  late final mnemonicCode;

  @override
  Widget build(BuildContext context) {

    this.mnemonicCode = bip39.generateMnemonic();

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
              child: Text('${this.mnemonicCode}',
                style: TextStyle(fontSize: 20),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Clipboard.setData(new ClipboardData(text: '${this.mnemonicCode}'));
                    final snackBar = SnackBar(
                      content: Text(AppLocalizations.of(context)!.seedPhraseCopied),
                      action: SnackBarAction(
                        label: AppLocalizations.of(context)!.undo,
                        textColor: Color.fromRGBO(26, 159, 41, 1.0),
                        onPressed: () {
                        },
                      ),
                    );
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
                      )
                    );
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
                    return Colors.grey;
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
                  MaterialPageRoute(builder: (BuildContext ctx) => ScreenLockPage())
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