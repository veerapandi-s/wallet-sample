// ignore_for_file: empty_catches, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:magic_sample/home.dart';
import 'package:magic_sdk/magic_sdk.dart';

void main() {
  runApp(const MyApp());
  Magic.instance = Magic.custom(
    "pk_live_ABC41AC55D59C04D",
    rpcUrl: 'https://ropsten.infura.io/v3/66b8e081633b4153b9e2600b8e607697',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}
