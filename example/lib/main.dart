import 'package:flutter/material.dart';
import 'package:lpe_with_source/lpe_with_source.dart';

void main() {
  LpeWithSourceConfig.init(
    appleMerchantId: 'merchant.com.example',
    googleGatewayMerchantId: 'exampleGatewayId',
  );
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('lpe_with_source example')),
        body: const Center(child: ExampleBody()),
      ),
    );
  }
}

class ExampleBody extends StatelessWidget {
  const ExampleBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LearmondPayButtons(
          amount: '9.99',
          onResult: (r) {
            // Handle result in your app.
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Payment result: $r')));
          },
        ),
      ],
    );
  }
}
