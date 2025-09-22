/*

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:demo_app/icons/myicons.dart';
import 'package:demo_app/markers/mymarkers.dart';
import 'package:demo_app/ble/ble_info.dart';
import 'package:demo_app/ble/Characteristics_widget.dart';
import 'package:demo_app/connectivity/check_connectivity_class.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ControllerPage extends StatefulWidget {
  final BluetoothDevice device;

  const ControllerPage({super.key, required this.device});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
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
  MyCustomMarkers myMarkers = MyCustomMarkers(size: 10);

  // Google Maps
  late final GoogleMapController _myController;
  final Completer<GoogleMapController> _controller = Completer();
    Set<Marker> markers = {};

  // Icons
  final MyIcons icons = MyIcons(width: null, height: 10);

  // BLE
  final MyBleInfo myBleInfo = MyBleInfo();
  late StreamSubscription<BluetoothConnectionState> _connectionStateSubscription;
  List<BluetoothService> _services = [];

  // Characteristics
  BluetoothCharacteristic? batteryLife;
  BluetoothCharacteristic? packetLoss;
  BluetoothCharacteristic? speed;
  BluetoothCharacteristic? gpsError;
  BluetoothCharacteristic? batteryDrain;
  BluetoothCharacteristic? latitude;
  BluetoothCharacteristic? longitude;
  BluetoothCharacteristic? rotation;

  initMarkers() async {
    myMarkers.addPositionMarker(
      positionMarker: Marker(
        markerId: const MarkerId("USV"),
        position: const LatLng(37.43296265331129, -122.08832357078792),
        icon: await BitmapDescriptor.asset(
          ImageConfiguration(size: Size(24, 24)), 
          'assets/icons/USV_POSITION.png'
        ),
      )
    );
    await myMarkers.addMarker(
      depth: 14,
      position: LatLng(37.43296265331129, -122.08832357078792),
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
    
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription = widget.device.connectionState.listen((state) {
      if (state == BluetoothConnectionState.disconnected) {
        bleStateImage = icons.searchByName('BLE_RED');
        print("${widget.device.disconnectReason?.code} ${widget.device.disconnectReason?.description}");
      }
      if (state == BluetoothConnectionState.connected) {
        bleStateImage = icons.searchByName('BLE_WHITE');
        print("RECONECTED AGAIN");
      }
    });

    connectToDevice();
    initMarkers();
    initImages();
    setColorOnConnectionChange();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    rootBundle.loadString('assets/map/map_style.json').then((string) {
      _mapStyleString = string;
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
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
    } catch (e) {
      print('Proces characteristics failed: $e');
    }
  }

  void assignBleCharacteristics(MyCharacteristics myCharacteristic) {
    switch (myCharacteristic.characteristicName) {
      case 'batteryLife':
        batteryLife = myCharacteristic.c;
        break;
      case 'packetLoss':
        packetLoss = myCharacteristic.c;
        break;
      case 'speed':
        speed = myCharacteristic.c;
        break;
      case 'gpsError':
        gpsError = myCharacteristic.c;
        break;
      case 'batteryDrain':
        batteryDrain = myCharacteristic.c;
        break;
      case 'latitude':
        latitude = myCharacteristic.c;
        break;
      case 'longitude':
        longitude = myCharacteristic.c;
        break;
      case 'rotation':
        rotation = myCharacteristic.c;
        break;
    }
  }

  void _positionAssign(CameraPosition position) {
    myPosition = position;
    //debugPrint('zoom 1: ${position.zoom}');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.43296265331129, -122.08832357078792),
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
            onCameraMove: _positionAssign,
            onCameraIdle: _onCameraIdle,
            // Disable default UI controls
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
                                updateCamera(
                                  LatLng(
                                    37.43296265331129,
                                    -122.08832357078792,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          AppbarBleWidget(
                            stateImage: batteryStateImage,
                            characteristic: batteryLife, 
                            horizontalPadding: 10, 
                            childSeparation: 10,
                            unit: '%'
                          ),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Container(child: bleStateImage),
                          const SizedBox(width: 10),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Container(child: wifiStateImage),
                          const SizedBox(width: 10),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          AppbarBleWidget(
                            stateImage: packetLossImage,
                            characteristic: packetLoss, 
                            horizontalPadding: 10, 
                            childSeparation: 10,
                            unit: '%'
                          ),
                          Container(
                            height: 10,
                            width: 1,
                            decoration: BoxDecoration(color: Colors.white),
                          ),
                          AppbarBleWidget(
                            stateImage: speedImage,
                            characteristic: speed, 
                            horizontalPadding: 10, 
                            childSeparation: 10,
                            unit: 'km / h'
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
                                  //debugPrint('details.x: ${details.x}');
                                  //debugPrint('details.y: ${details.y}');
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
                                        '2 Km',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 15),
                                    ],
                                  ),
                                ),
                                SeparatorBar(height: 40),
                                Expanded(
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
                                ),
                                SeparatorBar(height: 55),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        child: Image.asset(
                                          'assets/icons/BLOB_DISTANCE.png',
                                          width: 20,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '~ 1 m',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 40),
                                    ],
                                  ),
                                ),
                                SeparatorBar(height: 55),
                                DownbarBleWidget(
                                  image: 'assets/icons/GPS_ERROR.png', 
                                  imageHeight: 20, 
                                  characteristic: gpsError, 
                                  bottomPadding: 34, 
                                  childSeparation: 2, 
                                  unit: '%'
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
                                Expanded(
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
                                ),
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
                                    updateCamera(
                                      LatLng(
                                        37.43296265331129,
                                        -122.08832357078792,
                                      ),
                                    );
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
                                    'assets/icons/EYE_LOCK_ROUND_BLUE.png',
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
                              padding: EdgeInsets.only(right: 9, bottom: 40),
                              child: Joystick(
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
                                  //debugPrint('details.x: ${details.x}');
                                  //debugPrint('details.y: ${details.y}');
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
    _connectivity.onConnectivityChanged.listen((value) async {
      bool isActive = ConnectivityChecker.updateConnectionStatus(value);
      if (isActive) {
        wifiStateImage = await icons.searchByNameAsync('WIFI_GREEN');
      } else {
        wifiStateImage = await icons.searchByNameAsync('WIFI_RED');
        conectionLostDialog();
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

  const AppbarBleWidget({Key? key, required this.stateImage, required this.characteristic, required this.horizontalPadding, required this.childSeparation, required this.unit}) : super(key: key);

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
            unit: widget.unit
          ) : SizedBox(width: 40),
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

  const DownbarBleWidget({Key? key, required this.image, required this.imageHeight, required this.characteristic, required this.bottomPadding, required this.childSeparation,required this.unit}) : super(key: key);

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
            unit: widget.unit
          ) : SizedBox(width: 40),
          SizedBox(height: widget.bottomPadding),
        ],
      ),
    );
  }
}
*/
