import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'EBiCS',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:// MyHomePage(title: 'EBiCS Control Center'),
        Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              child: PageViewDemo(),
            ),
        ),
      );
}



class PageViewDemo extends StatefulWidget {
        @override
        _PageViewDemoState createState() => _PageViewDemoState();
        }

class _PageViewDemoState extends State<PageViewDemo> {

        PageController _controller = PageController(
        initialPage: 0,
        );

        @override
        void dispose() {
        _controller.dispose();
        super.dispose();
        }

        @override
        Widget build(BuildContext context) {
          return PageView(
            controller: _controller,
            children: [

              MyHomePage(title: 'EBiCS Control Center'),
              //MyPage1Widget(),
        ],
        );
        }
}

class MyPage1Widget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: [
            MyBox(darkGreen, height: 50),
          ],
        ),
        Row(
          children: [
            MyBox(lightGreen),
            MyBox(lightGreen),
          ],
        ),
        MyGauge(10.0),
        Row(
          children: [
            MyBox(lightGreen, height: 200),
            MyBox(lightGreen, height: 200),
          ],
        ),
      ],
    );
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  final FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();
  final Map<Guid, List<int>> readValues = new Map<Guid, List<int>>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _writeController = TextEditingController();
  final String SERVICE_UUID = "0000ffe0-0000-1000-8000-00805f9b34fb";
  final String CHARACTERISTIC_UUID = "0000ffe1-0000-1000-8000-00805f9b34fb";
  final String TARGET_DEVICE_NAME = "EBiCS";
  //BluetoothDevice targetDevice;
  //BluetoothCharacteristic targetCharacteristic;
  BluetoothDevice _connectedDevice;
  BluetoothDevice targetDevice;
  BluetoothCharacteristic EBiCS_characteristic;
  List<BluetoothService> _services;
  static int Speed_value = 30;
  static int viewNumber = 0;

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
          widget.devicesList.add(device);
      });
    }
  }

  @override
  void initState() {
    super.initState();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        if (result.device.name == TARGET_DEVICE_NAME) {
          _addDeviceTolist(result.device);
          targetDevice = result.device;
          connectToDevice();
           }
      }
    });
    widget.flutterBlue.startScan();
  }
  connectToDevice() async {

    widget.flutterBlue.stopScan();
    try {
      await targetDevice.connect();
    } catch (e) {
      if (e.code != 'already_connected') {
        throw e;
      }
    } finally {
      _services = await targetDevice.discoverServices();

    }
    activateNotify();
    setState(() {
      _connectedDevice = targetDevice;
      viewNumber = 1;
    });
    print('DEVICE CONNECTED');

  }

  activateNotify() async {

    for (BluetoothService service in _services) {
      if (service.uuid.toString() == SERVICE_UUID) {
        for (BluetoothCharacteristic characteristic in service.characteristics) {
        await characteristic.setNotifyValue(true);
        characteristic.value.listen((value) {
          print('aktualisierte Nachricht!:' + value.toString());
          setState(() {
            widget.readValues[characteristic.uuid] = value;
            Speed_value = value[0];

          });

        });
      }
      }
    }
  }
  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  Text(device.name == '' ? '(unknown device)' : device.name
                  ),
                  Text(device.id.toString()
                  ),
                ],
              ),
            ),
            FlatButton(
              color: Colors.blue,
              child: Text(
                'Connect',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                widget.flutterBlue.stopScan();
                try {
                  await device.connect();
                } catch (e) {
                  if (e.code != 'already_connected') {
                    throw e;
                  }
                } finally {
                  _services = await device.discoverServices();
                }
                setState(() {
                  _connectedDevice = device;
                });
              },
            ),
          ],
        ),
        ),
      );
    }
    containers.add(
        Container(
          height: 50,
          child: Row(
              children: <Widget>[
                FlatButton(
                  color: Colors.blue,
                  child: Text(
                    'Detail View',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {

                    setState(() {
                      viewNumber = 1;
                    });

                  }
                  ),

              ],
          ),
        ));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  List<ButtonTheme> _buildReadWriteNotifyButton(
      BluetoothCharacteristic characteristic) {
    List<ButtonTheme> buttons = new List<ButtonTheme>();

    if (characteristic.properties.read) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              color: Colors.blue,
              child: Text('READ', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                var sub = characteristic.value.listen((value) {
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                });
                await characteristic.read();
                sub.cancel();
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.write) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('WRITE', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Write"),
                        content: Row(
                          children: <Widget>[
                            Expanded(
                              child: TextField(
                                controller: _writeController,
                              ),
                            ),
                          ],
                        ),
                        actions: <Widget>[
                          FlatButton(
                            child: Text("Send"),
                            onPressed: () {
                              characteristic.write(
                                  utf8.encode(_writeController.value.text));
                              Navigator.pop(context);
                            },
                          ),
                          FlatButton(
                            child: Text("Cancel"),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        ),
      );
    }
    if (characteristic.properties.notify) {
      buttons.add(
        ButtonTheme(
          minWidth: 10,
          height: 20,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RaisedButton(
              child: Text('NOTIFY', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                /*characteristic.value.listen((value) {
                  widget.readValues[characteristic.uuid] = value;
                });*/
                await characteristic.setNotifyValue(true);
                characteristic.value.listen((value) {
                  print('aktualisierte Nachricht!:' + value.toString());
                  setState(() {
                    widget.readValues[characteristic.uuid] = value;
                  });
                  //widget.readValues[characteristic.uuid] = value;
                });
                showAlertDialog(context);
              },
            ),
          ),
        ),
      );
    }

    return buttons;
  }

  ListView _buildConnectDeviceView() {
    List<Container> containers = new List<Container>();

    for (BluetoothService service in _services) {
      if (service.uuid.toString() == SERVICE_UUID) {
      List<Widget> characteristicsWidget = new List<Widget>();
      print('service uuid!:' + service.uuid.toString());
      //showAlertDialog(context);
      for (BluetoothCharacteristic characteristic in service.characteristics) {
          characteristicsWidget.add(
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(characteristic.uuid.toString()
                        ,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: <Widget>[
                    ..._buildReadWriteNotifyButton(characteristic),
                  ],
                ),
                Row(
                  children: <Widget>[
                    Text('aktueller Wert: ' + widget.readValues[characteristic.uuid].toString()
                    ),
                  ],
                ),

                Divider(),

              ],
            ),
          ),
        );
      }
      containers.add(
        Container(
          child: characteristicsWidget[0],
        ),

      );

    }
  }
    containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              FlatButton(
                  color: Colors.blue,
                  child: Text(
                    'Device View',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    print('Button 1 pressed!');
                    setState(() {
                      viewNumber = 0;
                    });

                  }
              ),
              FlatButton(
                  color: Colors.blue,
                  child: Text(
                    'View 3',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    print('Button 2 pressed!');
                    setState(() {
                      viewNumber = 2;
                    });

                  }
              ),
            ],
          ),
        ));
    containers.add(
        Container(
          height: 300,
          child: MyGauge(Speed_value.toDouble())
          ,        ));
    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  ListView _ThirdView() {
    List<Container> containers = new List<Container>();


    containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              FlatButton(
                  color: Colors.blue,
                  child: Text(
                    'Device View',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    print('Button 1 pressed!');
                    setState(() {
                      viewNumber = 0;
                    });

                  }
              ),
              FlatButton(
                  color: Colors.blue,
                  child: Text(
                    'Detail View',
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    print('Button 2 pressed!');
                    setState(() {
                      viewNumber = 1;
                    });

                  }
              ),
            ],
          ),
        ));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }
  
  ListView _buildView() {
    /*if (_connectedDevice != null) {
      return _buildConnectDeviceView();
    }
    return _buildListViewOfDevices();*/
    switch(viewNumber) {
      case 0: {
        return _buildListViewOfDevices();
      }
      break;

      case 1: {
        return _buildConnectDeviceView();
      }
      break;

      case 2: {
        return _ThirdView();
      }
      break;
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title,
            textAlign: TextAlign.center,
          ),
        ),
        body: _buildView(),
      );
}

showAlertDialog(BuildContext context) {
  // set up the button
  Widget okButton = FlatButton(
    child: Text("OK"),
    onPressed: () { },
  );
  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Debug Meldung"),
    content: Text("Ich bin da :-)"),
    actions: [
      okButton,
    ],
  );
  // show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

const lightBlue = Color(0xff00bbff);
const mediumBlue = Color(0xff00a2fc);
const darkBlue = Color(0xff0075c9);

final lightGreen = Colors.green.shade300;
final mediumGreen = Colors.green.shade600;
final darkGreen = Colors.green.shade900;

final lightRed = Colors.red.shade300;
final mediumRed = Colors.red.shade600;
final darkRed = Colors.red.shade900;

class MyBox extends StatelessWidget {
  final Color color;
  final double height;
  final String text;

  MyBox(this.color, {this.height, this.text});

  @override
  Widget build(BuildContext context) {
     return Expanded(
      child: Container(
        margin: EdgeInsets.all(10),
        color: color,
        height: (height == null) ? 150 : height,
        child: (text == null)
            ? null
            : Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 50,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}




class MyGauge extends StatelessWidget {
final double zeigerwert;

  MyGauge(this.zeigerwert);

  @override
  Widget build(BuildContext context) {
    return _getMarkerPointerExample(zeigerwert);
  }

  /// Returns the marker pointer gauge
  SfRadialGauge _getMarkerPointerExample(double paramvalue) {
    return SfRadialGauge(
      enableLoadingAnimation: true,
      axes: <RadialAxis>[
        RadialAxis(
            interval: 10,
            axisLineStyle: AxisLineStyle(
              thickness: 0.03,
              thicknessUnit: GaugeSizeUnit.factor,
            ),
            showTicks: false,
            axisLabelStyle: GaugeTextStyle(
              fontSize: 14,
            ),
            labelOffset: 25,
            radiusFactor: 0.95,
            pointers: <GaugePointer>[
              NeedlePointer(
                  needleLength: 0.7,
                  value: paramvalue,
                  lengthUnit: GaugeSizeUnit.factor,
                  needleColor: _needleColor,
                  needleStartWidth: 0,
                  needleEndWidth: 4,
                  knobStyle: KnobStyle(
                      sizeUnit: GaugeSizeUnit.factor,
                      color: _needleColor,
                      knobRadius: 0.05)),
            ],
            annotations: <GaugeAnnotation>[
              GaugeAnnotation(
                  angle: 270,
                  positionFactor: 0.5,
                  widget: Container(
                      child: Text('km/h',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)))),

            ]
        )
           ],
    );
  }

final Color _needleColor = const Color(0xFFC06C84);

}