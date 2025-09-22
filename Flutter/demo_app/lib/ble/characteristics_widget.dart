import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CharacteristicWidget extends StatefulWidget {
  final BluetoothCharacteristic? characteristic;
  // final String icon;
  final String unit;
  final double width;

  const CharacteristicWidget({Key? key, required this.characteristic, required this.width, /*required this.icon,*/ required this.unit}) : super(key: key);

  @override
  State<CharacteristicWidget> createState() => _CharacteristicWidgetState();
}

class _CharacteristicWidgetState extends State<CharacteristicWidget> {
  List<int> _bytes = [];
  String? decodedData;

  late StreamSubscription<List<int>> _lastValueSubscription;

  BluetoothCharacteristic? get c => widget.characteristic;

  @override
  void initState() {
    super.initState();
    if (c != null) {
      _lastValueSubscription = c!.lastValueStream.listen((bytes) async {
        _bytes = bytes;
        decodedData = await processRecivedBytes(_bytes);
        if (mounted) {
          setState(() {});
        }
      });

      subscribeToCharacteristic();
    }

    print('CHARACTERISTIC IS EMPTY? : $c');
  }

  @override
  void dispose() {
    _lastValueSubscription.cancel();
    super.dispose();
  }

  Future<String>  processRecivedBytes(List<int> bytes) async {
    return String.fromCharCodes(bytes);
  }

  /*Future<double>  processRecivedBytes(List<int> bytes) async {
    /////////////////////////////////////////////////////////////////////////////////////// 
    /// ACABAR
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    double decodedData = byteData.getFloat32(0, Endian.little);
    return decodedData;
  }*/

  Future<void> subscribeToCharacteristic() async {
    try {
      await c!.setNotifyValue(true);
    } catch (e) {
      print('error when subscribing: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: Center(
      child: Text(
        '${(c != null) ? decodedData : 'null'} ${widget.unit}', 
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.start,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
      ),
    );
  }
}
