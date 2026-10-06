import 'package:flutter/material.dart';
import 'package:sapiku/plugins/management/utils/qr.dart';

class TextFormFieldExample extends StatefulWidget {
  const TextFormFieldExample({super.key});

  @override
  State<TextFormFieldExample> createState() => _TextFormFieldExampleState();
}

class _TextFormFieldExampleState extends State<TextFormFieldExample> {
  final myController = TextEditingController();
  Widget? qrCode;
  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Retrieve Text Input')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: myController),
            if (qrCode != null) qrCode!,
            ElevatedButton(
              onPressed: () async {
                await saveQrToGallery();

                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('QR berhasil disimpan ke Gallery'),
                  ),
                );
              },
              child: const Text('Simpan QR'),
            ),
            FloatingActionButton(
              onPressed: () async {
                final int? id = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(builder: (_) => const QRScannerPage()),
                );
                if (id != null) {
                  print('Scanned ID: $id');
                  myController.text = id.toString();
                }
              },
              child: const Text("Scan QR"),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        // When the user presses the button, show an alert dialog containing
        // the text that the user has entered into the text field.
        onPressed: () {
          print("Creating data: ${myController.text}");
          setState(() {
            qrCode = buildQRImage(myController.text);
          });
        },
        tooltip: 'Show me the value!',
        child: const Text("Buat QR"),
      ),
    );
  }
}
