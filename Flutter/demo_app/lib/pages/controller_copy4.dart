/*import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:location/location.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:demo_app/icons/myicons.dart';
import 'package:demo_app/markers/mymarkers.dart';
import 'package:demo_app/ble/ble_info.dart';
import 'package:demo_app/user_mesages/dialogs.dart';
import 'package:demo_app/ble/Characteristics_widget.dart';
import 'package:demo_app/connectivity/check_connectivity_class.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:math';
import 'package:demo_app/ble/ble_snackbar.dart';

class ControllerPage extends StatefulWidget {
  final BluetoothDevice device;

  const ControllerPage({super.key, required this.device});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  late TextEditingController controller;

  late String _mapStyleString;
  double beforeZoom = 12.151926040649414;
  late CameraPosition myPosition;

  late Image? bleStateImage;
  late Image? wifiStateImage;
  late Image? batteryStateImage;
  late Image? speedImage;
  late Image? packetLossImage;

  // Map Gesture configurations
  bool zoomGesturesConfig = true;
  bool rotateGesturesConfig = true;
  bool tiltGesturesConfig = true;
  bool scrollGesturesConfig = true;

  // Joystick Configurations
  bool isBlocked = false;

  // Conectivity
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _wifiSubscription;
  MyCustomMarkers myMarkers = MyCustomMarkers(size: 10);
  

  // Google Maps
  late final GoogleMapController _myController;
  final Completer<GoogleMapController> _controller = Completer();
  Set<Marker> markers = {};

  // User Location
  Location _locationController = new Location();
  LatLng? _currentPosition = null;
  PermissionStatus? _permisionGranted;

  // Drone Location
  LatLng? _dronePosition = null;
  double? latitudePos = null;
  double? longitudePos = null;
  double? latitudePosBefore = null;
  double? longitudePosBefore = null;
  double traveledDistanceDouble = 0;
  String traveledDistance = '0.00 Km';

  // Icons
  final MyIcons icons = MyIcons(width: null, height: 10);

  // BLE
  final MyBleInfo myBleInfo = MyBleInfo();
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  List<BluetoothService> _services = [];
  late StreamSubscription<List<int>> _connectionSubscription;
  late StreamSubscription<List<int>> _latitudeSubscription;
  late StreamSubscription<List<int>> _longitudeSubscription;

  // Characteristics
  BluetoothCharacteristic? batteryLife;
  BluetoothCharacteristic? packetLoss;
  BluetoothCharacteristic? speed;
  BluetoothCharacteristic? gpsError;
  BluetoothCharacteristic? depth;
  BluetoothCharacteristic? latitude;
  BluetoothCharacteristic? longitude;
  BluetoothCharacteristic? rotation;
  BluetoothCharacteristic? datarate;
  BluetoothCharacteristic? onChannelChangedError;
  BluetoothCharacteristic? datagathering;
  BluetoothCharacteristic? channel;
  BluetoothCharacteristic? connection;
  BluetoothCharacteristic? inputLM;
  BluetoothCharacteristic? inputRM;

  bool startDataGathering = false;

  // Loading screen


  initMarkers() async {
    await myMarkers.addPositionMarker(
      positionMarker: Marker(
        markerId: const MarkerId("USV"),
        position: const LatLng(41.37250958728433, 2.1921073916192357),
        icon: await BitmapDescriptor.asset(
          ImageConfiguration(size: Size(24, 24)), 
          'assets/icons/USV_POSITION.png'
        ),
      )
    );
    await myMarkers.addMarker(
      depth: 10,
      position: LatLng(41.37514419930947, 2.193664637736376),
      zoom: 12.151926040649414,
      id: 'caca',
    );

    print('MYMARKERS: ${myMarkers.getMarkers()}');

    setState(() {});
  }

  void initImages() {
    bleStateImage = icons.searchByName('BLE_WHITE');
    wifiStateImage = icons.searchByName('WIFI_WHITE');
    batteryStateImage = icons.searchByName('BATTERY_WHITE');
    speedImage = icons.searchByName('SPEED_WHITE');
    packetLossImage = icons.searchByName('PACKETLOSS_WHITE');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();

    rootBundle.loadString('assets/map/map_style.json').then((string) {
      _mapStyleString = string;
    });

    controller = TextEditingController();

    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        bleStateImage = icons.searchByName('BLE_RED');
        print("${widget.device.disconnectReason?.code} ${widget.device.disconnectReason?.description}");
        if(mounted) {
          conectionBLELostDialog();
        }
      }
      if (state == BluetoothConnectionState.connected) {
        bleStateImage = icons.searchByName('BLE_WHITE');
        print("RECONECTED AGAIN");
      }
    });
    
    //connectToDevice();
    discoverServices();
    initMarkers();
    initImages();
    setColorOnConnectionChange();
    getUserLocationUpdates();
  }

  @override
  void dispose() {

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp
    ]);
    
    widget.device.disconnect();
    _connectionStateSubscription.cancel();
    _connectionSubscription.cancel();
    _latitudeSubscription.cancel();
    _longitudeSubscription.cancel();
    _wifiSubscription.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> getUserLocationUpdates() async {
    bool _serviceEnabled;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    } else {
      print("service enabled");
    }

    _permisionGranted = await _locationController.hasPermission();
    
    if(_permisionGranted == PermissionStatus.denied) {
      _permisionGranted = await _locationController.requestPermission();
      if (_permisionGranted != PermissionStatus.granted) {
        print("GPS Doesn't work!!!! * 2");
        print('Permission status: $_permisionGranted');
        return;
      }
    }

    _locationController.onLocationChanged.listen((LocationData currentLocation) {
      if (currentLocation.latitude != null && currentLocation.longitude != null) {
        setState(() {
          _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
          /*myMarkers.UpdateUserPositionMarker(
            userPositionMarker: Marker(
              markerId: const MarkerId("UserPosition"),
              position: LatLng(currentLocation.latitude!, currentLocation.longitude!)
            )
          );
          print(_currentPosition);*/
        });
      }
    });
  }

  Future<void> connectToDevice() async {
    await widget.device.connect().catchError((e) {
      print('Connect Error: $e');
    });

    await discoverServices();
    setState(() {});
  }

  Future<void> discoverServices() async {
    try {
      print('DISCOVERING SERVICES -------------------------------------------------------');
      _services = await widget.device.discoverServices();
      await procesServices(_services);
      _droneConnectionControl();
      _dronePositionController();
    } catch (e) {
      print('Discover services Services failed: $e');
    }
  }

  Future<void> procesServices(List<BluetoothService> services) async {
    try {
      for (BluetoothService service in services) {
        await procesCharacteristics(service.characteristics);
      }
    } catch (e) {
      print('Proces Services failed: $e');
    }
  }

  Future<void> procesCharacteristics(List<BluetoothCharacteristic> characteristics) async {
    try {
      for (BluetoothCharacteristic c in characteristics) {
        print('RECEIVED CHARACTERISTIC UUID:  ${c.characteristicUuid}');
        for(MyCharacteristics myCharacteristic in myBleInfo.characteristics) {
          print('MY CHARACTERISTIC UUID:  ${myCharacteristic.characteristicUuid}');
          if (myCharacteristic.characteristicUuid == c.characteristicUuid) {
            print('CHARACTERISTIC MATCH FOUND');
            myCharacteristic.characteristic = c;
            assignBleCharacteristics(myCharacteristic);
          }
        }
      }

      setState(() {});
    } catch (e) {
      print('Proces characteristics failed: $e');
    }
  }

  void assignBleCharacteristics(MyCharacteristics myCharacteristic) {
    switch (myCharacteristic.characteristicName) {
      case 'batteryLife':
        batteryLife = myCharacteristic.c;
        print('batteryLife MATCH FOUND');
        break;
      case 'packetLoss':
        packetLoss = myCharacteristic.c;
        print('packetLoss MATCH FOUND');
        break;
      case 'speed':
        speed = myCharacteristic.c;
        print('speed MATCH FOUND');
        break;
      case 'gpsError':
        gpsError = myCharacteristic.c;
        print('gpsError MATCH FOUND');
        break;
      case 'depth':
        depth = myCharacteristic.c;
        print('depth MATCH FOUND');
        break;
      case 'latitude':
        latitude = myCharacteristic.c;
        print('latitude MATCH FOUND');
        break;
      case 'longitude':
        longitude = myCharacteristic.c;
        print('longitude MATCH FOUND');
        break;
      case 'rotation':
        rotation = myCharacteristic.c;
        print('rotation MATCH FOUND');
        break;
      case 'datarate':
        datarate = myCharacteristic.c;
        print('datarate MATCH FOUND');
        break;
      case 'onChannelChangedError':
        onChannelChangedError = myCharacteristic.c;
        print('onChannelChangedError MATCH FOUND');
        break;
      case 'datagathering':
        datagathering = myCharacteristic.c;
        print('datagathering MATCH FOUND');
        break;
      case 'channel':
        channel = myCharacteristic.c;
        print('channel MATCH FOUND');
        break;
      case 'connection':
        connection = myCharacteristic.c;
        print('connection MATCH FOUND');
        break;
      case 'RM':
        inputRM = myCharacteristic.c;
        print('inputRM MATCH FOUND');
        break;
      case 'LM':
        inputLM = myCharacteristic.c;
        print('inputLM MATCH FOUND');
        break;
    }
  }

  void _positionAssign(CameraPosition position) {
    myPosition = position;
    //debugPrint('zoom 1: ${position.zoom}');
  }

  Future<void> _droneConnectionControl() async {
    List<int> _bytes = [];
    String? decodedData;

    if (connection != null) {
      _connectionSubscription = connection!.lastValueStream.listen((bytes) async {
        _bytes = bytes;
        decodedData = String.fromCharCodes(_bytes);
        if (mounted) {
          setState(() {
            if (decodedData == 'disconected') {
              Dialogs.connectionWithDroneLost(context);
            } else if (decodedData == 'connected') {
              Dialogs.connectionWithDroneEstablished(context);
            }
          });
        }
      });

      try {
        await connection!.setNotifyValue(true);
      } catch (e) {
        print('error when subscribing: $e');
      }
    }
  }

  Future<void> _dronePositionController() async{
    List<int> bytesLat = [];
    String? decodedDataLat;

    List<int> bytesLon = [];
    String? decodedDataLon;

    if (latitude != null) {
      _latitudeSubscription = latitude!.lastValueStream.listen((bytes) async {
        bytesLat = bytes;
        decodedDataLat = String.fromCharCodes(bytesLat);
        if (mounted) {
          setState(() {
            latitudePosBefore = latitudePos;
            latitudePos = double.tryParse(decodedDataLat!);
            print("longitude updated: $latitudePos");
          });
        }
      });

      try {
        await latitude!.setNotifyValue(true);
      } catch (e) {
        print('error when subscribing: $e');
      }
    }

    if (longitude != null) {
      _longitudeSubscription = longitude!.lastValueStream.listen((bytes) async {
        bytesLon = bytes;
        decodedDataLon = String.fromCharCodes(bytesLon);
        if (mounted) {
          setState(() {
            longitudePosBefore = longitudePos;
            longitudePos = double.tryParse(decodedDataLon!);
            print("longitude updated: $longitudePos");
            updateDronePosition();
            updateTraveledDistance();
          });
        }
      });

      try {
        await longitude!.setNotifyValue(true);
      } catch (e) {
        print('error when subscribing: $e');
      }
    }
  }
  
  Future<void> updateDronePosition() async {
    if (latitudePos != null && longitudePos != null) {
      await myMarkers.updateDronePositionMarker(
        myPosition.zoom, 
        13, 
        latitude: latitudePos!, 
        longitude: longitudePos!
      );
    }
  }

  double degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  double calculateDistance(LatLng posBefore, LatLng posNow) {
    const double earthRadiusKm = 6371.0;
    // Convertir grados a radianes
    final double posBeforeLatRad = degreesToRadians(posBefore.latitude);
    final double posBeforeLonRad = degreesToRadians(posBefore.longitude);
    final double posNowLatRad = degreesToRadians(posNow.latitude);
    final double posNowLonRad = degreesToRadians(posNow.longitude);

    // Diferencias de latitud y longitud
    final double deltaLat = posNowLatRad - posBeforeLatRad;
    final double deltaLon = posNowLonRad - posBeforeLonRad;

    // Aplicar la fórmula de Haversine
    final double a = pow(sin(deltaLat / 2), 2) +
        cos(posBeforeLatRad) * cos(posNowLatRad) * pow(sin(deltaLon / 2), 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final double distance = earthRadiusKm * c; // Distancia en kilómetros
    return distance;
  }

  Future<void> updateTraveledDistance() async {
    if (latitudePosBefore != null && longitudePosBefore != null) {
      traveledDistanceDouble += calculateDistance(LatLng(latitudePosBefore!, longitudePosBefore!), LatLng(latitudePos!, longitudePos!));
      traveledDistance = '${traveledDistanceDouble.toStringAsFixed(2)} Km';
      print("traveled distance updated: $traveledDistance");
    }
  }

  // En vez de hacer un markers.clear(), markers.add() acceder a los marcadores
  // que hay guardados en markers y cambiar markers[x].logicalsize, imagesize
  void _onCameraIdle() async {
    await myMarkers.updateMarkersOnZoom(myPosition.zoom, 13);
    setState(() {});

    debugPrint('zoom ${myPosition.zoom}');
    beforeZoom = myPosition.zoom;
  }

  void updateCamera(LatLng newPosition) async {
    await _myController.animateCamera(CameraUpdate.newLatLng(newPosition));
  }

  void updateMapGesturesConfig() {
    zoomGesturesConfig = (zoomGesturesConfig) ? false : true;
    //rotateGesturesConfig = (rotateGesturesConfig) ? false : true;
    tiltGesturesConfig = (tiltGesturesConfig) ? false : true;
    scrollGesturesConfig = (scrollGesturesConfig) ? false : true;
    setState(() {});
  }

  void toggleBlockJoystick() {
    isBlocked = (isBlocked) ? false : true;
    setState(() {});
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const double appBarSpacing = 20;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: (channel != null) ? MyDrawer(controller: controller, characteristic: channel!,) : null,
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(41.37250958728433, 2.1921073916192357),
              zoom: 12.151926040649414,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              _controller.future.then((value) {
                _myController = value;
                value.setMapStyle(_mapStyleString);
              });
            },
            markers: myMarkers.getMarkers(), // markers,
            /*polylines: {
              Polyline(
                polylineId: const PolylineId("User/drone distance"),
                color: Colors.orange,
                width: 3,
                points: <LatLng> [_currentPosition!, const LatLng(41.37250958728433, 2.1921073916192357)],
              ),
            },*/
            onCameraMove: _positionAssign,
            onCameraIdle: _onCameraIdle,
            // Disable default UI controls
            myLocationEnabled: (_permisionGranted == PermissionStatus.granted) ? true : false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            trafficEnabled: false,
            //style: _mapStyleString,
            // Gesture controllers
            zoomGesturesEnabled: zoomGesturesConfig,
            rotateGesturesEnabled: rotateGesturesConfig,
            tiltGesturesEnabled: tiltGesturesConfig,
            scrollGesturesEnabled: scrollGesturesConfig,
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SvgPicture.asset(
              'assets/icons/DOWNBAR.svg',
              height: 90,
              width: double.infinity,
              fit: BoxFit.fill,
            ),
          ),
          Column(
            children: [
              Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xff000000).withAlpha(127),
                ),
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 10),
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: IconButton(
                              padding: EdgeInsets.all(0),
                              icon: Image.asset(
                                'assets/icons/TOOLBAR_WHITE.png',
                              ),
                              onPressed: () {
                                // do something
                                print('pressed');
                                _scaffoldKey.currentState?.openDrawer();
                                //Scaffold.of(context).openDrawer();
                              },
                            ),
                          ),
                          const SizedBox(width: appBarSpacing),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          AppbarBleWidget(
                            stateImage: batteryStateImage,
                            characteristic: batteryLife, 
                            horizontalPadding: appBarSpacing, 
                            childSeparation: 10,
                            unit: '%',
                            width: 50,
                          ),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          const SizedBox(width: appBarSpacing),
                          Container(child: bleStateImage),
                          const SizedBox(width: appBarSpacing),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          const SizedBox(width: appBarSpacing),
                          Container(child: wifiStateImage),
                          const SizedBox(width: appBarSpacing),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          AppbarBleWidget(
                            stateImage: packetLossImage,
                            characteristic: packetLoss, 
                            horizontalPadding: appBarSpacing, 
                            childSeparation: 10,
                            unit: '%',
                            width: 50,
                          ),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          AppbarBleWidget(
                            stateImage: speedImage,
                            characteristic: speed, 
                            horizontalPadding: appBarSpacing, 
                            childSeparation: 10,
                            unit: 'km/h',
                            width: 100,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: SizedBox(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 9, bottom: 40),
                              child: Joystick(
                                period: const Duration(milliseconds: 100),
                                block: isBlocked,
                                mode: JoystickMode.vertical,
                                stick: Container(
                                  width: 50,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/icons/JOY_BLUE.png',
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                base: SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: SvgPicture.asset('assets/icons/JOYSTICK_BASE.svg'),
                                ),
                                listener: (details) {
                                  if (inputLM != null) {
                                    // COMPROBAR QUE ESTO FUNCIONAAAAAAAA
                                    debugPrint('details.y: ${details.y}');
                                    List<int> bytes = utf8.encode((details.y * -1).toString());
                                    inputLM!.write(bytes, withoutResponse: true);
                                  }
                                  //debugPrint('details.x: ${details.x}');
                                  
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        child: Image.asset(
                                          'assets/icons/TRAVELED_DISTANCE.png',
                                          height: 24,
                                        ),
                                      ),
                                      const SizedBox(height: 0),
                                      Text(
                                        traveledDistance,
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                ),
                                SeparatorBar(height: 40),
                                DownbarBleWidget(
                                  image: 'assets/icons/GPS_ERROR.png', 
                                  imageHeight: 20, 
                                  characteristic: gpsError, 
                                  bottomPadding: 34, 
                                  childSeparation: 2, 
                                  unit: 'm',
                                  width: 100,
                                ),
                                /*Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        child: Image.asset(
                                          'assets/icons/GPS_ERROR.png',
                                          height: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '10 %',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 34),
                                    ],
                                  ),
                                ),*/
                                SeparatorBar(height: 40),
                                DownbarBleWidget(
                                  image: 'assets/icons/DATARATE_WHITE_.png', 
                                  imageHeight: 20, 
                                  characteristic: datarate, 
                                  bottomPadding: 15, 
                                  childSeparation: 4, 
                                  unit: 'Mbps',
                                  width: 100,
                                ),
                                /*Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        child: Image.asset(
                                          'assets/icons/BATTERY_CONSUM.png',
                                          width: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '80 %',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                ),*/
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: SizedBox(
                                height: 42,
                                width: 42,
                                child: IconButton(
                                  padding: EdgeInsets.all(5),
                                  icon: Image.asset(
                                    'assets/icons/WORLD_LOCK_ROUND_BLUE.png',
                                  ),
                                  onPressed: () {
                                    // do something
                                    updateMapGesturesConfig();
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: SizedBox(
                                height: 42,
                                width: 42,
                                child: IconButton(
                                  padding: EdgeInsets.all(5),
                                  icon: Image.asset(
                                    'assets/icons/CENTER_ROUND_BLUE.png',
                                  ),
                                  onPressed: () {
                                    // do something
                                    if (latitudePos != null && longitudePos != null) {
                                      updateCamera(
                                        LatLng(
                                          latitudePos!,
                                          longitudePos!,
                                        )
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: SizedBox(
                                height: 42,
                                width: 42,
                                child: IconButton(
                                  padding: EdgeInsets.all(5),
                                  icon: Image.asset(
                                    'assets/icons/JOY_LOCK_ROUND_BLUE.png',
                                  ),
                                  onPressed: () {
                                    // do something
                                    toggleBlockJoystick();
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: SizedBox(
                                height: 42,
                                width: 42,
                                child: IconButton(
                                  padding: EdgeInsets.all(5),
                                  icon: Image.asset(
                                    'assets/icons/START_DATA_GATHERING_BLUE.png',
                                  ),
                                  onPressed: () {
                                    // do something
                                    if (datagathering != null) {
                                      startDataGathering = !startDataGathering;
                                      List<int> bytes = utf8.encode((startDataGathering).toString());
                                      datagathering!.write(bytes, withoutResponse: true);
                                    }
                                  },
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(right: 9, bottom: 40),
                              child: Joystick(
                                period: const Duration(milliseconds: 100),
                                block: isBlocked,
                                mode: JoystickMode.vertical,
                                stick: Container(
                                  width: 50,
                                  height: 50,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  child: Image.asset(
                                    'assets/icons/JOY_BLUE.png',
                                    alignment: Alignment.center,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                base: SizedBox(
                                  width: 150,
                                  height: 150,
                                  child: SvgPicture.asset('assets/icons/JOYSTICK_BASE.svg'),
                                ),
                                listener: (details) {
                                  if (inputRM != null) {
                                    // COMPROBAR QUE ESTO FUNCIONAAAAAAAA
                                    debugPrint('details.y: ${details.y}');
                                    List<int> bytes = utf8.encode((details.y * -1).toString());
                                    inputRM!.write(bytes, withoutResponse: true);
                                  }
                                  //debugPrint('details.x: ${details.x}');
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> setColorOnConnectionChange() async {
    _wifiSubscription = _connectivity.onConnectivityChanged.listen((value) async {
      bool isActive = ConnectivityChecker.updateConnectionStatus(value);
      if (isActive) {
        wifiStateImage = await icons.searchByNameAsync('WIFI_WHITE');
      } else {
        wifiStateImage = await icons.searchByNameAsync('WIFI_RED');
        if(mounted) {
          Dialogs.conectionLostDialog(context);
        }
      }
      /*wifiStateImage =
          (isActive)
              ? await icons.searchByNameAsync('WIFI_GREEN')
              : await icons.searchByNameAsync('WIFI_RED');*/
      setState(() {});
    });
  }

  Future conectionLostDialog() => showDialog(
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
          onPressed: sumbit, 
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

  Future conectionBLELostDialog() => showDialog(
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
          onPressed: sumbit, 
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

  void sumbit() {
    Navigator.of(context).pop();
  }
}

class BlobMarker extends StatelessWidget {
  const BlobMarker({super.key});

  final double width = 50;
  final double height = 50;
  final Color markerColor = const Color.fromARGB(255, 117, 27, 27);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(color: markerColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text('Hello World', maxLines: 1),
        ),
      ],
    );
  }
}

class SeparatorBar extends StatelessWidget {
  const SeparatorBar({super.key, required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 1,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white,
            ),
          ),
          SizedBox(height: height),
        ],
      ),
    );
  }
}

class AppbarBleWidget extends StatefulWidget {
  final Image? stateImage;
  final BluetoothCharacteristic? characteristic;
  final double horizontalPadding;
  final double childSeparation;
  final String unit;
  final double width;

  const AppbarBleWidget({Key? key, required this.width, required this.stateImage, required this.characteristic, required this.horizontalPadding, required this.childSeparation, required this.unit}) : super(key: key);

  @override
  State<AppbarBleWidget> createState() => _AppbarBleWidget();
}

class _AppbarBleWidget extends  State<AppbarBleWidget> {

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
          SizedBox(width: widget.horizontalPadding),
          Container(child: widget.stateImage),
          SizedBox(width: widget.childSeparation),
          (widget.characteristic != null) ? 
          CharacteristicWidget(
            characteristic: widget.characteristic, 
            unit: widget.unit,
            width: widget.width,
          ) : SizedBox(
            width: 60,
            child: Text(
              'ERROR',
              style: TextStyle(
                color: Colors.white
              ),
            ),
          ),
          SizedBox(width: widget.horizontalPadding),
      ],
    );
  }
}

class DownbarBleWidget extends StatefulWidget {
  final String image;
  final double imageHeight;
  final BluetoothCharacteristic? characteristic;
  final double bottomPadding;
  final double childSeparation;
  final String unit;
  final double width;

  const DownbarBleWidget({Key? key, required this.width, required this.image, required this.imageHeight, required this.characteristic, required this.bottomPadding, required this.childSeparation,required this.unit}) : super(key: key);

  @override
  State<DownbarBleWidget> createState() => _DownbarBleWidget();
}

class _DownbarBleWidget extends State<DownbarBleWidget> {

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            child: Image.asset(
              widget.image,
              height: widget.imageHeight,
            ),
          ),
          SizedBox(height: widget.childSeparation),
          (widget.characteristic != null) ? 
          CharacteristicWidget(
            characteristic: widget.characteristic, 
            unit: widget.unit,
            width: widget.width,
          ) : SizedBox(
            width: 60,
            child: Text(
              'ERROR',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: Colors.white
              ),
            )
          ),
          SizedBox(height: widget.bottomPadding),
        ],
      ),
    );
  }
}

class MyDrawer extends StatefulWidget {
  MyDrawer({super.key, required  this.controller, required this.characteristic}); 

  TextEditingController controller;
  BluetoothCharacteristic characteristic;

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 200,
      backgroundColor: Color(0xff383838),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
        topRight: Radius.circular(0),
        bottomRight: Radius.circular(0)),
      ),
      child: ListView(
        children: [
          Padding(
            padding: EdgeInsets.all(15),
            child: SizedBox(
              height: 42,
              width: 42,
              child: IconButton(
                icon: Image.asset('assets/icons/TOOLBAR_WHITE.png'),
                onPressed: Navigator.of(context).pop,
                padding: EdgeInsets.all(15),
                alignment: Alignment.topLeft,
              )
            )
          ),
          ListTile(
            leading: Image.asset('assets/icons/BLE_WHITE.png', height: 15),
            title: Text('Scan',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            contentPadding: EdgeInsets.all(0),
            horizontalTitleGap: 0,
            onTap: () {
              Navigator.of(context).popUntil((route) => route.settings.name == '/');
              //Navigator.pop(context);
            } 
          ),
          Padding(
            padding: EdgeInsets.only(left: 30, right: 20),
            child: Container(
              width: 10,
              height: 1,
              color: Colors.grey,
            ),
          ),
          ListTile(
            leading: Image.asset('assets/icons/RF_WHITE.png', height: 15),
            title: Text('Canal',
              style: TextStyle(fontSize: 13, color: Colors.white),
            ),
            contentPadding: EdgeInsets.all(0),
            horizontalTitleGap: 0,
            onTap: () async {
              Dialogs.changeChannelDialog(context, widget.controller, widget.characteristic);
            },
          ),
          Padding(
            padding: EdgeInsets.only(left: 30, right: 20),
            child: Container(
              width: 10,
              height: 1,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}*/