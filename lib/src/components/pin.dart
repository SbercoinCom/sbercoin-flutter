import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screen_lock/heading_title.dart';
import 'package:flutter_screen_lock/input_controller.dart';
import 'package:flutter_screen_lock/screen_lock.dart';
import 'package:local_auth/auth_strings.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../configuration_service.dart';
import '../wallet.dart';
import 'enableBiometry.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

enum _SupportState {
  unknown,
  supported,
  unsupported,
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  final auth = LocalAuthentication();
  final inputController = InputController();
  late bool _isFingerprintEnabled;
  _SupportState _supportState = _SupportState.unknown;

  Future<void> localAuth(BuildContext context) async {
    final didAuthenticate = await auth.authenticate(
      localizedReason: AppLocalizations.of(context)!.pleaseAuth,
      biometricOnly: true,
      androidAuthStrings: AndroidAuthMessages(
        signInTitle: AppLocalizations.of(context)!.authRequired,
        cancelButton: AppLocalizations.of(context)!.cancel,
        biometricHint: ''
      ),
      iOSAuthStrings: IOSAuthMessages(
        cancelButton: AppLocalizations.of(context)!.cancel,
        lockOut: AppLocalizations.of(context)!.authRequired
      )
    );
    if (didAuthenticate) {
      if (Navigator.canPop(context))
        Navigator.of(context).pop(true);
      else
        Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => Wallet())
        );
    }
  }

  @override
  void initState() {
    super.initState();
    _getFingerprint();
    auth.isDeviceSupported().then(
          (isSupported) => setState(() => _supportState = isSupported
              ? _SupportState.supported
              : _SupportState.unsupported),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<String>(
        future: _getPin(),
        builder: (context, snapshot)  {
          if (snapshot.hasData) {
            if (snapshot.data.toString() == '')
              return ScreenLock(
                correctString: '',
                confirmation: true,
                digits: 6,
                inputController: inputController,
                canCancel: false,
                title: HeadingTitle(text: AppLocalizations.of(context)!.createPasscode),
                confirmTitle: HeadingTitle(text: AppLocalizations.of(context)!.confirmPasscode),
                didConfirmed: (matchedText) {
                  _setPin(matchedText);
                  (_supportState == _SupportState.supported) ?
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => EnableBiometryPage())
                    ) 
                    : 
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Wallet())
                    );
                },
              );
            else 
              if (_supportState == _SupportState.supported && _isFingerprintEnabled)
                return ScreenLock(
                  correctString: snapshot.data.toString(),
                  confirmation: false,
                  digits: 6,
                  title: HeadingTitle(text: AppLocalizations.of(context)!.enterPasscode),
                  inputController: inputController,
                  didUnlocked: () {
                    if (Navigator.canPop(context))
                      Navigator.of(context).pop(true);
                    else
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Wallet())
                    );
                  },
                  customizedButtonChild: const Icon(
                    Icons.fingerprint,
                  ),
                  custmizedButtonTap: () async {
                    await localAuth(context);
                  },
                  cancelButton: FittedBox(
                    child: InkWell(
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        softWrap: false,
                      ),
                      onTap: () {
                        if (Navigator.canPop(context))
                          Navigator.of(context).pop(false);
                        else exit(0);  
                      },
                    )
                  )
                );
              else
                return ScreenLock(
                  correctString: snapshot.data.toString(),
                  confirmation: false,
                  digits: 6,
                  inputController: inputController,
                  didUnlocked: () {
                    if (Navigator.canPop(context))
                      Navigator.of(context).pop(true);
                    else
                    Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) => Wallet())
                    );
                  },
                  cancelButton: FittedBox(
                    child: InkWell(
                      child: Text(
                        AppLocalizations.of(context)!.cancel,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                        softWrap: false,
                      ),
                      onTap: () {
                        if (Navigator.canPop(context))
                          Navigator.of(context).pop(false);
                        else exit(0);      
                      },
                    )
                  )
                );
          } 
          return Center(
            child: CircularProgressIndicator(color:Color.fromRGBO(26, 159, 41, 1.0),)
          );
        }     
      )
    );
  }

  Future<String> _getPin() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    var pin = configurationService.getPIN();
    if (pin != null) 
      return pin;
    else return '';
  }

  void _setPin(String pin) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    configurationService.setPIN(pin);
  }

  void _getFingerprint() async{ // change return type to bool
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    var configurationService = ConfigurationService(_prefs);
    _isFingerprintEnabled = configurationService.getFingerprint();
  }

}