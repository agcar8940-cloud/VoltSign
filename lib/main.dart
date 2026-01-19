import 'package:flutter/cupertino.dart';
import 'dart:ffi';
import 'dart:io';

// 1. Define the C function signature (How it looks in C)
typedef GetUidC = Int32 Function();
// 2. Define the Dart function signature (How we use it in Flutter)
typedef GetUidDart = int Function();

void main() {
  runApp(const VoltSignApp());
}

class VoltSignApp extends StatelessWidget {
  const VoltSignApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'VoltSign',
      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.activeBlue,
      ),
      home: VoltSignHomePage(),
    );
  }
}

class VoltSignHomePage extends StatefulWidget {
  const VoltSignHomePage({super.key});

  @override
  State<VoltSignHomePage> createState() => _VoltSignHomePageState();
}

class _VoltSignHomePageState extends State<VoltSignHomePage> {
  int _currentUid = 501;
  int _effectiveUid = 501;

  // 3. Connect to the Native Library
  // We use DynamicLibrary.process() because on iOS,
  // custom C files are linked directly into the main app binary.
  final DynamicLibrary _nativeLib = Platform.isIOS
      ? DynamicLibrary.process()
      : DynamicLibrary.open('voltroot.so');

  void _checkRoot() {
    // 4. Look up your C functions by the names you wrote in voltroot.c
    final GetUidDart getUid = _nativeLib
        .lookup<NativeFunction<GetUidC>>('get_current_uid')
        .asFunction();
    final GetUidDart getEuid = _nativeLib
        .lookup<NativeFunction<GetUidC>>('get_effective_uid')
        .asFunction();

    setState(() {
      // 5. Call the C function and update the UI
      _currentUid = getUid();
      _effectiveUid = getEuid();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('VoltSign Exploit Tool'),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Current Status:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              Text(
                _currentUid == 0 ? 'ROOTED' : 'Sandboxed (UID: $_currentUid)',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _currentUid == 0
                      ? CupertinoColors.activeGreen
                      : CupertinoColors.destructiveRed,
                ),
              ),
              const SizedBox(height: 40),
              CupertinoButton.filled(
                onPressed: _checkRoot,
                child: const Text('Check Current UID'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
