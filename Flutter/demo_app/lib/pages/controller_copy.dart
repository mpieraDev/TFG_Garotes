import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:flutter_joystick/flutter_joystick.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:widget_to_marker/widget_to_marker.dart';
import 'package:demo_app/icons/myicons.dart';
import 'package:demo_app/connectivity/check_connectivity_class.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  late String _mapStyleString;
  late double beforeZoom;
  late CameraPosition myPosition;

  late Image? bleStateImage;
  late Image? wifiStateImage;
  late Image? batteryStateImage;
  late Image? speedImage;
  late Image? packetLossImage;

  final Connectivity _connectivity = Connectivity();

  final Completer<GoogleMapController> _controller = Completer();
  final MyIcons icons = MyIcons(width: null, height: 10);
  Set<Marker> markers = {};

  initMarkers() async {
    markers = {};

    markers.add(
      Marker(
        markerId: const MarkerId("1"),
        position: const LatLng(37.43296265331129, -122.08832357078792),
        icon: await const CountWidget(count: 1).toBitmapDescriptor(
          logicalSize: const Size(100, 100),
          imageSize: const Size(300, 300),
        ),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId("2"),
        position: const LatLng(37.33296265331129, -122.08832357078792),
        icon: await const BlobMarker().toBitmapDescriptor(
          logicalSize: const Size(100, 100),
          imageSize: const Size(300, 300),
        ),
      ),
    );
    setState(() {});
  }

  void initImages() {
    bleStateImage = icons.searchByName('BLE');
    wifiStateImage = icons.searchByName('WIFI_GREEN');
    batteryStateImage = icons.searchByName('BATTERY_GREEN');
    speedImage = icons.searchByName('SPEED');
    packetLossImage = icons.searchByName('PACKETLOSS');
  }

  @override
  void initState() {
    //runServerInIsolate();
    beforeZoom = 12.151926040649414;
    initMarkers();
    initImages();
    setColorOnConnectionChange();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    rootBundle.loadString('assets/map/map_style.json').then((string) {
      _mapStyleString = string;
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  void _positionAssign(CameraPosition position) {
    myPosition = position;
    //debugPrint('zoom 1: ${position.zoom}');
  }

  // En vez de hacer un markers.clear(), markers.add() acceder a los marcadores
  // que hay guardados en markers y cambiar markers[x].logicalsize, imagesize
  void _onCameraIdle() async {
    if (beforeZoom != myPosition.zoom) {
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId("2"),
          position: const LatLng(37.33296265331129, -122.08832357078792),
          icon: await const BlobMarker().toBitmapDescriptor(
            logicalSize: Size(10 * myPosition.zoom, 10 * myPosition.zoom),
            imageSize: Size(10 * myPosition.zoom, 10 * myPosition.zoom),
          ),
        ),
      );
      debugPrint('zoom: ${myPosition.zoom}');
      setState(() {});
    }

    //debugPrint('zoom ${position.zoom}');
    beforeZoom = myPosition.zoom;
  }

  void _onCameraIdle2() async {
    if (beforeZoom != myPosition.zoom) {
      for (Marker marker in markers) {
        BitmapDescriptor icon = marker.icon;
      }
    }

    //debugPrint('zoom ${position.zoom}');
    beforeZoom = myPosition.zoom;
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
                value.setMapStyle(_mapStyleString);
              });
            },
            markers: markers,
            onCameraMove: _positionAssign,
            onCameraIdle: _onCameraIdle,
            // Disable default UI controls
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            trafficEnabled: false,
            //style: _mapStyleString,
          ),
          Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(color: Color(0xff000000).withAlpha(127)),
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
                        height: 20,
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.all(0),
                          icon: Image.asset(
                            'assets/icons/TOOLBAR_ROUND_BLACK.png',
                          ),
                          onPressed: () {
                            // do something
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        height: 20,
                        width: 1,
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Container(child: batteryStateImage),
                      const SizedBox(width: 10),
                      Text('80 %', style: TextStyle(color: Colors.white)),
                      const SizedBox(width: 10),
                      Container(
                        height: 20,
                        width: 1,
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Container(child: bleStateImage),
                      const SizedBox(width: 10),
                      Container(
                        height: 20,
                        width: 1,
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Container(child: wifiStateImage),
                      const SizedBox(width: 10),
                      Container(
                        height: 20,
                        width: 1,
                        decoration: BoxDecoration(color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Container(child: speedImage),
                      const SizedBox(width: 10),
                      Text('2km / h', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Joystick(
              block: true,
              stick: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(
                  'assets/icons/joy_ora.png', 
                  alignment: Alignment.center,
                  width: double.infinity, 
                  height: double.infinity, 
                  fit: BoxFit.contain, 
                ),
              ),
              base: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Color(0xffFFFFFF).withAlpha(125),
                  shape: BoxShape.circle,
                ),
              ),
              listener: (details) {
                //debugPrint('details.x: ${details.x}');
                //debugPrint('details.y: ${details.y}');
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: Joystick(
              block: true,
              stick: Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: Image.asset(
                  'assets/icons/joy_ora.png', 
                  alignment: Alignment.center,
                  width: double.infinity, 
                  height: double.infinity, 
                  fit: BoxFit.contain, 
                ),
              ),
              base: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Color(0xffFFFFFF).withAlpha(125),
                  shape: BoxShape.circle,
                ),
              ),
              listener: (details) {
                //debugPrint('details.x: ${details.x}');
                //debugPrint('details.y: ${details.y}');
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> setColorOnConnectionChange () async{
    _connectivity.onConnectivityChanged.listen((value) async {
      bool isActive = ConnectivityChecker.updateConnectionStatus(value);
      wifiStateImage = (isActive) ? await icons.searchByNameAsync('WIFI_GREEN') : await icons.searchByNameAsync('WIFI_RED');
      setState(() {});
    });
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

class CountWidget extends StatelessWidget {
  const CountWidget({super.key, required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(child: Text('$count'));
  }
}

class MyCustomMarker {
  MyCustomMarker({required this.marker, required this.look});

  Marker marker;
  BlobMarker look;
}
