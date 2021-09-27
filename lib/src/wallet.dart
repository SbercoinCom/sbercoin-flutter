import 'package:flutter/material.dart';
import 'package:coinslib/coinslib.dart' as BitcoinLibrary;
import 'package:shared_preferences/shared_preferences.dart';
import 'configuration_service.dart';
import 'components/address_info.dart';
import 'pages/delegation_page.dart';
import 'pages/send_transaction_page.dart';
import 'pages/settings_page.dart';
import 'components/address_transaction_list.dart';
import 'pages/token_list_page.dart';
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
    wallet = BitcoinLibrary.Wallet.fromWIF(configurationService.getWIF()!, CONSTANTS.sbercoinNetwork);
    return wallet;
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
        if (snapshot.hasData)
          return Container(
            child: DefaultTabController(
              length: 5,
              child: Scaffold(
                appBar: AppBar(
                  bottom: TabBar(
                    tabs: [
                      Tab(icon: Icon(Icons.account_balance)),
                      Tab(icon: Icon(Icons.monetization_on)),
                      Tab(icon: Icon(Icons.payments)),
                      Tab(icon: Icon(Icons.savings)),
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
                        WalletInfo(walletAddress: wallet.address),
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
                            style: TextStyle(fontSize: 20, letterSpacing: 1.0),textAlign: TextAlign.left
                          ),
                          height: 30.0, 
                        ),
                        Expanded(
                          child: Container(
                            child: TxsListPage(wallet.address!),
                          ),
                        ),
                      ],
                    ),
                    TokenList(wallet.address!),
                    SendTransaction(wallet.address!),
                    Delegation(wallet.address!),
                    Settings(),
                  ]
                )
              )
            )
          );
        return Center(child: CircularProgressIndicator(color: Color.fromRGBO(26, 159, 41, 1.0)));
      }
    );
  }
}