import 'package:demo_app/icons/myicon.dart';
import 'package:flutter/material.dart';
import 'package:demo_app/connectivity/check_connectivity_class.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MyIcons {
  final List<MyIcon> _icons = [];
  final double? width;
  final double? height;
  
  MyIcons({this.width, this.height}) {
    initIcons();
  }

  void initIcons() {

    _icons.add(
      MyIcon(
        name: 'BLE',
        path: 'assets/icons/BLE.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'BLE_WHITE',
        path: 'assets/icons/BLE_WHITE.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'BLE_RED',
        path: 'assets/icons/BLE_RED.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'BATTERY_GREEN',
        path: 'assets/icons/BATTERY_GREEN.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'BATTERY_WHITE',
        path: 'assets/icons/BATTERY_WHITE.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'WIFI_WHITE',
        path: 'assets/icons/WIFI.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'WIFI_GREEN',
        path: 'assets/icons/WIFI.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'WIFI_RED',
        path: 'assets/icons/WIFI_RED.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'SPEED',
        path: 'assets/icons/SPEED.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'SPEED_WHITE',
        path: 'assets/icons/SPEED_WHITE.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'PACKETLOSS',
        path: 'assets/icons/DATARATE.png'
      )
    );

    _icons.add(
      MyIcon(
        name: 'PACKETLOSS_WHITE',
        path: 'assets/icons/DATARATE_WHITE.png'
      )
    );

  }

  Future<Image?> searchByNameAsync(String name, {double? width, double? height}) async {
    for (MyIcon icon in _icons) {
      if (icon.name == name) {
        return Image.asset(
          icon.path,
          alignment: Alignment.center,
          height: (height == null) ? this.height : height,
          width: (width == null) ? this.width : width,
        );
      }
    } 

    return null;
  }

  Image? searchByName(String name) {
    for (MyIcon icon in _icons) {
      if (icon.name == name) {
        return Image.asset(
          icon.path,
          alignment: Alignment.center,
          height: height,
          width: width,
        );
      }
    } 

    return null;
  }
}