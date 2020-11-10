import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

import 'LEV_Pages.dart';


void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'EBiCS',
    theme: ThemeData(
      primarySwatch: Colors.lightBlue,
    ),
    home: MyHomePage(title: 'v.01'),

  );
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
  static int Speed_value = 1;
  static int Trip_value = 0;
  static int Voltage_value = 0;
  static int Power_value = 0;
  static int Assist_Level = 3;
  static int Regen_Level = 4;
  static int viewNumber = 2;
  static Color BT_color = Colors.grey;
  static Color OnOff_color = Colors.grey;
  static bool OnOff = false;

  BluetoothService UART_service;
  BluetoothCharacteristic UART_characteristic;
  controllerState test = new controllerState(0);


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
        _addDeviceTolist(result.device);
        if (result.device.name == TARGET_DEVICE_NAME) {
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
      BT_color = Colors.green[900];
    });
    print('DEVICE CONNECTED');

  }

  activateNotify() async {
     for (BluetoothService service in _services) {

      if (service.uuid.toString() == SERVICE_UUID) {
        UART_service = service;
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          if (characteristic.uuid.toString() == CHARACTERISTIC_UUID) {
            UART_characteristic = characteristic;
            await characteristic.setNotifyValue(true);
            characteristic.value.listen((value) {
              //print('aktualisierte Nachricht!:' + value.toString());
              setState(() {
                widget.readValues[characteristic.uuid] = value;
                Speed_value = value[0];
                Trip_value = value[1];
                Voltage_value = value[2];
                Power_value = value[3];
                test.Speed = value[4];;
                print('Hallo Welt ' + test.Speed.toString());
                UART_characteristic.write(value);
              });
            });
          }
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
                  //print('aktualisierte Nachricht!:' + value.toString());
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
        //showAlertDialog(context);
        for (BluetoothCharacteristic characteristic in service.characteristics) {
          characteristicsWidget.add(
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                children: <Widget>[


                  Row(
                    children: <Widget>[
                      Text('Bytes received:' + widget.readValues[characteristic.uuid].toString()
                      ),
                    ],
                  ),

                  Divider(),

                ],
              ),
            ),
          );
        }



      }

    }

    containers.add(
        Container(
          height: 300,
          child: MyGauge(Speed_value.toDouble())
          ,
        ));


    containers.add(
        Container(
            child: Row(
              children: <Widget>[
                MyBox(Colors.white, height: 22, text: "Trip"),
                MyBox(Colors.white, height: 22, text: "Voltage"),
                MyBox(Colors.white, height: 22, text: "Power"),
              ],
            )

        )
    );
    containers.add(
        Container(
            child: Row(
              children: <Widget>[
                MyBox(mediumBlue, height: 30, fontColor: Colors.white, text: Trip_value.toString() + " km"),
                MyBox(mediumBlue, height: 30, fontColor: Colors.white, text: Voltage_value.toString() + " V"),
                MyBox(mediumBlue, height: 30, fontColor: Colors.white, text: Power_value.toString() + " W"),
              ],
            )

        )
    );


    containers.add(
        Container(
            child: Row(
              children: <Widget>[
                MyBox(Colors.white, height: 22, text: ""),
                MyBox(Colors.white, height: 22, text: "Regen Level"),
                MyBox(Colors.white, height: 22, text: ""),
              ],
            )

        )
    );

    containers.add(
        Container(
            child: Row(
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    if (Regen_Level>0) {
                      setState(() {
                        Regen_Level--;
                        UART_characteristic.write(
                            utf8.encode(Regen_Level.toString()));
                      });
                    }
                    },
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      //Text("Label", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 70),
                      Icon(Icons.arrow_circle_down_rounded, color: Colors.white),
                    ],
                  ),
                ),
                MyBox(mediumBlue, height: 70, fontSize: 48, fontColor: Colors.white, text: Regen_Level.toString()),
                RaisedButton(
                  onPressed: () {
                    if (Regen_Level<7) {
                      setState(() {
                        Regen_Level++;
                        UART_characteristic.write(
                            utf8.encode(Regen_Level.toString()));
                      });
                    }
                    },
                  padding: const EdgeInsets.symmetric(horizontal:12),
                  color: darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      //Text("Label", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 70),
                      Icon(Icons.arrow_circle_up_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ],
            )
        )
    );

    containers.add(
        Container(
            child: Row(
              children: <Widget>[
                MyBox(Colors.white, height: 22, text: ""),
                MyBox(Colors.white, height: 22, text: "Assist Level"),
                MyBox(Colors.white, height: 22, text: ""),
              ],
            )

        )
    );

    containers.add(
        Container(
            child: Row(
              children: <Widget>[
                RaisedButton(
                  onPressed: () {
                    if (Assist_Level>0) {
                      setState(() {
                        Assist_Level--;
                        UART_characteristic.write(
                            utf8.encode(Assist_Level.toString()));
                      });
                    }
                    },
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  color: darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      //Text("Label", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 70),
                      Icon(Icons.arrow_circle_down_rounded, color: Colors.white),
                    ],
                  ),
                ),
                MyBox(mediumBlue, height: 70, fontSize: 48, fontColor: Colors.white, text: Assist_Level.toString()),
                RaisedButton(
                  onPressed: () {
                    if (Assist_Level<7) {
                      setState(() {
                        Assist_Level++;
                        UART_characteristic.write(
                            utf8.encode(Assist_Level.toString()));
                      });
                    }
                    },
                  padding: const EdgeInsets.symmetric(horizontal:12),
                  color: darkBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: <Widget>[
                      //Text("Label", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 70),
                      Icon(Icons.arrow_circle_up_rounded, color: Colors.white),
                    ],
                  ),
                ),
              ],
            )
        )
    );

    return ListView(
      padding: const EdgeInsets.all(4),
      children: <Widget>[
        ...containers,
      ],
    );
  }

  void handleClick(String value) {
    switch (value) {
      case 'Main View':
        setState(() {
          viewNumber = 1;
        });
        break;
      case 'Connect Device':
        setState(() {
          viewNumber = 0;
        });
        break;
    }
  }

  ListView _WelcomeScreen () {

    List<Container> containers = new List<Container>();
    containers.add(
        Container(

            child: Row(
              children: <Widget>[

                MyBox(mediumBlue, height: 200, text: "Welcome! \r\nWaiting for connection..."),

              ],
            )
        )
    );
    return ListView(
      padding: const EdgeInsets.all(2),
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
        return _WelcomeScreen();
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
      leading: IconButton(
        icon: Image.asset('assets/EBiCS_Icon.png'),
        onPressed: () { },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.bluetooth_connected_rounded, color: BT_color),
          onPressed: () { },
        ),
        IconButton(
          icon: Icon(Icons.radio_button_on, color: OnOff_color),
          onPressed: () {
            OnOff = !OnOff; //toggle
            if (OnOff) {
              setState(() {
                 UART_characteristic.write(
                    utf8.encode('AT+PIO21'));
                 OnOff_color= Colors.green[900];
              });
            }
            else {
              setState(() {
                UART_characteristic.write(
                    utf8.encode('AT+PIO20'));
                OnOff_color= Colors.grey;
              });
            }
          },
        ),


        PopupMenuButton<String>(
          onSelected: handleClick,
          itemBuilder: (BuildContext context) {
            return {'Main View', 'Connect Device'}.map((String choice) {
              return PopupMenuItem<String>(
                value: choice,
                child: Text(choice),
              );
            }).toList();
          },
        ),
      ],
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
  final Color fontColor;
  final double fontSize;
  final String text;

  MyBox(this.color, {this.height, this.fontSize, this.fontColor, this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(5),
        color: color,
        height: (height == null) ? 150 : height,

        child: (text == null)
            ? null
            : Center(
          child: Text(
            text,
            style: TextStyle(
                fontSize: (fontSize == null) ? 18 : fontSize,
              color: (fontColor == null) ? Colors.black : fontColor,
            ),
            textAlign: TextAlign.center,
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
// Returns the marker pointer gauge
  SfRadialGauge _getMarkerPointerExample(double paramvalue) {
    return SfRadialGauge(
      enableLoadingAnimation: true,
      axes: <RadialAxis>[
        RadialAxis(
            interval: 5,
            maximum: 60,
            axisLineStyle: AxisLineStyle(
              thickness: 0.05,
              thicknessUnit: GaugeSizeUnit.factor,
            ),
            showTicks: true,
            axisLabelStyle: GaugeTextStyle(
              fontSize: 18,
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