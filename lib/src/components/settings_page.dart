import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';
import '../configuration_service.dart';
import 'about.dart';
import 'pin.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'smartContractsPage.dart';

enum Type { changePin, backup, touchId, smartContracts, about, logout }

class Settings extends StatefulWidget {
  @override
  SettingsState createState() => SettingsState();
}


class SettingsState extends State<Settings> {

  bool _isFingerprintEnabled = false;
  late bool _isLocalAuthAvailable;

  _getAuthStatus() async {
    _isLocalAuthAvailable = await LocalAuthentication().isDeviceSupported();
  }

  @override
  void initState() {
    super.initState();
    _getAuthStatus();
    _getFingerprint().whenComplete((){
          setState(() {});
       });
  }

  Widget build(BuildContext context) {
    return new Center(child: new Column(
        children: [
          _tile(context, AppLocalizations.of(context)!.changePIN, Icons.password, Type.changePin),
          //Divider(),
          //_tile(context, AppLocalizations.of(context)!.backup, Icons.file_download, Type.backup),
          if (_isLocalAuthAvailable) Divider(),
          if (_isLocalAuthAvailable) Row(
            children:  <Widget>[
              Expanded(
                child: _tile(context, AppLocalizations.of(context)!.touchID, Icons.fingerprint, Type.touchId),
              ),
              Switch(
                value: _isFingerprintEnabled,
                activeColor: Color.fromRGBO(26, 159, 41, 1.0),
                onChanged: (value) {
                  _setFingerprint(value);
                  setState(() {
                    _isFingerprintEnabled = value;
                    print(value);
                  });
                }
              ),
            ],
          ),
          Divider(),
          _tile(context, AppLocalizations.of(context)!.smartContracts, Icons.assignment, Type.smartContracts),
          Divider(),
          _tile(context, AppLocalizations.of(context)!.about, Icons.info, Type.about),
          Divider(),
          _tile(context, AppLocalizations.of(context)!.logout, Icons.logout, Type.logout),
          Divider(),
        ]
    ));

  }

  _getFingerprint() async{ // change return type to bool
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    _isFingerprintEnabled = configurationService.getFingerprint();
    Future.delayed(const Duration(milliseconds: 100));
  }

  void _setFingerprint(bool value) async{ // change return type to bool
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    configurationService.setFingerprint(value);
  }

}

ListTile _tile(BuildContext context, String title, IconData icon, Type type) => ListTile(
  title: Text(title,
    style: TextStyle(
      fontWeight: FontWeight.w500,
      fontSize: 15,
    )
  ),
  //subtitle: Text(subtitle),
  leading: Icon(
    icon,
    color: Color.fromRGBO(26, 159, 41, 1.0),
  ),
  onTap: () {
    switch(type) {
      case Type.logout: return logout(context);
      case Type.changePin: return changePin(context);
      case Type.backup:
        // TODO: Handle this case.
        break;
      case Type.touchId:
        // TODO: Handle this case.
        break;
      case Type.smartContracts: return smartContacts(context);
      case Type.about: return about(context);
    }
  }
  
);

logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var configurationService = ConfigurationService(prefs);
  configurationService.setPIN(null);
  configurationService.setWIF(null);
  configurationService.setMnemonic(null);
  configurationService.setupDone(false);
  Navigator.pushReplacement(context,
    MaterialPageRoute(builder: (BuildContext ctx) => Login())
  );
}

changePin(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var configurationService = ConfigurationService(prefs);
  configurationService.setPIN(null);
  Navigator.pushReplacement(context,
    MaterialPageRoute(builder: (BuildContext ctx) => MyHomePage())
  );
}

smartContacts(BuildContext context) async {
  Navigator.push(context,
    MaterialPageRoute(builder: (BuildContext ctx) => SmartContractPage())
  );
}

about(BuildContext context) async {
  Navigator.push(context,
    MaterialPageRoute(builder: (BuildContext ctx) => AboutPage())
  );
}