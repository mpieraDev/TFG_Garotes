import 'dart:async';

import 'package:demo_app/pages/controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter/services.dart';

import 'package:demo_app/ble/ble_snackbar.dart';
import 'package:demo_app/ble/scan_result_tile.dart';
import 'package:demo_app/ble/system_device_tile.dart';

import 'loading_screen.dart';
import 'package:demo_app/user_mesages/dialogs.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  List<BluetoothDevice> _systemDevices = [];
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  late StreamSubscription<bool> _isScanningSubscription;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    setState(() {
      isLoading = false;
      print(
        'HELLOOO------------------------------------------------------------------------------------',
      );
    });

    _scanResultsSubscription = FlutterBluePlus.scanResults.listen(
      (results) {
        _scanResults = results;
        if (mounted) {
          setState(() {});
        }
      },
      onError: (e) {
        Snackbar.show(ABC.b, prettyException("Scan Error:", e), success: false);
      },
    );

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((state) {
      _isScanning = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    super.dispose();
  }

  Future onScanPressed() async {
    try {
      // `withServices` is required on iOS for privacy purposes, ignored on android.
      var withServices = [Guid("180f")]; // Battery Level Service
      _systemDevices = await FlutterBluePlus.systemDevices(withServices);
    } catch (e) {
      Snackbar.show(
        ABC.b,
        prettyException("System Devices Error:", e),
        success: false,
      );
      print(e);
    }
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    } catch (e) {
      Snackbar.show(
        ABC.b,
        prettyException("Start Scan Error:", e),
        success: false,
      );
      print(e);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      FlutterBluePlus.stopScan();
    } catch (e) {
      Snackbar.show(
        ABC.b,
        prettyException("Stop Scan Error:", e),
        success: false,
      );
      print(e);
    }
  }
  /*
  void onConnectPressed(BluetoothDevice device) {
    //if (device.advName == 'FLUTTERAPP') {
    setState(() {
      isLoading = true;
    });

    device
        .connect(autoConnect: false)
        .catchError((e) {
          Snackbar.show(
            ABC.c,
            prettyException("Connect Error:", e),
            success: false,
          );
        })
        .whenComplete(() {
          MaterialPageRoute route = MaterialPageRoute(
            builder: (context) => ControllerPage(device: device),
            settings: RouteSettings(name: '/controller'),
          );

          //Navigator.of(context).push(route);
          //Navigator.pushReplacement(context, route);

          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeRight,
            DeviceOrientation.landscapeLeft,
          ]);

          loadNextScreen(route);
        });
    //} else {
    //Dialogs.incorrectDeviceDialog(context);
    //}
  }*/

  void onConnectPressed(BluetoothDevice device) {
    if (device.advName == 'FLUTTERAPP') {
      setState(() {
        isLoading = true;
      });

      device
          .connect()
          .then((_) {
            // Use then() to ensure this runs ONLY after connection is successful
            print('Connected to device: ${device.name}');

            // Request MTU. This also returns a Future, so chain another .then()
            return device.requestMtu(
              512,
            ); // Always return the Future for chaining
          })
          .then((mtuValue) {
            print('MTU requested to $mtuValue');

            // IMPORTANT: Discover services. This also returns a Future.
            return device
                .discoverServices(); // Always return the Future for chaining
          })
          .then((services) {
            print('Discovered ${services.length} services.');

            // Now that connection and service discovery are complete, navigate
            MaterialPageRoute route = MaterialPageRoute(
              builder: (context) => ControllerPage(device: device),
              settings: RouteSettings(name: '/controller'),
            );

            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeRight,
              DeviceOrientation.landscapeLeft,
            ]);

            // Navigate to the next screen. The .whenComplete() here will handle final state.
            Navigator.of(context).push(route).whenComplete(() {
              setState(() {
                isLoading = false;
                _scanResults = [];
                _systemDevices = [];
              });
            });
          })
          .catchError((e) {
            // Catch any error that occurs in the entire chain (connect, requestMtu, discoverServices)
            print('BLE Operation Error: $e');
            Snackbar.show(
              ABC.c,
              prettyException("Connect Error:", e),
              success: false,
            );
            setState(() {
              isLoading = false; // Reset loading state on error
            });
            // Ensure device is disconnected if an error occurred
            device
                .disconnect(); // Explicitly disconnect if an error prevented full setup
          });
    } else {
      Dialogs.incorrectDeviceDialog(context);
    }
  }

  Future<void> loadNextScreen(MaterialPageRoute route) async {
    await Future.delayed(Duration(milliseconds: 1000));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        print('DONE---------------------------------------------------------');
        Navigator.of(context).push(route).whenComplete(() {
          setState(() {
            isLoading = false;
            _scanResults = [];
            _systemDevices = [];
          });
        });
      }
    });
  }

  Future onRefresh() {
    if (_isScanning == false) {
      FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));
    }
    if (mounted) {
      setState(() {});
    }
    return Future.delayed(Duration(milliseconds: 500));
  }

  Widget buildScanButton(BuildContext context) {
    if (FlutterBluePlus.isScanningNow) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else {
      return FloatingActionButton(
        child: const Text("SCAN", style: TextStyle(color: Colors.white)),
        onPressed: onScanPressed,
        backgroundColor: Color(0Xff72C3FF),
      );
    }
  }

  List<Widget> _buildSystemDeviceTiles(BuildContext context) {
    return _systemDevices
        .map(
          (d) => SystemDeviceTile(
            device: d,
            onOpen:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ControllerPage(device: d),
                    settings: RouteSettings(name: '/DeviceScreen'),
                  ),
                ),
            onConnect: () => onConnectPressed(d),
          ),
        )
        .toList();
  }

  List<Widget> _buildScanResultTiles(BuildContext context) {
    return _scanResults
        .where(
          (r) =>
              r.advertisementData.connectable &&
              r.advertisementData.advName.isNotEmpty,
        )
        .map(
          (r) => ScanResultTile(
            result: r,
            onTap: () => onConnectPressed(r.device),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return (isLoading)
        ? LoadingScreen()
        : ScaffoldMessenger(
          //key: Snackbar.snackBarKeyB,
          child: Scaffold(
            backgroundColor: Color(0xff737373),
            appBar: AppBar(
              title: const Text(
                'Find Devices',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Color(0xff656565),
            ),
            body: RefreshIndicator(
              onRefresh: onRefresh,
              child: ListView(
                children: <Widget>[
                  ..._buildSystemDeviceTiles(context),
                  ..._buildScanResultTiles(context),
                ],
              ),
            ),
            floatingActionButton: buildScanButton(context),
          ),
        );
  }
}
