// ignore_for_file: avoid_print
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:magic_sample/config/erc20_abi.dart';
import 'package:magic_sdk/magic_sdk.dart';
import 'package:magic_sdk/provider/rpc_provider.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class MagicHome extends StatefulWidget {
  const MagicHome({Key? key}) : super(key: key);

  @override
  State<MagicHome> createState() => _MagicHomeState();
}

class _MagicHomeState extends State<MagicHome> {
  Magic magic = Magic.instance;
  Uint8List payload = convertStringToUint8List("message");
  late MagicCredential credent;
  late RpcProvider provider;
  String contractAddress = "0x071e842e2c71CF22E40Df4f1a3744377E5bC6b5A";
  final myController = TextEditingController(text: 'veerapandi@rage.fan');
  EthereumAddress toEthAddress =
      EthereumAddress.fromHex("0xD5C7df686Cdc0636863b8ac1C08AE8e60Fcafebe");
  String rpcURL =
      "https://ropsten.infura.io/v3/66b8e081633b4153b9e2600b8e607697";
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 1), () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Magic Demo'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FutureBuilder<bool>(
                  future: checkSession(),
                  builder:
                      (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!) {
                        return Column(
                          children: [
                            const Text("User is logged in "),
                            ElevatedButton(
                                onPressed: logOut, child: const Text("Logout"))
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 32.0),
                              child: TextFormField(
                                controller: myController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your email',
                                ),
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 20,
                            ),
                            ElevatedButton(
                              onPressed: login,
                              child: const Text('Login With Magic Link'),
                            ),
                          ],
                        );
                      }
                    } else if (snapshot.hasError) {
                      return const Center(
                        child: Text("Error in Log in"),
                      );
                    } else {
                      return Column(
                        children: const [
                          Center(
                            child: CircularProgressIndicator.adaptive(),
                          ),
                          Text("Loading")
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: signMessagePersonal,
                  child: const Text("Sign Message"),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: sendTrans,
                  child: const Text("Sent Native Token"),
                ),
                const SizedBox(
                  height: 10,
                ),
                ElevatedButton(
                  onPressed: sendERC20,
                  child: const Text("Sent ERC20 Token"),
                ),
              ],
            ),
          ),
        ),
        Magic.instance.relayer
      ],
    );
  }

  signMessagePersonal() async {
    try {
      await credent.getAccount();
      var persMess = await credent.personalSign(payload: payload);
      debugPrint("personalSign Sign $persMess");
      SnackBar snackBar =
          SnackBar(content: Text('Sign Data Personnel : $persMess'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      SnackBar snackBar =
          SnackBar(content: Text('Error in siging Personel : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }

  signETH() async {
    try {
      await credent.getAccount();
      var ethMess = await credent.ethSign(payload: payload);
      SnackBar snackBar = SnackBar(content: Text('Sign Data Eth : $ethMess'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint("ETH Sign $ethMess");
    } catch (e) {
      SnackBar snackBar =
          SnackBar(content: Text('Error in siging Eth : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }

  sendTrans() async {
    try {
      await credent.getAccount();
      Transaction toSend = Transaction(
        from: credent.address,
        to: EthereumAddress.fromHex(
            '0x119810D0f52182D0F4A2C2B37516854e2EC3897f'),
        value: EtherAmount.fromUnitAndValue(EtherUnit.gwei, 1),
      );
      var tx = await credent.sendTransaction(toSend);
      SnackBar snackBar =
          SnackBar(content: Text('Eth Tx Hash : ${tx.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(tx);
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('Error in sending Native Token : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }

  sendERC20() async {
    EtherAmount? gasPrice;
    var client = Web3Client(rpcURL, Client());
    try {
      gasPrice = await client.getGasPrice();
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('Error in sending ERC20 Token : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }

    String abi = ABI.get("erc20");
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abi, "erc20"),
        EthereumAddress.fromHex(contractAddress));

    Transaction tx = Transaction.callContract(
        from: credent.address,
        contract: contract,
        function: contract.function("transfer"),
        gasPrice: gasPrice,
        parameters: [
          toEthAddress,
          EtherAmount.fromUnitAndValue(EtherUnit.ether, 1).getInWei
        ]);
    var gas = await client.estimateGas(
        sender: credent.address, to: toEthAddress, data: tx.data);
    var newTx = tx.copyWith(maxGas: gas.toInt());
    if (newTx.data == null) return;
    try {
      var txb = await credent.sendTransaction(newTx);
      SnackBar snackBar =
          SnackBar(content: Text('ERC20 Tx Hash : ${txb.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(txb);
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('Error in sending ERC20 Token : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }

  login() async {
    try {
      await magic.auth.loginWithMagicLink(email: myController.text);
      provider = magic.user.provider;
      credent = MagicCredential(provider);
      await credent.getAccount();
      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  logOut() async {
    try {
      await magic.user.logout();
      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> checkSession() async {
    try {
      var status = await magic.user.isLoggedIn();
      provider = magic.user.provider;
      credent = MagicCredential(provider);
      await credent.getAccount();
      return status;
    } catch (e) {
      return false;
    }
  }
}

Uint8List convertStringToUint8List(String str) {
  final List<int> codeUnits = str.codeUnits;
  final Uint8List unit8List = Uint8List.fromList(codeUnits);

  return unit8List;
}
