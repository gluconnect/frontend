import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_ble/universal_ble.dart';
import 'brains.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
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
    errormsg = msg;
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
        bleDevices.add(res);//add to list of options if not already there
      }else{
        if(res.name==null&&bleDevices[i].name!=null){
          res.name = bleDevices[i].name;//update new info for existing devices
        }
        bleDevices[i] = res;
      }
      setState(() {
        glucometer!["dev"] = res;
      });
    };
  }
  @override
  Widget build(BuildContext context){
    var appState = context.watch<MyAppState>();
    return Column(
      children: [
        Text(errormsg),
        Row(
          children: [
            ElevatedButton(child: isscanning?Text("Stop Search"):Text("Search for Glucometers"), onPressed: () async{
              if(!isscanning){
                setState(() {
                  bleDevices.clear();
                  isscanning = true;
                });
                try{
                  await UniversalBle.startScan(
                    scanFilter: ScanFilter(
                      withServices: ["0x1808"]
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
                err("Enabled? $v");
              }, child: Text("Enable Bluetooth")),
            if(BleCapabilities.requiresRuntimePermission)
              ElevatedButton(onPressed: () async{
                if(await PermissionHandler.arePermissionsGranted()){
                  err("Permissions Granted");
                }
              }, child: Text("Check Permissions")),
            if(BleCapabilities.supportsConnectedDevicesApi)
              ElevatedButton(onPressed: () async{
                List<BleDevice> devs = await UniversalBle.getSystemDevices();
                if(devs.isEmpty){
                  err("No Connected Devices Found");
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
            ? Placeholder()
            : ListView.separated(shrinkWrap: true, itemBuilder: (context, index){
                BleDevice dev = bleDevices[bleDevices.length-index-1];
                return Text(dev.deviceId);
              }, separatorBuilder: (context, index)=>Divider(), itemCount: bleDevices.length)
        )
      ],
    );
  }
}
class Midget extends StatefulWidget{
  @override
  State<Midget> createState() => _MidgetState();
}

class _MidgetState extends State<Midget> {
  Timer? timer;
  Function? callback;
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(seconds: 15), (timer){callback!();});
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return SizedBox.shrink();
  }
}
class PermissionHandler {
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
        print("Bluetooth Permission Permanently Denied");
        openAppSettings();
      }
      return false;
    }

    if (!locationPermissionGranted) {
      PermissionStatus locationPermissionCheck =
          await Permission.location.request();
      if (locationPermissionCheck.isPermanentlyDenied) {
        print("Location Permission Permanently Denied");
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
    } else {
      PermissionStatus permissionStatus = await Permission.bluetooth.request();
      blePermissionGranted = permissionStatus.isGranted;
      locationPermissionGranted = await requiresLocationPermission
          ? (await Permission.locationWhenInUse.request()).isGranted
          : true;
    }
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
Future<void> connectGlucometer() async{
  void decode(Uint8List s){
    //
  }
  //connect to glucometer when available, and obtain service to get readings
  UniversalBle.onScanResult = (BleDevice bleDevice) async {
    var deviceId = bleDevice.deviceId;
    print("Device found "+deviceId);
    await UniversalBle.connect(deviceId);
    print("Device connected");
    List<BleService> b = await UniversalBle.discoverServices(deviceId);
    print("Services obtained");
    BleService s = b.firstWhere((t)=>t.uuid=='0x1808');
    print("Service id "+s.uuid);
    Uint8List us = await UniversalBle.readValue(deviceId, s.uuid, '0000-00001-'+deviceId);
    decode(us);
  };
  AvailabilityState state = await UniversalBle.getBluetoothAvailabilityState();
  // Start scan only if Bluetooth is powered on, make sure it is, if not, request perms
  print(state);
  if (state == AvailabilityState.poweredOn) {
    print("Starting scan");
    UniversalBle.startScan(
      /*scanFilter: ScanFilter(
        withServices: ["0x1808"]
      )*/
    );
  }
}