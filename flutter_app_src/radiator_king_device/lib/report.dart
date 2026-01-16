import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:radiator_king_device/generate_report.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Report extends StatefulWidget {
  int co2ppm;
  FuelType fuelType;
  String vehicleSpecs;
  String licenseCode;

  Report({super.key, required this.co2ppm, required this.fuelType, required this.vehicleSpecs, required this.licenseCode});

  @override
  State<StatefulWidget> createState() {
    return ReportState();
  }
}

Future<String?> getCompanyLogoImagePath() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('company_logo');
}

Future<String?> getCompanyName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('company_name');
}

class ReportState extends State<Report> {
  int co2ppm = 0;
  FuelType fuelType = FuelType.petrol;
  String vehicleSpecs = "";
  String licenseCode = "";

  @override
  void initState() {
    super.initState();
    co2ppm = widget.co2ppm;
    fuelType = widget.fuelType;
    vehicleSpecs = widget.vehicleSpecs;
    licenseCode = widget.licenseCode;
  }

  pw.Text generateReportTitlePdf(int co2ppm, FuelType fuelType) {
    if (fuelType == FuelType.petrol) {
      if (co2ppm < 500) {
        return pw.Text(
          "Normal",
          style: pw.TextStyle(
            color: PdfColor.fromRYB(0, 1, 1),
            fontWeight: pw.FontWeight.bold,
          ),
        );
      } else if (co2ppm < 2000) {
        return pw.Text(
          "Elevated",
          style: pw.TextStyle(
            color: PdfColor.fromRYB(1, 1, 0),
            fontWeight: pw.FontWeight.bold,
          ),
        );
      } else {
        return pw.Text(
          "High",
          style: pw.TextStyle(
            color: PdfColor.fromRYB(1, 0, 0),
            fontWeight: pw.FontWeight.bold,
          ),
        );
      }
    } else {
      if (co2ppm < 800) {
        return pw.Text(
          "Normal",
          style: pw.TextStyle(
            color: PdfColor.fromRYB(0, 1, 1),
            fontWeight: pw.FontWeight.bold,
          ),
        );
      } else if (co2ppm < 3000) {
        return pw.Text(
          "Elevated",
          style: pw.TextStyle(
            color: PdfColor.fromRYB(1, 1, 0),
            fontWeight: pw.FontWeight.bold,
          ),
        );
      } else {
        return pw.Text(
          "High",
          style: pw.TextStyle(
            color: PdfColor.fromRYB(1, 0, 0),
            fontWeight: pw.FontWeight.bold,
          ),
        );
      }
    }
  }

  Text generateReportTitle(int co2ppm, FuelType fuelType) {
    if (fuelType == FuelType.petrol) {
      if (co2ppm < 500) {
        return Text(
          "Normal",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        );
      } else if (co2ppm < 2000) {
        return Text(
          "Elevated",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return Text(
          "High",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    } else {
      if (co2ppm < 800) {
        return Text(
          "Normal",
          style: TextStyle(
            color: Colors.green,
            fontWeight: FontWeight.bold,
          ),
        );
      } else if (co2ppm < 3000) {
        return Text(
          "Elevated",
          style: TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        );
      } else {
        return Text(
          "High",
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        );
      }
    }
  }

  String generateReportBody(int co2ppm, FuelType fuelType) {
    if (fuelType == FuelType.petrol) {
      if (co2ppm < 500) {
        return "CO₂ levels were within the normal range.\n\nRecommendation: \nNo action required at this time.";
      } else if (co2ppm < 2000) {
        return "Elevated concentrations of CO₂ were detected in the cooling system.\nThis result strongly indicates active combustion gas leakage into the cooling system.\n\n Recommendation: \nIt is recommended that the vehicle be monitored closely and re-tested after additional driving or if symptoms develop. Further inspection by a qualified automotive technician is advised to assess the cooling system and engine sealing integrity. Additional diagnostic procedures may include cooling system pressure testing, compression testing, or repeat combustion gas testing under different operating conditions.";
      } else {
        return "High concentrations of CO₂ were detected in the cooling system.\nThis result strongly indicates active combustion gas leakage into the cooling system.\n\nRecommendation:\nIt is recommended that the vehicle be inspected by a qualified automotive technician as soon as possible to identify the source of the combustion gas intrusion. Further diagnostic procedures may include compression testing, cylinder leak-down testing, and inspection of the cylinder head gasket and related components.\nContinued operation of the vehicle without corrective action may result in engine overheating and further mechanical damage.";
      }
    } else {
      if (co2ppm < 800) {
        return "CO₂ levels were within the normal range.\n\nRecommendation: \nNo action required at this time.";
      } else if (co2ppm < 3000) {
        return "Elevated concentrations of CO₂ were detected in the cooling system.\nThis result strongly indicates active combustion gas leakage into the cooling system.\n\n Recommendation: \nIt is recommended that the vehicle be monitored closely and re-tested after additional driving or if symptoms develop. Further inspection by a qualified automotive technician is advised to assess the cooling system and engine sealing integrity. Additional diagnostic procedures may include cooling system pressure testing, compression testing, or repeat combustion gas testing under different operating conditions.";
      } else {
        return "High concentrations of CO₂ were detected in the cooling system.\nThis result strongly indicates active combustion gas leakage into the cooling system.\n\nRecommendation:\nIt is recommended that the vehicle be inspected by a qualified automotive technician as soon as possible to identify the source of the combustion gas intrusion. Further diagnostic procedures may include compression testing, cylinder leak-down testing, and inspection of the cylinder head gasket and related components.\nContinued operation of the vehicle without corrective action may result in engine overheating and further mechanical damage.";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF051518),
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => Navigator.pop(context, false),
          color: Colors.white,
        ),
        backgroundColor: Color(0xFF051518),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white,
                  )
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(10,10,10,5),
                      child: FittedBox(
                        fit: BoxFit.fitWidth,
                        child: Text(
                          "Digital combustion leak report",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20
                          ),
                        ),
                      )
                      
                    ),
                    Divider(),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10,10,10,5),
                      child: Text(
                        "Vehicle: $vehicleSpecs",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10,2,10,5),
                      child: Text(
                        "Number Plate: $licenseCode",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10,2,10,5),
                      child: Text(
                        fuelType == FuelType.petrol ? "Fuel Type: Petrol" : "Fuel Type: Diesel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10,10,10,5),
                      child: generateReportTitle(co2ppm, fuelType),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(10,10,10,10),
                      child: Text(
                        generateReportBody(co2ppm, fuelType),
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: InkWell(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Report generated by ",
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: "eblocktest.com ",
                                style: TextStyle(
                                  color: Colors.blue,
                                  decoration: TextDecoration.underline,  
                                ),
                                recognizer: TapGestureRecognizer()..onTap = () {
                                  launchUrlString("https://www.eblocktest.com");
                                }
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final pdfReport = pw.Document();

                  final now = DateTime.now();
                  String formatted = DateFormat('yMd').format(now);

                  final String? imagePath = await getCompanyLogoImagePath();
                  final String? companyName =  await getCompanyName();
                  pw.MemoryImage? pdfImage;

                  if (imagePath != null) {
                    final imageFile = File(imagePath);
                    final Uint8List imageBytes = imageFile.readAsBytesSync();

                    pdfImage = pw.MemoryImage(imageBytes);
                  }
                  
                  pdfReport.addPage(pw.Page(
                    pageFormat: PdfPageFormat.a4,
                    build: (pw.Context context) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Builder(
                            builder: (context) {
                              if (pdfImage != null) {
                                return pw.Container(
                                  alignment: pw.Alignment.center,
                                  child: pw.Image(pdfImage),
                                );
                              } else {
                                return pw.Container();
                              }
                            }
                          ),
                          pw.Text(
                            "Digital Combustion Leak Report",
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          pw.Builder(
                            builder: (context) {
                              if (pdfImage != null) {
                                return pw.Text(
                                  "Conducted by $companyName",
                                );
                              } else {
                                return pw.Container();
                              }
                            }
                          ),
                          pw.Text(
                            "Report generated on: $formatted\n\nVehicle: $vehicleSpecs\nNumber Plate: $licenseCode",
                          ),
                          pw.Text(
                            fuelType == FuelType.petrol ? "Fuel Type: Petrol" : "Fuel Type: Diesel",
                          ),
                          generateReportTitlePdf(co2ppm, fuelType),
                          pw.Text(
                            generateReportBody(co2ppm, fuelType).replaceAll("₂", "2"),
                          ),
                          pw.Text(
                            "\nReport by eblocktest.com",
                          ),
                        ]
                      );
                    }
                  ));          

                  final output = await getTemporaryDirectory();
                  final file = File("${output.path}/eblocktest_report.pdf");

                  await file.writeAsBytes(await pdfReport.save());

                  final params = ShareParams(
                    files: [XFile('${output.path}/eblocktest_report.pdf')],
                  );

                  final result = await SharePlus.instance.share(params);

                  if (result.status == ShareResultStatus.success) {
                    Navigator.pop(context, true);
                  }

                },
                icon: Icon(
                  Icons.share,
                  size: 20,
                  color: Colors.black,
                ),
                label: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    "Share Report",
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
              padding: EdgeInsets.fromLTRB(10, 10, 10, 20),
              child: ElevatedButton.icon(
                onPressed: () => setState(() {
                  // Navigator.popUntil(context, ModalRoute.withName('/'), false);
                  Navigator.pop(context, true);
                }),
                icon: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.black,
                ),
                label: FittedBox(
                  fit: BoxFit.fitHeight,
                  child: Text(
                    "New Test",
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