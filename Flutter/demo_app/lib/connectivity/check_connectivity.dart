// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:demo_app/connectivity/check_connectivity_class.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MyConnectivity extends StatefulWidget {
  const MyConnectivity({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyConnectivity> createState() => _MyConnectivityState();
}

class _MyConnectivityState extends State<MyConnectivity> {
  Color myColor = Colors.red;
  final Connectivity _connectivity = Connectivity();

  @override
  void initState() {
    super.initState();
    setColor();
  }

  @override
  void dispose() {

    super.dispose();
  }

  Future<void> setColor () async{
    _connectivity.onConnectivityChanged.listen((value) {
      bool isActive = ConnectivityChecker.updateConnectionStatus(value);
      whichColor(isActive);
      setState(() {});
    });
  }

  void whichColor(bool isActive) {
    if (isActive) {
      myColor = Colors.green;
    } else {
      myColor = Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connectivity Plus Example'),
        elevation: 4,
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Spacer(flex: 2),
          Text(
            'Active connection types:',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const Spacer(),
          Container(
            height: 50,
            width: 50,
            color: myColor,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}