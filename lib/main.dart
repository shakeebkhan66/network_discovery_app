import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_nsd/flutter_nsd.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {


  final flutterNsd = FlutterNsd();
  final services = <NsdServiceInfo>[];
  bool initialStart = true;
  bool _scanning = false;

  _MyAppState();

  @override
  void initState() {
    super.initState();

    // Try one restart if initial start fails, which happens on hot-restart of
    // the flutter app.
    flutterNsd.stream.listen(
          (NsdServiceInfo service) {
        setState(() {
          services.add(service);
        });
      },
      onError: (e) async {
        if (e is NsdError) {
          if (e.errorCode == NsdErrorCode.startDiscoveryFailed &&
              initialStart) {
            await stopDiscovery();
          } else if (e.errorCode == NsdErrorCode.discoveryStopped &&
              initialStart) {
            initialStart = false;
            await startDiscovery();
          }
        }
      },
    );
  }

  Future<void> startDiscovery() async {
    if (_scanning) return;

    setState(() {
      services.clear();
      _scanning = true;
    });
    await flutterNsd.discoverServices('_http._tcp.');
  }

  Future<void> stopDiscovery() async {
    if (!_scanning) return;

    setState(() {
      services.clear();
      _scanning = false;
    });
    flutterNsd.stopDiscovery();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.amber,
          centerTitle: true,
          title: const Text(
            'Network Services Discovery',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 40.0),
          child: Column(
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  MaterialButton(
                    color: Colors.green,
                    child: Text(
                        'Start',
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: () async => startDiscovery(),
                  ),
                  MaterialButton(
                    color: Colors.red,
                    child: Text('Stop',  style: TextStyle(color: Colors.white),),
                    onPressed: () async => stopDiscovery(),
                  ),
                ],
              ),
              SizedBox(height: 40),
              Expanded(
                child: _buildMainWidget(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainWidget(BuildContext context) {
    if (services.isEmpty && _scanning) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else if (services.isEmpty && !_scanning) {
      return const SizedBox.shrink();
    } else {
      return ListView.builder(
        itemBuilder: (context, index) => Card(
          margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4.0),
          color: Color(0xffFFF8DC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13.0),
          ),
          child: ListTile(
            title: Text(
                services[index].name ?? 'Invalid service name',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        itemCount: services.length,
      );
    }
  }
}
