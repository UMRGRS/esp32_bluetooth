import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:serialbt/config/config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _bluetooth = FlutterBluetoothSerial.instance;

  bool BTState = false;
  bool BTConnected = false;
  BluetoothConnection? connection;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? device;
  String content = '';

  @override
  void initState() {
    super.initState();
    permissions();
    stateBT();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter Bluetooth"),
      ),
      body: Column(
        children: [
          switchBT(),
          const Divider(
            height: 20,
          ),
          deviceInfo(),
          const Divider(
            height: 20,
          ),
          Expanded(child: devicesList()),
          const Divider(
            height: 20,
          ),
          buttons(),
        ],
      ),
    );
  }

  void permissions() async {
    await Permission.bluetoothConnect.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetooth.request();
    await Permission.location.request();
  }

  void stateBT() {
    _bluetooth.state.then(
      (value) {
        setState(() {
          BTState = value.isEnabled;
        });
      },
    );

    _bluetooth.onStateChanged().listen((event) {
      switch (event) {
        case BluetoothState.STATE_ON:
          BTState = true;
          break;
        case BluetoothState.STATE_OFF:
          BTState = false;
          break;
        case BluetoothState.STATE_TURNING_ON:
          break;
        case BluetoothState.STATE_BLE_TURNING_OFF:
          turnOff();
          break;
      }
      setState(() {});
    });
  }

  void turnOnBT() async {
    await _bluetooth.requestEnable();
  }

  void turnOffBT() async {
    await _bluetooth.requestDisable();
    await connection?.finish();
    BTConnected = false;
    devices = [];
    device = null;
    setState(() {});
  }

  Widget switchBT() {
    return SwitchListTile(
        activeColor: Colors.blue,
        value: BTState,
        title: BTState
            ? const Text('Bluetooth encendido')
            : const Text('Bluetooth apagado'),
        onChanged: (bool value) {
          if (value) {
            turnOnBT();
          } else {
            turnOffBT();
          }
        },
        secondary: BTState
            ? const Icon(Icons.bluetooth)
            : const Icon(Icons.bluetooth_disabled));
  }

  Widget deviceInfo() {
    return ListTile(
      title: device == null ? Text('Sin dispositivo') : Text('${device!.name}'),
      subtitle:
          device == null ? Text('Sin dispositivo') : Text('${device!.address}'),
      trailing: BTConnected
          ? IconButton(
              onPressed: () {
                turnOff();
                setState(() {});
              },
              icon: Icon(Icons.delete))
          : IconButton(
              onPressed: () {
                listDevices();
              },
              icon: Icon(Icons.search)),
      tileColor: Colors.grey,
    );
  }

  void listDevices() async {
    devices = await _bluetooth.getBondedDevices();
    debugPrint(devices.toString());
    setState(() {});
  }

  Widget devicesList() {
    if (BTConnected) {
      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Text(
          content,
          style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
              wordSpacing: 1),
        ),
      );
    } else {
      return devices.isEmpty
          ? const Text('No hay dispositivos')
          : ListView.builder(
              itemCount: devices.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text('${devices[index].name}'),
                  subtitle: Text('${devices[index].address}'),
                  trailing: IconButton(
                    icon: Icon(Icons.connect_without_contact),
                    onPressed: () async {
                      connection = await BluetoothConnection.toAddress(
                          devices[index].address);
                      device = devices[index];
                      BTConnected = true;
                      getData();
                      setState(() {});
                    },
                  ),
                  tileColor: Colors.blueAccent,
                );
              },
            );
    }
  }

  void getData() {
    connection!.input!.listen((event) {
      content += String.fromCharCodes(event);
      setState(() {});
    });
  }

  void sendData(String msg) {
    if (connection != null) {
      if (connection!.isConnected) {
        connection?.output.add(ascii.encode("$msg\n"));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('No connection')));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No connection')));
    }
  }

  Widget buttons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
            onPressed: () {
              sendData('led_on');
            },
            icon: Icon(Icons.lightbulb)),
        IconButton(
            onPressed: () {
              sendData('led_off');
            },
            icon: Icon(Icons.lightbulb_outline)),
        IconButton(
            onPressed: () {
              sendData('hello');
            },
            icon: Icon(Icons.waving_hand)),
      ],
    );
  }

  void turnOff() async {
    await connection?.finish();
    BTConnected = false;
    devices = [];
    device = null;
    setState(() {});
  }
}
