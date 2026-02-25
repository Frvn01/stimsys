import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Subject QR")),
      body: MobileScanner(
        onDetect: (BarcodeCapture barcodeCapture) {
          if (_isScanned) return; // prevent duplicates

          final List<Barcode> barcodes = barcodeCapture.barcodes;
          
          for (final barcode in barcodes) {
            final String? code = barcode.rawValue;
            if (code != null && code.isNotEmpty) {
              _isScanned = true;

              // Return scanned data to previous screen
              Navigator.pop(context, code);
              return;
            }
          }
        },
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:mobile_scanner/mobile_scanner.dart';

// class QRScannerScreen extends StatefulWidget {
//   const QRScannerScreen({super.key});

//   @override
//   State<QRScannerScreen> createState() => _QRScannerScreenState();
// }

// class _QRScannerScreenState extends State<QRScannerScreen> {
//   bool _isScanned = false;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Scan Subject QR")),
//       body: MobileScanner(
//         // FIXED: Updated callback signature
//         onDetect: (BarcodeCapture capture) {
//           if (_isScanned) return; 

//           // Access the list of barcodes from the capture object
//           final List<Barcode> barcodes = capture.barcodes;

//           if (barcodes.isNotEmpty) {
//             final Barcode barcode = barcodes.first;
//             final String? code = barcode.rawValue;

//             if (code != null && code.isNotEmpty) {
//               setState(() {
//                 _isScanned = true;
//               });
              
//               // Return scanned data to previous screen
//               Navigator.pop(context, code);
//             }
//           }
//         },
//       ),
//     );
//   }
// }