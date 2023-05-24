import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  SignClient? wcClient;
  AuthClient? authClient;
  SessionData? session;

  AuthResponse? authResponse;

  @override
  void initState() {
    super.initState();
    _createSign();
  }

  Future<void> _createSign() async {
    wcClient = await SignClient.createInstance(
      core: Core(
        projectId: '<project-id-here>',
      ),
      metadata: const PairingMetadata(
        name: 'Ensemble wallet',
        description: 'Dapp api',
        url: 'https://ensembleui.com/',
        icons: ['https://ensembleui.com/assets/images/logo.svg'],
      ),
    );
    authClient = await AuthClient.createInstance(
      core: Core(
        projectId: '<project-id-here>',
      ),
      metadata: const PairingMetadata(
        name: 'Ensemble wallet',
        description: 'Dapp api',
        url: 'https://ensembleui.com/',
        icons: ['https://ensembleui.com/assets/images/logo.svg'],
      ),
    );

    authClient?.onAuthResponse.subscribe((auth) {
      setState(() {
        authResponse = auth;
      });
    });

    wcClient?.onSessionConnect.subscribe((sessionConnector) {
      setState(() {
        session = sessionConnector?.session;
      });
    });
    wcClient?.onSessionEvent.subscribe((event) {
      debugPrint(event?.data);
    });
    wcClient?.onSessionPing.subscribe((ping) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Ping ${ping?.id}'),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo dapp'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: double.maxFinite),
          if (session != null)
            Column(
              children: [
                InkWell(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(
                        text: session!.namespaces['eip155']?.accounts[0]
                                .split(':')[2] ??
                            ''));

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                      ),
                    );
                  },
                  child: Text(
                      'Wallet Public key ${session!.namespaces['eip155']?.accounts[0].split(':')[2]}'),
                ),
                Text(session!.peer.metadata.name),
                Text(session!.peer.metadata.url),
                Text(session!.peer.metadata.description),
              ],
            ),
          TextButton(
            onPressed: () async {
              // final resp = await wcClient?.requestAuth(
              //   params: AuthRequestParams(
              //     chainId: 'eip155',
              //     nonce: AuthUtils.generateNonce(),
              //     domain: 'localhost:3000',
              //     aud: 'http://localhost:3000/login',
              //     ),
              //   );

              ConnectResponse? resp = await wcClient?.connect(
                requiredNamespaces: {
                  'eip155': RequiredNamespace(
                    chains: ['eip155:1'], // Ethereum chain
                    methods: EthereumMethods.getMethodList(),
                    events: [
                      "accountsChanged",
                      "chainChanged"
                    ], // Requestable Methods
                  ),
                },
                optionalNamespaces: {
                  'kadena': const RequiredNamespace(
                    chains: ['kadena:mainnet01'],
                    methods: ['kadena_quicksign_v1'],
                    events: [],
                  )
                },
              );

              if (resp?.uri == null || !mounted) return;
              Clipboard.setData(ClipboardData(text: resp!.uri!.toString()));
              final uri = 'https://sequence.app/wc?uri=${resp.uri!}';
              launchUrlString(uri, mode: LaunchMode.externalApplication);
              final s = (await resp.session.future) as SessionData?;

              setState(() => session = s);
              session?.expiry;
            },
            child: const Text('Connect'),
          ),
          TextButton(
            onPressed: () async {
              final address =
                  session!.namespaces['eip155']?.accounts[0].split(':')[2];
              final balance = await getAccountBalance(address!, 'eip155:1');
              print(balance);
            },
            child: const Text('balance'),
          ),
        ],
      ),
    );
  }
}

class EthereumMethods {
  static const String ethSendTransaction = "eth_sendTransaction";
  static const String ethSignTransaction = "eth_signTransaction";
  static const String ethSign = "eth_sign";
  static const String personalSign = "personal_sign";

  static List<String> getMethodList() {
    return [ethSendTransaction, ethSignTransaction, ethSign, personalSign];
  }
}

Map<int, Map<String, dynamic>> rpcProvidersByChainId = {
  1: {
    "name": "Ethereum Mainnet",
    "baseURL": "https://mainnet.infura.io/v3/5dc0df7abe4645dfb06a9a8c39ede422",
    "token": {
      "name": "Ether",
      "symbol": "ETH",
    },
  },
  5: {
    "name": "Ethereum Goerli",
    "baseURL": "https://goerli.infura.io/v3/5dc0df7abe4645dfb06a9a8c39ede422",
    "token": {
      "name": "Ether",
      "symbol": "ETH",
    },
  }
};

Future<BigInt?> getAccountBalance(String address, String chainId) async {
  final ethChainId = chainId.split(":")[1];
  final rpc = rpcProvidersByChainId[int.parse(ethChainId)];

  if (rpc == null) return null;

  final baseURL = rpc['baseURL'];
  final token = rpc['token'];

  final response = await http.post(
    Uri.parse(baseURL),
    body: json.encode({
      "jsonrpc": "2.0",
      "method": "eth_getBalance",
      "params": [address, "latest"],
      "id": 1
    }),
  );

  final data = json.decode(response.body);
  final balance = hexToInt(data['result']);

  return balance;
}

String strip0x(String hex) {
  if (hex.startsWith('0x')) return hex.substring(2);
  return hex;
}

BigInt hexToInt(String hex) {
  return BigInt.parse(strip0x(hex), radix: 16);
}
