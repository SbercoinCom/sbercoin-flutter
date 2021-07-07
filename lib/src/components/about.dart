import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


class AboutPage extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.about),
      ),
      body: Center(
        child: Column(
          children: [
            Image(image: AssetImage('lib/src/images/bitcoin.png')),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(AppLocalizations.of(context)!.aboutProject,
                textAlign: TextAlign.center,
              ),
            )
          ]
        )
      ),
    );
  }
}
