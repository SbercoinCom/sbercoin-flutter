import 'package:coinslib/coinslib.dart';

final sbercoinNetwork = new NetworkType(
  messagePrefix: '\x15SBER Signed Message:\n',
  bech32: 'sber',
  bip32: new Bip32Type(public: 0x0488b21e, private: 0x0488ade4),
  pubKeyHash: 0x3f,
  scriptHash: 0x1a,
  wif: 0x3c
);

const SBER_DECIMALS = 1e7;