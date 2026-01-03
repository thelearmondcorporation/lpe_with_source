import 'package:flutter/material.dart';
import 'package:lpe_with_source/lpe_with_source.dart';

void main() {
  // Set example defaults for native pay merchant ids
  LpeWithSourceConfig.init(
    appleMerchantId: 'merchant.com.example',
    googleMerchantId: 'exampleMerchantId',
  );
  runApp(const LpeDemoApp());
}

class LpeDemoApp extends StatelessWidget {
  const LpeDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lpe_with_source Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const DemoHome(),
    );
  }
}

class DemoHome extends StatefulWidget {
  const DemoHome({super.key});

  @override
  State<DemoHome> createState() => _DemoHomeState();
}

class _DemoHomeState extends State<DemoHome> {
  final _log = <String>[];

  void _addLog(String s) => setState(() => _log.insert(0, s));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('lpe_with_source Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Demo Pay Buttons',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            LearmondPayButtons(
              amount: '9.99',
              onResult: (r) {
                _addLog('onResult: success=${r.success} error=${r.error}');
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                _addLog('Manual: opening paysheet (card)');
                final res = await Paysheet.instance.present(
                  context,
                  method: 'card',
                  amount: '9.99',
                );
                _addLog(
                    'paysheet result: success=${res?.success} error=${res?.error}');
              },
              child: const Text('Open Card Paysheet'),
            ),
            const SizedBox(height: 12),
            const Divider(),
            const Text('Log', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _log.map((s) => Text(s)).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
