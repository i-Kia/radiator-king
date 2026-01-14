import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:radiator_king_device/bluetooth.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

import 'package:radiator_king_device/generate_report.dart';
import 'package:radiator_king_device/info.dart';

// Get Bluetooth Permissions
Future getPermissions()async{
  try{
    await Permission.bluetooth.request();
  }catch(e)
  {
    print(e.toString());
  }
}

@override
void initState() {
  getPermissions();
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, 
    DeviceOrientation.portraitDown,
  ]);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: HomePage(),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget{
  const HomePage({super.key, highestPPMValue});

  @override
  _HomePageState createState() => _HomePageState();
}

// Color.fromRGBO(9, 36, 41, 0)

class _HomePageState extends State<HomePage> {

  StreamSubscription<List<int>>? streamSub;
  BluetoothDevice? selectedDevice;

  bool connectionStatus = false;
  String receivedValue = "0";

  int highestPPMValue = 0;

  @override
  void initState() {
    super.initState();

    Timer _ = Timer.periodic(Duration(seconds: 2), (Timer t) {
      setState(() {
        if (connectionStatus){
          writeData();

          if (int.parse(receivedValue) > highestPPMValue){
            highestPPMValue = int.parse(receivedValue);
          }
        }
      });
    });
  }

  Color _getColor(int value) {
    if (value < 800) {
      return Colors.green;
    } else if (value < 1500) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF051518),
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => setState(() {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const InfoPage()),
              );
            }),
            icon: Icon(Icons.info),
            color: Colors.white,
          ),
          backgroundColor: Color(0xFF051518),
          centerTitle: true,
          title: Text(
            connectionStatus ? "${selectedDevice!.platformName} Connected" : "No Device Connected", 
            style: TextStyle(
              color: Colors.white
            ),
          ),
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FittedBox(
              fit: BoxFit.fill,
              child: SizedBox(
                height: 50,
                width: 50,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10.0),
                          color: Color(0xFF051518),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(5.0),
                          child: CircularProgressIndicator(
                            value: connectionStatus ? int.parse(receivedValue) / 5000.0 : 0,
                            backgroundColor: Colors.grey.shade700,
                            color: _getColor(int.parse(receivedValue)),
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    Center(
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Text(
                          connectionStatus ? receivedValue : "0", 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white
                          ),
                        ),
                      ),
                    ),
                    Center(
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Text(
                          "CO₂ ppm",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 2,
                            color: Colors.white
                          ),
                        ),
                      ),
                    ),

                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  if (connectionStatus) {
                    selectedDevice!.disconnect();
                    highestPPMValue = 0;
                  } else {
                    _navigateAndGetDevice(context);
                  }
                }),
                icon: Icon(
                  size: 20,
                  connectionStatus ? Icons.bluetooth_disabled : Icons.bluetooth,
                  color: Colors.black,
                ),
                label: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    connectionStatus ? "Disconnect Device" : "Connect Device",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(Colors.grey.shade100),
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)
                    ),
                  ),
                )
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (highestPPMValue != 0) {
                    final shouldReset = await Navigator.push(
                      context, 
                      MaterialPageRoute(builder: (context) => GenerateReportForm(co2ppm: highestPPMValue)),
                    );

                    if (shouldReset) {
                      highestPPMValue = 0;
                    }
                  }
                },
                icon: Icon(
                  Icons.edit_document,
                  size: 20,
                  color: Colors.black,
                ),
                label: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    "Generate Report",
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll<Color>(connectionStatus ? Colors.grey.shade100 : Colors.grey.shade600),
                  foregroundColor: WidgetStatePropertyAll<Color>(Colors.black),
                  shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)
                    ),
                  ),
                )
              ),
            ),
          ],
        ),
      )
    );
  }

  /*Future<void> _dialogBuilder(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Saved Log'),
          content: Text(
            'File was saved to $fileLocation',
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: Text('Ok'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(textStyle: Theme.of(context).textTheme.labelLarge),
              child: Text('Copy'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: recordedValues.toString().replaceAll(", ", "\n").replaceAll("[", "").replaceAll("]", ""))).then((_){
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Data was saved to clipboard!")));
                });
              },
            ),
          ],
        );
      },
    );
  }*/

  Future<void> _navigateAndGetDevice(BuildContext context) async {

    // Push Device Selection Screen
    final SelectedDevice? poppedDevice = await Navigator.push(
      context,
      MaterialPageRoute<SelectedDevice>(builder: (context) => const BluetoothSettings()),
    );

    if (poppedDevice != null){

      // Check State of Device
      setState(() {
        selectedDevice = poppedDevice.device;

        if(poppedDevice.state == 1){
          BluetoothConnectionState? ev;
          selectedDevice!.connectionState.listen((event) {
            if (ev == BluetoothConnectionState.connected){
              connectionStatus = true;
            } else {
              connectionStatus = false;
            }
          });
        } else if (poppedDevice.state == 0) {
          connectionStatus = false;
        }
      });

      // Connect to Device
      await selectedDevice!.connect(license: License.free).then((value) {
        selectedDevice!.connectionState.listen((event) async{
          setState(() {  
            if (event == BluetoothConnectionState.connected){
              connectionStatus = true;
            } else {
              connectionStatus = false;
            }
          });

          if(event == BluetoothConnectionState.disconnected){
            await streamSub!.cancel();
          }
        });
      });
    }
  }

  Future<void> readData() async {
    // Last Bluetooth Service is the Device
    List<BluetoothService> services = await selectedDevice!.discoverServices();
    BluetoothService lastService = services.last;
    BluetoothCharacteristic lastCharacterist = lastService.characteristics.last;

    streamSub = lastCharacterist.onValueReceived.listen((value) async{
      if (value.isNotEmpty) {
        String s = String.fromCharCodes(value);
        setState(() {
          receivedValue = s;
        });
      }
    });
  }

  Future<void> writeData() async {
    List<BluetoothService> services = await selectedDevice!.discoverServices();
    BluetoothService lastservice = services.last;
    BluetoothCharacteristic lastCharacterist = lastservice.characteristics.last;

    List<int> list = utf8.encode("retrieve-data");
    Uint8List bytes = Uint8List.fromList(list);

    await lastCharacterist.setNotifyValue(true);
    await lastCharacterist.write(bytes);

    await readData();
  }

  /*Future<String> get _localPath async {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    fileLocation = '$path/CO2_Log_${DateTime.now()}.txt'.replaceAll(":", "_").replaceAll("-", "_").replaceAll(" ", "_");
    return File(fileLocation);
  }

  Future<File> writeCounter(String data) async {
    final file = await _localFile;

    return file.writeAsString(data);
  }*/

}

