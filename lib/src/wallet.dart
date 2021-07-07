import 'dart:core';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:bitcoin_flutter/bitcoin_flutter.dart' as BitcoinLibrary;
import 'package:shared_preferences/shared_preferences.dart';
import 'configuration_service.dart';
import './components/balance.dart';
import './components/send_transaction.dart';
import './components/settings_page.dart';
import 'components/tx_details.dart' as Test;
import 'token_list.dart';
import 'constants.dart' as CONSTANTS;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Wallet extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => WalletState();
}

class WalletState extends State<Wallet> {

  late BitcoinLibrary.Wallet wallet;

  Future<BitcoinLibrary.Wallet> _loadWallet() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    Future.delayed(const Duration(milliseconds: 100));
    var configurationService = ConfigurationService(_prefs);
    return BitcoinLibrary.Wallet.fromWIF(configurationService.getWIF(), CONSTANTS.sbercoinNetwork);
  }

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BitcoinLibrary.Wallet>(
      future: _loadWallet(),
      builder: (context, snapshot) {
        wallet = snapshot.data!;
        return Container(
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(icon: Icon(Icons.account_balance)),
                Tab(icon: Icon(Icons.monetization_on)),
                Tab(icon: Icon(Icons.payments)),
                Tab(icon: Icon(Icons.settings)),
              ],
            ),
            title: Text(AppLocalizations.of(context)!.sbercoinComWallet),
          ),
          body: TabBarView(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Expanded(
                  flex: 3,
                child: WalletInfo(walletAddress: wallet.address),
              ),
              Divider(
            height: 10,
            thickness: 3,
            indent: 10,
            endIndent: 10,
          ),
                  Container(
                    padding: EdgeInsets.only(left: 15),
                    child: 
                    Text(AppLocalizations.of(context)!.txList,
                    style: TextStyle(fontSize: 20, letterSpacing: 1.0),textAlign: TextAlign.left,),
                    height: 30.0, 
                    
                  ),
                  //Divider(),
              Expanded(
                flex: 6,
                child:
                  Container(
                    child: 
                    Test.MyApp(wallet.address),
                  ),
              ),

              ],),
              TokenList(wallet.address),
              //Icon(Icons.directions_transit),
              SendTransaction(wallet.address),
              Settings(),

          ],),
        ),
      ),
    );
      }
    );
  }
}