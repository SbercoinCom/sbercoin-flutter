import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'wallet_import_page.dart';
import 'wallet_create_page.dart';

class IntroPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addWallet),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.createNewWallet),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Color.fromRGBO(26, 159, 41, 1.0)),
              ),
              onPressed: () {
                Navigator.push(context,
                  MaterialPageRoute(builder: (BuildContext ctx) => CreateSeed())
                );
              },
            ),
            Container(
              padding: const EdgeInsets.all(10),
              child: OutlinedButton(
                child: Text(AppLocalizations.of(context)!.importWallet, style: TextStyle(color: Color.fromRGBO(26, 159, 41, 1.0))),
                onPressed: () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (BuildContext ctx) => ImportWallet())
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
