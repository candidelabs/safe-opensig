import 'package:flutter/material.dart';

class SafeTxJsonGuideSheet extends StatelessWidget {
  const SafeTxJsonGuideSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'How to get transaction data ?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16,),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Follow these steps to get the transaction data from your Safe wallet:',
            style: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Image.network(
            'https://placehold.co/600x400/gif?text=Placeholder',
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '1. Open your Safe wallet app\n'
            '2. Navigate to the transaction you want to verify\n'
            '3. Find the JSON data field as illustrated above\n'
            '4. Copy the JSON data and paste it here',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Got it'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
