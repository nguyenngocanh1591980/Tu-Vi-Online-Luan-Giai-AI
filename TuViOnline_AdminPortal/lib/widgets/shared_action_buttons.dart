import 'package:flutter/material.dart';

class SharedActionButtons extends StatelessWidget {
  final VoidCallback onAiPressed;
  final VoidCallback onSharePressed;

  const SharedActionButtons({
    Key? key,
    required this.onAiPressed,
    required this.onSharePressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: onAiPressed,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Nhờ AI luận giải (10 Coin)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
        ElevatedButton.icon(
          onPressed: onSharePressed,
          icon: const Icon(Icons.share),
          label: const Text('Share to Forum'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      ],
    );
  }
}
