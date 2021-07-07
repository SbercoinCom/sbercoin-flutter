import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../configuration_service.dart';
import '../wallet.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EnableBiometryPage extends StatelessWidget{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.doYouWantToEnableFingerprint,
              style: TextStyle(fontSize: 22),
            ),
            Padding(
              padding: EdgeInsets.all(26.0),
              child: Icon(Icons.fingerprint,
                size: 70
              ),
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.enableFingerprint),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
              ),
              onPressed: () {
                _saveFingerPrintOption(true);
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext ctx) => Wallet()),
                  (Route<dynamic> route) => false
                );
              },
            ),
            OutlinedButton(
              child: Text(AppLocalizations.of(context)!.skip, style: TextStyle(color: Color.fromRGBO(26, 159, 41, 1.0))),
              onPressed: () {
                _saveFingerPrintOption(false);
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (BuildContext ctx) => Wallet()),
                  (Route<dynamic> route) => false
                );
              },
            ),
          ],
        )
      )
    );
  }

  void _saveFingerPrintOption(bool option) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    configurationService.setFingerprint(option);
  }
  
}
