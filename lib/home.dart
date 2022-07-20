import 'package:flutter/material.dart';
import 'package:magic_sample/magic_home.dart';
import 'package:magic_sample/wallet_connect.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MagicHome()));
                },
                child: const Text("Magic Example")),
          ),
          ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const WalletIntegration()));
              },
              child: const Text("Wallet Connect Example"))
        ],
      ),
    );
  }
}
