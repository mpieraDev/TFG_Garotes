import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    return Scaffold(
      body: GestureDetector(
        onTap: () async {
          await Future.delayed(const Duration(seconds: 1));
          Navigator.pushNamed(context, '/ble_scanner');
        },
        child: SizedBox.expand(
          child: Container(
            decoration: BoxDecoration(color: Color.fromARGB(255, 235, 235, 235)),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/SPASCAT_LOGO_BLUE.svg',
                height: 150,
                width: 150,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
