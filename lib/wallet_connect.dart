// Create a connector
// ignore_for_file: avoid_print
import 'package:http/http.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:web3dart/web3dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'config/erc20_abi.dart';

class WalletIntegration extends StatefulWidget {
  const WalletIntegration({Key? key}) : super(key: key);

  @override
  State<WalletIntegration> createState() => _WalletIntegrationState();
}

class _WalletIntegrationState extends State<WalletIntegration> {
  SessionStatus? sessionStatus;
  String? address;
  int? chainId;
  bool isWalletConnected = false;
  String contractAddress = "0x071e842e2c71CF22E40Df4f1a3744377E5bC6b5A";
  String toAddress = "0xD5C7df686Cdc0636863b8ac1C08AE8e60Fcafebe";
  EthereumAddress toEthAddress =
      EthereumAddress.fromHex("0xD5C7df686Cdc0636863b8ac1C08AE8e60Fcafebe");
  String rpcURL =
      "https://ropsten.infura.io/v3/66b8e081633b4153b9e2600b8e607697";

  late EthereumWalletConnectProvider provider;
  SessionStorage? sessionStorage;
  final WalletConnect connector = WalletConnect(
    bridge: 'https://bridge.walletconnect.org',
    clientMeta: const PeerMeta(
      name: 'Rage Test App',
      description: 'Testing purpose wallet',
      url: 'https://rage.fan',
      icons: ['https://rage.fan/images/logo/rage-fan-white.png'],
    ),
  );

  @override
  void initState() {
    myInit();
    super.initState();
  }

  myInit() async {
    provider = EthereumWalletConnectProvider(connector, chainId: 3);
  }

  @override
  void dispose() {
    connector.killSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet Connect Integration'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(child: Text("Status : $isWalletConnected")),
          ElevatedButton(
            onPressed: events,
            child: const Text('Wallet Connect'),
          ),
          ElevatedButton(
            onPressed: signMessage,
            child: const Text('Sign Message'),
          ),
          ElevatedButton(
            onPressed: sendETH,
            child: const Text('Send Native Transaction'),
          ),
          ElevatedButton(
            onPressed: sendERC20,
            child: const Text('Send ERC 20 Transaction'),
          ),
          ElevatedButton(
              onPressed: killSession, child: const Text('Disconnect')),
        ],
      ),
    );
  }

  events() async {
    if (!connector.connected) {
      checkSession();
    } else {
      setState(() {
        isWalletConnected = true;
      });
    }
    // Subscribe to events
    connector.on('connect', (session) async {
      // sessionStorage.store(session?.ses)
      setState(() {
        isWalletConnected = true;
      });
      debugPrint("connect: " + session.toString());
      address = sessionStatus?.accounts[0];
      chainId = sessionStatus?.chainId;
      debugPrint("Address: " + address!);
      debugPrint("Chain Id: " + chainId.toString());
    });

    connector.on('session_request', (payload) {
      debugPrint("session request: " + payload.toString());
    });

    connector.on('session_update', (payload) {
      debugPrint(payload.toString());
    });

    connector.on('disconnect', (session) {
      setState(() {
        isWalletConnected = false;
      });
      debugPrint("disconnect: " + session.toString());
    });

    connector.registerListeners(onSessionUpdate: (payload) {
      debugPrint(payload.toString());
    });
  }

  newSession() async {
    if (!connector.connected) {
      try {
        sessionStatus = await connector.createSession(
          // chainId: 3,
          onDisplayUri: (uri) async {
            var launchURL = Uri.parse(uri);
            await launchUrl(launchURL);
          },
        );
      } catch (e) {
        SnackBar snackBar = SnackBar(
            content: Text('Error in connecting to wallet : ${e.toString()}'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        debugPrint(e.toString());
      }
    }
  }

  checkSession() async {
    if (connector.connected) return;
    try {
      sessionStatus = await connector.connect(
        // chainId: 3,
        onDisplayUri: (uri) async {
          var launchURL = Uri.parse(uri);
          await launchUrl(launchURL);
        },
      );
      debugPrint(sessionStatus.toString());
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('Error in connecting to wallet : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }

  sendERC20() async {
    if (address == null) {
      return;
    }
    var userAddress = EthereumAddress.fromHex(address!);

    String abi = ABI.get("erc20");
    DeployedContract contract = DeployedContract(
        ContractAbi.fromJson(abi, "erc20"),
        EthereumAddress.fromHex(contractAddress));

    Transaction tx = Transaction.callContract(
        from: userAddress,
        contract: contract,
        function: contract.function("transfer"),
        parameters: [
          toEthAddress,
          EtherAmount.fromUnitAndValue(EtherUnit.ether, 1).getInWei
        ]);

    if (tx.data == null) return;
    var client = Web3Client(rpcURL, Client());
    var gasPrice = await client.getGasPrice();
    var gas = await client.estimateGas(
        sender: userAddress,
        to: contract.address,
        data: tx.data,
        gasPrice: gasPrice);
    try {
      var txb = await provider.sendTransaction(
          from: address!,
          data: tx.data,
          to: contractAddress,
          gasPrice: gasPrice.getInWei,
          gas: gas.toInt());
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

    return contract;
  }

  sendETH() async {
    if (address == null) {
      return;
    }
    try {
      var tx = await provider.sendTransaction(
        from: address!,
        to: toEthAddress.hexEip55,
        value: EtherAmount.fromUnitAndValue(EtherUnit.finney, 1).getInWei,
      );
      SnackBar snackBar =
          SnackBar(content: Text('Eth Tx Hash : ${tx.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      return tx;
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('Error in sending Native Token : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  signMessage() async {
    if (address == null) {
      return;
    }
    try {
      var method = "personal_sign";
      var message = "Test String";
      var paramsForSign = [message, address];
      var tx = await connector.sendCustomRequest(
          method: method, params: paramsForSign);
      SnackBar snackBar =
          SnackBar(content: Text('Sign Data : ${tx.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(tx);
    } catch (e) {
      SnackBar snackBar =
          SnackBar(content: Text('Error in siging : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }

  killSession() async {
    try {
      var tx = await connector.killSession();
      setState(() {
        isWalletConnected = false;
      });
      SnackBar snackBar =
          SnackBar(content: Text('Terminated Session : ${tx.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      SnackBar snackBar = SnackBar(
          content: Text('Error in Terminating Session : ${e.toString()}'));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint(e.toString());
    }
  }
}
