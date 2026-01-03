import 'package:flutter/material.dart';
import 'package:lpe_with_source/lpe_with_source.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _amountCtrl = TextEditingController(text: '10.00');
  final _pkCtrl = TextEditingController(text: '');

  @override
  void dispose() {
    _amountCtrl.dispose();
    _pkCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Keep Source.present.defaultapiKey in sync with the text field.
    Source.present.defaultapiKey = _pkCtrl.text;
    _pkCtrl.addListener(() {
      Source.present.defaultapiKey = _pkCtrl.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LPE Paysheet Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Amount (e.g. 10.00)',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pkCtrl,
              decoration: const InputDecoration(
                labelText: 'Publishable Key (optional)',
              ),
            ),
            const SizedBox(height: 16),
            SourcePayButton(
              style: Source.present.defaultStyle,
              amount: _amountCtrl.text,
              merchantArgs: {
                'merchantName': 'Demo Store',
                'merchantInfo': 'Order #42',
                'summaryItems': [
                  {'label': 'T-shirt', 'amountCents': 1999},
                  {'label': 'Shipping', 'amountCents': 500},
                  {'label': 'Tax', 'amountCents': 250},
                ],
              },
              onResult: (result) {
                final messenger = ScaffoldMessenger.of(context);
                if (result == null) {
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Paysheet dismissed')),
                  );
                  return;
                }

                messenger.showSnackBar(
                  SnackBar(content: Text('Payment result: $result')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
