import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:radiator_king_device/bluetooth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

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

void main() {
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
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

// Color.fromRGBO(9, 36, 41, 0)

class _HomePageState extends State<HomePage> {

  StreamSubscription<List<int>>? streamSub;
  BluetoothDevice? selectedDevice;

  bool connectionStatus = false;
  String receivedValue = "400";

  bool recording = false;

  List<String> recordedValues = [];
  String fileLocation = "";

  @override
  void initState() {
    super.initState();

    Timer _everyTwoSeconds = Timer.periodic(Duration(seconds: 2), (Timer t) {
      setState(() {
        if (connectionStatus){
          writeData();

          if (recording){
            recordedValues.add(receivedValue);
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context){
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFF092429),
        appBar: AppBar(
          backgroundColor: Color(0xFF051518),
          title: Text(
            "Main Menu", 
            style: TextStyle(
              color: Colors.white
            ),
          ),
        ),

        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 1,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(8, 4, 4, 4),
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() {
                          _navigateAndGetDevice(context);
                        }),
                        icon: Icon(
                          Icons.bluetooth,
                          size: 18,
                          color: Colors.black,
                        ),
                        label: connectionStatus ? Text("Change Device") : Text("Connect Device"),
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
                    )
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      margin: EdgeInsets.fromLTRB(4, 4, 8, 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: connectionStatus ? Colors.white : Colors.grey.shade600,
                      ),
                      child: Center(
                        child: Text(
                          connectionStatus ? "${selectedDevice!.platformName} Connected" : "No Device Connected", 
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 5,
              child: Container(
                margin: EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: Color(0xFF051518),
                ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Container(),
                      ),
                      Expanded(
                        flex: 10,
                        child: Center(
                          child: Text(
                            connectionStatus ? receivedValue : "", 
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 150,
                              color: Colors.white
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          connectionStatus ? "CO₂ ppm" : "",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Container(),
                      )
                    ],
                  ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                margin: EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: ElevatedButton.icon(
                  onPressed: () async => {
                    if (connectionStatus) {
                      if (recording){
                        // Stop Recording
                        await writeCounter(recordedValues.toString().replaceAll(", ", "\n").replaceAll("[", "").replaceAll("]", "")),
                        setState(() {
                          _dialogBuilder(context);
                        }),
                        recording = false,

                      } else {
                        // Start Recording
                        recordedValues = [],
                        recording = true,
                      }
                    },
                  },
                  icon: Icon(
                    recording ? Icons.stop : Icons.fiber_manual_record,
                    size: connectionStatus ? 40 : 0,
                    color:  Colors.red,
                  ),
                  label: Text(
                    connectionStatus ? (recording ? "Stop Recording..." : "Start Recording") : "No Device Connected",
                    style: TextStyle(
                      fontSize: 30,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      )
    );
  }

  Future<void> _dialogBuilder(BuildContext context) {
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
  }

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
        print(poppedDevice.state);

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

  Future<String> get _localPath async {
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
  }

}

