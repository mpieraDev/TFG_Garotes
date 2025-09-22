import 'package:flutter/material.dart';
import 'dart:async';
import 'package:demo_app/ble/ble_snackbar.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:convert';

class Dialogs {

    static Future conectionLostDialog(context) => showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(
        'Cloud connection lost',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white
        ),
      ),
      content: SizedBox(
        width: 100,
        child: Text('Connect the device to the internet if you want recived data to be stored',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
          maxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _sumbit(context);
          }, 
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xff72C3FF)
            ),
          )
        )
      ],
      backgroundColor: Color.fromARGB(255, 63, 63, 63),
    )
  );

  static Future incorrectDeviceDialog(context) => showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(
        'Device missmatch',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white
        ),
      ),
      content: SizedBox(
        width: 100,
        child: Text('Please connect to FLUTTERAPP',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
          maxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _sumbit(context);
          }, 
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xff72C3FF)
            ),
          )
        )
      ],
      backgroundColor: Color.fromARGB(255, 63, 63, 63),
    )
  );

  static Future connectionWithDroneLost(context) => showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(
        'Connection with drone lost',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white
        ),
      ),
      content: SizedBox(
        width: 100,
        child: Text('Retrying...',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
          maxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _sumbit(context);
          }, 
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xff72C3FF)
            ),
          )
        )
      ],
      backgroundColor: Color.fromARGB(255, 63, 63, 63),
    )
  );

  static Future connectionWithDroneEstablished(context) => showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(
        'Connection with drone established',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white
        ),
      ),
      content: SizedBox(
        width: 100,
        child: Text('Connection succesfull',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
          maxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _sumbit(context);
          }, 
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xff72C3FF)
            ),
          )
        )
      ],
      backgroundColor: Color.fromARGB(255, 63, 63, 63),
    )
  );

  static Future<void> changeChannelDialog(context, TextEditingController controller, BluetoothCharacteristic? channel, String? canal) => showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(
        'Select channel (0 / 125)',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white
        ),
      ),
      content: SizedBox(
        width: 100,
        child: TextField(
          controller: controller,
          onSubmitted: (String value) {
            int? valueToInt = int.tryParse(value);
            if (valueToInt != null) {
              if (valueToInt >= 0 && valueToInt <= 125) {
                canal = value;
              } else {
                canal = null;
              }
            } else {
              canal = null;
            }
          },
        )
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (channel != null && canal != null) {
              List<int> bytes = utf8.encode(canal!);
              channel.write(bytes, withoutResponse: true);
              _sumbit(context);
              print("soy tontito");
            } else {
              Snackbar.show(ABC.c, "invalid format", success: false);
              print("hello world");
            }
          }, 
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xff72C3FF)
            ),
          )
        )
      ],
      backgroundColor: Color.fromARGB(255, 63, 63, 63),
    )
  );

  static Future conectionBLELostDialog(context) => showDialog(
    context: context, 
    builder: (context) => AlertDialog(
      contentPadding: EdgeInsets.all(20),
      title: Text(
        'BLE connection lost',
        style: TextStyle(
          fontSize: 24,
          color: Colors.white
        ),
      ),
      content: SizedBox(
        width: 100,
        child: Text('Retry to connect',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white
          ),
          maxLines: 2,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _sumbit(context);
          }, 
          child: Text(
            'OK',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xff72C3FF)
            ),
          )
        )
      ],
      backgroundColor: Color.fromARGB(255, 63, 63, 63),
    )
  );

  static void _sumbit(context) {
    Navigator.of(context).pop();
  }
}