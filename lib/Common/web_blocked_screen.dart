import 'package:flutter/material.dart';

class WebBlockedScreen extends StatelessWidget {
  const WebBlockedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/Block.png', width: 480),
            const SizedBox(height: 16),
            const Text('모바일 환경에서만 이용할 수 있어요.', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
