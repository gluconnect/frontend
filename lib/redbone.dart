import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_ble/universal_ble.dart';
import 'brains.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
class BigPharma{
  static var service = BleUuidParser.string("A07498CA-AD5B-474E-940D-16F1FBE7E8CD");
  static var indexchange = BleUuidParser.string("51FF12BB-3ED8-46E5-B4F9-D64E2FEC021B");
  static var tocomm = BleUuidParser.string("bfc0c92f-317d-4ba9-976b-cc11ce77b4ca");
}
class Glucometer{
  static var count = 1;
  Glucometer({this.id = 0, this.name = "Glucometer", this.meter});
  String name = "HELLOWORLD";
  int id;
  BleDevice? meter;
  BleService? reads;
  Future<bool> connect() async{
    if(meter==null){
      return false;
    }
    var deviceId = meter!.deviceId;
    print("Device found "+deviceId);
    await UniversalBle.connect(deviceId);
    print("Device connected");
    List<BleService> b = await UniversalBle.discoverServices(deviceId);
    print("Services obtained");
    reads = b.firstWhere((t)=>t.uuid==BigPharma.service, orElse: null);
    if(reads==null){
      return false;
    }
    print("Service id "+reads!.uuid);
    //
    return true;
  }
  Future<String> update(MyAppState s) async{
    if(meter==null){
      return "no meter connected for "+name;
    }
    BleConnectionState isconnected = await meter!.connectionState;
    if(isconnected!=BleConnectionState.connected||reads==null||meter==null){
      bool worked = await connect();
      //TODO call error if failed
      if(!worked)return "device not connectable";
    }
    //TODO get reading
    String fin = "";
    Uint8List us = await UniversalBle.readValue(meter!.deviceId, reads!.uuid, BigPharma.tocomm);
    int n = decodeNum(us);
    fin+="num readings: "+n.toString()+",";
    Map m = jsonDecode(String.fromCharCodes(us));
    for(int i = 0; i < n; i++){
      await UniversalBle.writeValue(meter!.deviceId, reads!.uuid, BigPharma.indexchange, encodeNum(i), BleOutputProperty.withResponse);
      fin+="requesting reading "+i.toString()+",";
      GlucoReading r = GlucoReading(String.fromCharCodes(await UniversalBle.readValue(meter!.deviceId, reads!.uuid, BigPharma.indexchange)));
      fin+="REAADING OBTAINED: "+[r.timestamp, r.value, r.meal, r.measure_method, r.comment].toString()+",";
      if(!s.readings.any((GlucoReading e)=>e.timestamp==r.timestamp)){
        s.addReading(r.timestamp, r.value, r.meal, r.measure_method, r.comment);
        fin+="Sending new info to serv,";
        s.scheduleUpdate();
      }
    }
    return fin;
  }
  Uint8List encodeNum(int i){
    ByteData d = ByteData(8);
    d.setUint64(0 ,i, Endian.little);
    return d.buffer.asUint8List();
  }
  int decodeNum(Uint8List i){
    ByteData b = ByteData.sublistView(i);
    return b.getUint64(0, Endian.little);
  }
}
class ConnectGlucometer extends StatefulWidget{
  Map<String, BleDevice?>? glucometer;
  ConnectGlucometer({super.key, this.glucometer});

  @override
  State<ConnectGlucometer> createState() => _ConnectGlucometerState(glucometer: glucometer);
}

class _ConnectGlucometerState extends State<ConnectGlucometer> {
  final bleDevices = <BleDevice>[];
  bool isscanning = false;
  AvailabilityState? avSt;
  String errormsg = "";
  Map<String, BleDevice?>? glucometer;
  _ConnectGlucometerState({this.glucometer});
  void err(String msg){
    errormsg = msg+"  "+PermissionHandler.errorJunk;
    print("BLE: "+msg);
  }
  @override
  void initState(){
    super.initState();
    UniversalBle.onAvailabilityChange = (state){
      setState(() {
        avSt = state;
      });
    };
    UniversalBle.onScanResult = (res){
      int i = bleDevices.indexWhere((e)=>e.deviceId==res.deviceId);
      if(i==-1){
        bleDevices.clear();
        bleDevices.add(res);//add to list of options if not already there
      }else{
        if(res.name==null&&bleDevices[i].name!=null){
          res.name = bleDevices[i].name;//update new info for existing devices
        }
        bleDevices[i] = res;
      }
      setState(() {
      });
    };
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    if(!bleDevices.isEmpty)glucometer!["dev"] = bleDevices[0];
    return Column(
      children: [
        Text(errormsg),
        Row(
          children: [
            ElevatedButton(child: isscanning?Text("Stop Search"):Text("Search for Glucometers"), onPressed: () async{
              PermissionHandler.errorJunk = "";
              if(!isscanning){
                setState(() {
                  bleDevices.clear();
                  isscanning = true;
                });
                try{
                  await UniversalBle.startScan(
                    scanFilter: ScanFilter(
                      withServices: [BigPharma.service]
                    )
                  );
                }catch(e){
                  setState(() {
                    isscanning = false;
                    err("Something went wrong");
                  });
                }
              }else{
                await UniversalBle.stopScan();
                setState(() {
                  isscanning = false;
                });
              }
            },),
            if(BleCapabilities.supportsBluetoothEnableApi&&avSt==AvailabilityState.poweredOff)
              ElevatedButton(onPressed: () async{
                bool v = await UniversalBle.enableBluetooth();
                err("Bootuth Enabled? $v");
                setState((){});
              }, child: Text("Enable Bluetooth")),
            if(BleCapabilities.requiresRuntimePermission)
              ElevatedButton(onPressed: () async{
                if(await PermissionHandler.arePermissionsGranted()){
                  err("Permissions Granted");
                  setState((){});
                }else{
                  err("Perissions failed to grant");
                  setState((){});
                }
              }, child: Text("Check Permissions")),
            if(BleCapabilities.supportsConnectedDevicesApi)
              ElevatedButton(onPressed: () async{
                List<BleDevice> devs = await UniversalBle.getSystemDevices();
                if(devs.isEmpty){
                  err("No Connected Devices Found");
                  setState((){});
                }
                setState(() {
                  bleDevices.clear();
                  bleDevices.addAll(devs);
                });
              }, child: Text("List Connected Devices")),
            if(bleDevices.isNotEmpty)
              ElevatedButton(onPressed: (){
                setState(() {
                  bleDevices.clear();
                });
              }, child: Text("Clear List"))
          ]
        ),
        Text("BLE Availability: ${avSt?.name}"),
        Divider(color: Colors.green.shade900),
        Container(child: isscanning&&bleDevices.isEmpty
          ? Center(child: CircularProgressIndicator.adaptive())
          : !isscanning&&bleDevices.isEmpty
            ? Text("Try connecting devices first")
            : ListView.separated(shrinkWrap: true, itemBuilder: (context, index){
                BleDevice dev = bleDevices[bleDevices.length-index-1];
                return Text((index==0?"This device will be connected: ":"")+(dev.name!=null?dev.name!:dev.deviceId));
              }, separatorBuilder: (context, index)=>Divider(), itemCount: bleDevices.length)
        )
      ],
    );
  }
}
/*class Didget extends StatefulWidget{
  Function callback;
  Didget({super.key, required this.callback});
  @override
  State<Didget> createState() => _DidgetState(callback: callback);
}
class _DidgetState extends State<Didget>{
  Function callback;
  _DidgetState({required this.callback});
  @override
  Widget build(BuildContext context){
    call
    return Text(callback.msg);
  }
}*/
class Midget extends StatefulWidget{
  Function callback;
  String message;
  Midget({super.key, required this.message, required this.callback});
  @override
  State<Midget> createState() => _MidgetState(message: message, callback: callback);
}

class _MidgetState extends State<Midget> {
  Function callback;
  String message;
  _MidgetState({required this.message, required this.callback});
  Future<void> update() async{
    await Future.delayed(Duration(seconds: 15));
    callback();
    setState((){});
  }
  @override
  Widget build(BuildContext context){
    UniversalBle.onConnectionChange = (String deviceId, bool isConnected, String? error) {
      //TODO: tell user device disconnected
    };
    callback();
    //update();
    return ElevatedButton(onPressed: (){
      callback();
    }, child: Text(message));
  }
}
class PermissionHandler {
  static String errorJunk = "";
  static Future<bool> arePermissionsGranted() async {
    if (!isMobilePlatform) return true;

    var status = await _permissionStatus;
    bool blePermissionGranted = status[0];
    bool locationPermissionGranted = status[1];

    if (locationPermissionGranted && blePermissionGranted) return true;

    if (!blePermissionGranted) {
      PermissionStatus blePermissionCheck =
          await Permission.bluetooth.request();
      if (blePermissionCheck.isPermanentlyDenied) {
        errorJunk+="Bluetooth Permission Permanently Denied; ";
        openAppSettings();
      }
      return false;
    }

    if (!locationPermissionGranted) {
      PermissionStatus locationPermissionCheck =
          await Permission.location.request();
      if (locationPermissionCheck.isPermanentlyDenied) {
        errorJunk+="Location Permission Permanently Denied; ";
        openAppSettings();
      }
      return false;
    }

    return false;
  }

  static Future<List<bool>> get _permissionStatus async {
    bool blePermissionGranted = false;
    bool locationPermissionGranted = false;

    if (await requiresExplicitAndroidBluetoothPermissions) {
      bool bleConnectPermission =
          (await Permission.bluetoothConnect.request()).isGranted;
      bool bleScanPermission =
          (await Permission.bluetoothScan.request()).isGranted;

      blePermissionGranted = bleConnectPermission && bleScanPermission;
      locationPermissionGranted = true;
      errorJunk+="Required Android BLE perms; ";
    } else {
      PermissionStatus permissionStatus = await Permission.bluetooth.request();
      blePermissionGranted = permissionStatus.isGranted;
      locationPermissionGranted = await requiresLocationPermission
          ? (await Permission.locationWhenInUse.request()).isGranted
          : true;
    }
    errorJunk+="Permission status: location->"+locationPermissionGranted.toString()+", connect->"+blePermissionGranted.toString()+"; ";
    return [locationPermissionGranted, blePermissionGranted];
  }

  static bool get isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<bool> get requiresLocationPermission async =>
      !kIsWeb &&
      Platform.isAndroid &&
      (!await requiresExplicitAndroidBluetoothPermissions);

  static Future<bool> get requiresExplicitAndroidBluetoothPermissions async {
    if (kIsWeb || !Platform.isAndroid) return false;
    AndroidDeviceInfo androidInfo = await DeviceInfoPlugin().androidInfo;
    return androidInfo.version.sdkInt >= 31;
  }
}