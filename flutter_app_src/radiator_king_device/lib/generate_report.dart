import 'package:flutter/material.dart';
import 'package:radiator_king_device/report.dart';

class GenerateReportForm extends StatefulWidget {
  int co2ppm;

  GenerateReportForm({super.key, required this.co2ppm});

  @override
  State<StatefulWidget> createState() {
    return GenerateReportFormState();
  }
}

enum FuelType { diesel, petrol}

class GenerateReportFormState extends State<GenerateReportForm> {
  final _formKey = GlobalKey<FormState>();

  FuelType? _fuelType = FuelType.petrol;
  String _vehicleSpecs = "";
  String _licenseCode = "";
  late int _co2ppm;

  bool shouldReset = false;

  @override
  void initState() {
    super.initState();
    _co2ppm = widget.co2ppm;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF051518),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, shouldReset),
          color: Colors.white,
        ),
        backgroundColor: Color(0xFF051518),
        title: Text(
          "Generate Report", 
          style: TextStyle(
            color: Colors.white
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              title: Text(
                "Highest Recorded CO₂ PPM: $_co2ppm",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Divider(), 
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                onSaved: (value){_vehicleSpecs=value!;},
                maxLines: null,
                maxLength: 100,
                style: TextStyle(
                  color: Colors.white,
                ),
                cursorColor: Colors.grey.shade100,
                decoration: InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                    ),
                  labelStyle: TextStyle(color: Colors.grey.shade300),
                  labelText: "Vehicle Specifications",
                  hintText: "Vehicle Model",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  helperStyle: TextStyle(color: Colors.grey.shade300),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter vehicle model";
                  }
                  return null;
                },
              ),
            ), 
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: TextFormField(
                onSaved: (value){_licenseCode=value!;},
                maxLines: null,
                maxLength: 20,
                style: TextStyle(
                  color: Colors.white,
                ),
                cursorColor: Colors.grey.shade100,
                decoration: InputDecoration(
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white)
                    ),
                  labelStyle: TextStyle(color: Colors.grey.shade300),
                  labelText: "Number Plate",
                  hintText: "Number Plate Code",
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  helperStyle: TextStyle(color: Colors.grey.shade300),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter number plate code";
                  }
                  return null;
                },
              ),
            ), 
            Divider(),       
            ListTile(
              title: Text(
                "Fuel Type",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ListTile(
              title: Text(
                "Petrol",
                style: TextStyle(color: Colors.white),
              ),
              leading: Radio<FuelType>(
                fillColor: WidgetStateProperty.all(Colors.white),
                value: FuelType.petrol,
                groupValue: _fuelType,
                onChanged: (FuelType? value) {
                  setState(() {
                    _fuelType = value;
                  });
                },
              ),
            ),
            ListTile(
              title: Text(
                "Diesel",
                style: TextStyle(color: Colors.white),
              ),
              leading: Radio<FuelType>(
                fillColor: WidgetStateProperty.all(Colors.white),
                value: FuelType.diesel,
                groupValue: _fuelType,
                onChanged: (FuelType? value) {
                  setState(() {
                    _fuelType = value;
                  });
                },
              ),
            ),
            Divider(), 
            Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ElevatedButton.icon(
                onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      shouldReset = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => Report(
                          co2ppm: _co2ppm,
                          vehicleSpecs: _vehicleSpecs,
                          licenseCode: _licenseCode,
                          fuelType: _fuelType!,
                        )),
                    );

                    if (shouldReset) {
                      Navigator.pop(context, shouldReset);
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
          ],
        ),
      ),
    );
  }
}