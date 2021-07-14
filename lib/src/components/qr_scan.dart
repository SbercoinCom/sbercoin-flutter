import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class QRScannerPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScannerPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(child: _buildQrView(context)),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 500 ||
            MediaQuery.of(context).size.height < 500)
        ? 250.0
        : 500.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.red,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    bool scanned = false;
    var res = [];
    controller.scannedDataStream.listen((scanData) {
      if (!scanned) {
        scanned = true;
        if (scanData.code.startsWith('sbercoin:')) {
          //result code should be like `sbercoin:SSfbCTSoYnSAsVtXhLA7WyNuH22Cs8LTwp?amount=1.0&message=`
          res.add(scanData.code.substring(9, (9+34)));
          res.add(scanData.code.split('&')[0].substring(9+34+8));
        }
        Navigator.of(context).pop(res);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}