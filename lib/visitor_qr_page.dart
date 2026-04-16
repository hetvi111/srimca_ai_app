import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:srimca_ai/api_service.dart';

const Color navyBlue = Color(0xFF001F3F);
const Color accentBlue = Color(0xFF1E88E5);

class VisitorQRPage extends StatefulWidget {
  final String? token;
  final String? userId;

  const VisitorQRPage({super.key, this.token, this.userId});

  @override
  State<VisitorQRPage> createState() => _VisitorQRPageState();
}

class _VisitorQRPageState extends State<VisitorQRPage> {
  bool isScanning = false;
  bool isGenerating = false;
  String? qrData;
  MobileScannerController? scannerController;

  @override
  void initState() {
    super.initState();
    if (widget.token != null && widget.userId != null) {
      isGenerating = true;
      _generateQR();
    } else {
      isScanning = true;
    }
  }

  Future<void> _generateQR() async {
    try {
      final result = await ApiService.generateVisitorQR(widget.userId!);
      if (result != null && result['qr'] != null) {
        setState(() {
          qrData = result['qr'];
          isGenerating = false;
        });
      }
    } catch (e) {
      print(e);
      setState(() => isGenerating = false);
    }
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;
    if (code == null) return;

    scannerController?.stop();

    try {
      final result = await ApiService.checkInFromQR(code);
      if (!mounted) return;

      final success = result?['success'] == true;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(success ? 'Check-in Successful' : 'Check-in Failed'),
          content: Text(result?['message'] ?? 'Unknown error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (success) {
                  Navigator.pop(context);
                }
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    scannerController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isScanning ? 'Scan QR Pass' : 'Your QR Pass'),
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
      ),
      body: isGenerating
          ? Center(child: CircularProgressIndicator())
          : qrData != null
          ? _buildQRDisplay()
          : _buildScanner(),
    );
  }

  Widget _buildQRDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
            ),
            child: QrImageView(
              data: qrData!,
              version: QrVersions.auto,
              size: 250.0,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Show this QR at check-in',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back),
            label: Text('Back to Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildScanner() {
    scannerController ??= MobileScannerController();
    return Column(
      children: [
        Expanded(
          child: MobileScanner(
            controller: scannerController!,
            onDetect: _handleScan,
          ),
        ),
        Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Point camera at visitor QR pass',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
