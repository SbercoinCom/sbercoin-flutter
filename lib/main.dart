import 'package:flutter/material.dart';
import 'intro_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import './src/configuration_service.dart';
import 'src/components/pin.dart' as Test;

Future<void> main() async {
      WidgetsFlutterBinding.ensureInitialized();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var configurationService = ConfigurationService(prefs);
      bool? isWalletSetup = configurationService.didSetupWallet();
      runApp(
        MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            const Locale('en', ''),
            const Locale('ru', ''), 
          ],
          theme: ThemeData(
            primaryColor: Color.fromRGBO(26, 159, 41, 1.0),
            buttonColor: Color.fromRGBO(26, 159, 41, 1.0),
            indicatorColor: Color.fromRGBO(255, 255, 255, 1.0),
          ),
          home: (!isWalletSetup) ? Login() : Test.MyHomePage()
        )
      );
    }
    
 //Save the required user details after the successful login

class Login extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IntroPage();
  }
}