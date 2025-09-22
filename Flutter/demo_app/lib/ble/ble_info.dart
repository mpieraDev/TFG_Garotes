import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class MyBleInfo {
  final List<MyServices> _myServices = [];
  final List<MyCharacteristics> _myCharacteristics = [];

  MyBleInfo() {
    initServices();
    initCharacteristics();
  }

  List<MyServices> get services => _myServices;
  List<MyCharacteristics> get characteristics => _myCharacteristics;

  void initServices() {
    /*_myServices.add(
      MyServices(
        serviceName: 'Incoming', 
        serviceUuid: Guid('PLACEHOLDER')
      )
    );*/
  }

  void initCharacteristics() {
    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'batteryLife', 
        characteristicUuid: Guid('beb5483e-36e1-4688-b7f5-ea07361b26a8')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'packetLoss', 
        characteristicUuid: Guid('02a486bf-cb21-4e5b-8568-d0c6396ee39a')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'speed', 
        characteristicUuid: Guid('16c41f0f-15b3-4de9-a3de-f6ad2c9bd33f')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'gpsError', 
        characteristicUuid: Guid('e4265390-1c58-4104-b343-b709c62ea0c5')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'depth', 
        characteristicUuid: Guid('52c6e51d-5039-4d3e-913b-168e4aab9aa5')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'latitude', 
        characteristicUuid: Guid('06edbb9a-8a14-464a-a45c-5074faa25500')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'longitude', 
        characteristicUuid: Guid('d3b0e284-ed32-4d7c-a20e-c99413701d62')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'rotation', 
        characteristicUuid: Guid('d70e084e-939a-48a7-ba7c-7e3ca1736553')
      )
    );

     _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'datarate', 
        characteristicUuid: Guid('8394fae8-6ab5-4a6a-9e91-7d3852a59e36')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'onChannelChangedError', 
        characteristicUuid: Guid('4bd3198c-710a-405b-87c6-73e406c593fa')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'datagathering', 
        characteristicUuid: Guid('212855ff-df2b-4658-b49c-c26a1af73c2e')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'channel', 
        characteristicUuid: Guid('9d469b60-3923-4d6d-bf05-4e7eb15aaf97')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'connection', 
        characteristicUuid: Guid('666dc20d-e9d6-4cca-9f89-69706e97981e')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'RM', 
        characteristicUuid: Guid('b345013c-78cd-44ff-ae59-054bc66cda1b')
      )
    );

    _myCharacteristics.add(
      MyCharacteristics(
        characteristicName: 'LM', 
        characteristicUuid: Guid('a197ac09-efb1-4e6d-b378-3a04760aa767')
      )
    );
  }
 }

class MyServices {
  final String _serviceName;
  final Guid _serviceUuid;

  MyServices({required String serviceName, required Guid serviceUuid}) 
  : _serviceUuid = serviceUuid, 
  _serviceName = serviceName;

  String get serviceName => _serviceName;
  Guid get serviceUuid => _serviceUuid;
}

class MyCharacteristics {
  final String _characteristicName;
  final Guid _characteristicUuid;
  late final BluetoothCharacteristic? _c;

  MyCharacteristics({required String characteristicName, required Guid characteristicUuid}) 
  : _characteristicUuid = characteristicUuid, 
  _characteristicName = characteristicName;

  set characteristic(BluetoothCharacteristic newCharacteristic) => _c = newCharacteristic;

  String get characteristicName => _characteristicName;
  Guid get characteristicUuid => _characteristicUuid;
  BluetoothCharacteristic? get c => _c;
}