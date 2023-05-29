import 'package:image/image.dart' as im;
import 'dart:async';
import 'dart:io';
import 'package:charset_converter/charset_converter.dart';
import 'package:dedepos/core/logger/logger.dart';
import 'package:dedepos/core/service_locator.dart';
import 'package:dedepos/global.dart' as global;
import 'package:dedepos/global_model.dart';
import 'package:dedepos/util/network.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_usb_printer/flutter_usb_printer.dart';
import 'package:get/utils.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'dart:ui' as ui;

class PrinterConfigScreen extends StatefulWidget {
  const PrinterConfigScreen({Key? key}) : super(key: key);

  @override
  State<PrinterConfigScreen> createState() => _PrinterConfigScreenState();
}

class _PrinterConfigScreenState extends State<PrinterConfigScreen> {
  FlutterUsbPrinter flutterUsbPrinter = FlutterUsbPrinter();
  bool connected = false;
  bool printBinder = false;
  int paperSize = 0;
  String serialNumber = "";
  String printerVersion = "";
  TextEditingController usbDeviceController = TextEditingController();
  TextEditingController usbVendorIdController = TextEditingController();
  TextEditingController usbProductIdController = TextEditingController();
  TextEditingController ipAddressController = TextEditingController();
  TextEditingController portController = TextEditingController();
  int printerConnectType = global.appLocalStrongData.connectType;
  List<PrinterDeviceModel> printerList = [];
  late Timer screenTimer;
  bool printBillAuto = true;
  int printerPaperSize = 2;
  int printerSelectedIndex = -1;

  @override
  void initState() {
    ipAddressController.text = global.printerCashierIpAddress;
    portController.text = global.printerCashierIpPort.toString();
    getDeviceList();
    screenTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    screenTimer.cancel();
    super.dispose();
  }

  void scanNetworkPrinter() async {
    CapabilityProfile profile = await CapabilityProfile.load();
    String appIpAddress = await ipAddress();
    String subNet = appIpAddress.substring(0, appIpAddress.lastIndexOf('.'));
    for (int i = 1; i < 255; i++) {
      String ip = "$subNet.$i";
      NetworkPrinter printer = NetworkPrinter(PaperSize.mm80, profile);
      printer.connect(ip, port: 9100).then((value) {
        if (value == PosPrintResult.success) {
          if (printerList.any((element) => element.ipAddress == ip) == false) {
            printerList.add(PrinterDeviceModel(
              fullName: "IP Printer : $ip",
              productName: "IP Printer",
              ipAddress: ip,
              ipPort: 9100,
              connectType: global.PrinterCashierConnectEnum.ip,
            ));
          }
          printer.disconnect();
        }
      });
    }
  }

  void getDeviceList() async {
    printerConnectType = 0;
    printerList.clear();
    printerList.add(PrinterDeviceModel(
      fullName: "SUNMI Printer",
      deviceName: "SUNMI Printer",
      connectType: global.PrinterCashierConnectEnum.sunmi1,
    ));
    setState(() {});
    List<Map<String, dynamic>> results = [];
    results = await FlutterUsbPrinter.getUSBDeviceList();

    print("getDeviceList length: ${results.length}");
    for (var printer in results) {
      printerList.add(PrinterDeviceModel(
        fullName: "USB Printer : ${printer["manufacturer"]}",
        productName: printer["productName"],
        deviceName: printer["deviceName"],
        deviceId: printer["deviceId"],
        manufacturer: printer["manufacturer"],
        vendorId: printer["vendorId"],
        productId: printer["productId"],
        connectType: global.PrinterCashierConnectEnum.usb,
      ));
    }
    scanNetworkPrinter();
  }

  void connect(int vendorId, int productId) async {
    bool? returned = false;
    try {
      returned = await flutterUsbPrinter.connect(vendorId, productId);
    } on PlatformException {
      //response = 'Failed to get platform version.';192
    }
    if (returned!) {
      setState(() {
        connected = true;
      });
    }
  }

  void printTest() {
    switch (printerConnectType) {
      case 1:
        printTestByUsb();
        break;
      case 2:
        printTestByIpAddress(
            ipAddress: ipAddressController.text,
            port: int.parse(portController.text));
        break;
      case 100:
        printTestBySunmi1();
        break;
    }
  }

  Future<void> printTestBySunmi1() async {
    await SunmiPrinter.bindingPrinter();
    await SunmiPrinter.startTransactionPrint(true);

    double maxHeight = 10;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawRect(
        const Rect.fromLTWH(0.0, 0.0, 640.0, 10000.0), backgroundPaint);

    for (int loop = 1; loop < 10; loop++) {
      TextSpan span = TextSpan(
          style: TextStyle(
              color: Colors.black, fontSize: 24 + (loop.toDouble() * 2)),
          text: "สวัสดีประเทศไทย " + loop.toString());
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(0, maxHeight.toDouble()));
      maxHeight += tp.height;
    }
    final picture = recorder.endRecording();
    final imageBuffer = picture.toImage(640, maxHeight.toInt());
    final pngBytes = await imageBuffer
        .then((value) => value.toByteData(format: ui.ImageByteFormat.png));
    im.Image? imageDecode = im.decodeImage(pngBytes!.buffer.asUint8List());
    int printMaxHeight = 500;
    int calcLoop = imageDecode!.height ~/ printMaxHeight;
    for (int i = 0; i <= calcLoop; i++) {
      try {
        if (i != 0) {
          sleep(const Duration(milliseconds: 100));
        }
        im.Image croppedImage = im.copyCrop(imageDecode, 0, i * printMaxHeight,
            imageDecode.width, printMaxHeight);
        List<int> croppedImageBytes = im.encodePng(croppedImage);
        Uint8List imageCopy = Uint8List.fromList(croppedImageBytes);
        await SunmiPrinter.printImage(imageCopy);
      } catch (e) {
        serviceLocator<Log>().error(e);
      }
    }
    await SunmiPrinter.lineWrap(2); 
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printQRCode('https://www.dedepos.com');
    await SunmiPrinter.submitTransactionPrint();
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<void> printTestByIpAddress(
      {required String ipAddress, required int port}) async {
    PaperSize paper = PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    NetworkPrinter printer = NetworkPrinter(paper, profile);
    try {
      PosPrintResult res = await printer.connect(ipAddress, port: port);
      if (res == PosPrintResult.success) {
        printer.printCodeTable();
        printer.feed(3);
        printer.emptyLines(0);
        printer.text("--------------------------------------");
        printer.text("Hello world");
        printer.text("Testing ESC POS printer...");
        printer.text("--------------------------------------");
        printer.text("Font size: 100%",
            styles: const PosStyles(
                height: PosTextSize.size1, width: PosTextSize.size1));
        printer.text("Font size: 200%",
            styles: const PosStyles(
                height: PosTextSize.size2, width: PosTextSize.size2));
        printer.text("Font size: 400%",
            styles: const PosStyles(
                height: PosTextSize.size3, width: PosTextSize.size3));
        printer.text("--------------------------------------");
        printer.feed(1);
        printer.qrcode("www.dedepos.com", size: QRSize.Size8);
        printer.feed(1);
        printer.barcode(Barcode.upcA([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4]));
        printer.feed(3);
        printer.cut();
        printer.drawer();
        printer.disconnect();
      }
    } catch (e) {
      serviceLocator<Log>().error(e);
    }
  }

  Future<void> printTestByUsb() async {
    bool returned = false;
    try {
      int vendorId = int.tryParse(usbVendorIdController.text) ?? 0;
      int productId = int.tryParse(usbProductIdController.text) ?? 0;
      returned = (await flutterUsbPrinter.connect(vendorId, productId))!;
    } on PlatformException {
      serviceLocator<Log>().error('Failed to get platform version.');
    }
    if (returned) {
      setState(() {
        connected = true;
      });
    }
    if (connected) {
      try {
        var data = Uint8List.fromList(
            utf8.encode(" Hello world Testing ESC POS printer..."));
        await flutterUsbPrinter.write(data);
      } on PlatformException {
        //response = 'Failed to get platform version.';
      }
    }
/*    PaperSize paper = PaperSize.mm80;
    CapabilityProfile profile = await CapabilityProfile.load();
    NetworkPrinter printer = NetworkPrinter(paper, profile);
    try {
      PosPrintResult res = await printer.connect(ipAddress, port: port);
      if (res == PosPrintResult.success) {
        printer.printCodeTable();
        printer.feed(3);
        printer.emptyLines(0);
        printer.text("--------------------------------------");
        printer.text("Hello world");
        printer.text("Testing ESC POS printer...");
        printer.text("--------------------------------------");
        printer.text("Font size: 100%",
            styles:
                PosStyles(height: PosTextSize.size1, width: PosTextSize.size1));
        printer.text("Font size: 200%",
            styles:
                PosStyles(height: PosTextSize.size2, width: PosTextSize.size2));
        printer.text("Font size: 400%",
            styles:
                PosStyles(height: PosTextSize.size3, width: PosTextSize.size3));
        printer.text("--------------------------------------");
        printer.feed(1);
        printer.qrcode("www.dedepos.com", size: QRSize.Size8);
        printer.feed(1);
        printer.barcode(Barcode.upcA([1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4]));
        printer.feed(3);
        printer.cut();
        printer.drawer();
        printer.disconnect();
      }
    } catch (e) {
      print(e);
    }*/
  }

  Widget printerListWidget() {
    return Container(
        padding: const EdgeInsets.all(2),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue),
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: (printerList.isEmpty)
            ? Center(
                child: LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue,
                  size: 100,
                ),
              )
            : ListView.builder(
                itemBuilder: (context, index) {
                  return Padding(
                      padding: const EdgeInsets.all(4),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: (index == printerSelectedIndex)
                                ? Colors.orange
                                : Colors.blue,
                          ),
                          onPressed: () {
                            setState(() {
                              printerSelectedIndex = index;
                              switch (printerList[index].connectType) {
                                case global.PrinterCashierConnectEnum.usb:
                                  usbDeviceController.text =
                                      printerList[index].deviceName;
                                  usbVendorIdController.text =
                                      printerList[index].vendorId;
                                  usbProductIdController.text =
                                      printerList[index].productId;
                                  printerConnectType = 1;
                                  break;
                                case global.PrinterCashierConnectEnum.ip:
                                  ipAddressController.text =
                                      printerList[index].ipAddress;
                                  portController.text = "9100";
                                  printerConnectType = 2;
                                  break;
                                case global.PrinterCashierConnectEnum.bluetooth:
                                  printerConnectType = 3;
                                  break;
                                case global.PrinterCashierConnectEnum.serial:
                                  printerConnectType = 4;
                                  break;
                                case global.PrinterCashierConnectEnum.sunmi1:
                                  printerConnectType = 100;
                                  break;
                              }
                            });
                          },
                          child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 10, bottom: 10),
                              child: Row(
                                children: [
                                  const Icon(Icons.print),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(printerList[index].fullName),
                                ],
                              ))));
                },
                itemCount: printerList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
              ));
  }

  Widget printerUsbConnectWidget() {
    return Column(children: [
      TextField(
        controller: usbDeviceController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: global.language("printer_usb_device"),
        ),
      ),
      const SizedBox(
        height: 10,
      ),
      TextField(
        controller: usbVendorIdController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: global.language("printer_usb_vendor_id"),
        ),
      ),
      const SizedBox(
        height: 10,
      ),
      TextField(
        controller: usbProductIdController,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          labelText: global.language("printer_usb_product_id"),
        ),
      ),
    ]);
  }

  Widget printerIpConnectWidget() {
    return Column(children: [
      TextField(
        controller: ipAddressController,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: global.language("printer_ip_address"),
            hintText: "xxx.xxx.xxx.xxx"),
        readOnly: true,
      ),
      const SizedBox(
        height: 10,
      ),
      TextField(
        controller: portController,
        decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: global.language("printer_ip_port"),
            hintText: "xxxx"),
      ),
    ]);
  }

  Widget printerConnect() {
    List<Widget> displayPrinterConnectWidget = [];
    if (printerSelectedIndex != -1) {
      displayPrinterConnectWidget.add(Text(
          "${global.language("printer_selected")} : ${printerList[printerSelectedIndex].fullName}",
          style: const TextStyle(
              fontSize: 16, color: Colors.blue, fontWeight: FontWeight.bold)));
      displayPrinterConnectWidget.add(const SizedBox(
        height: 10,
      ));
    }
    if (printerConnectType == 1) {
      // Usb Printer
      displayPrinterConnectWidget.add(printerUsbConnectWidget());
    }
    if (printerConnectType == 2) {
      // IP Printer
      displayPrinterConnectWidget.add(printerIpConnectWidget());
    }
    displayPrinterConnectWidget.add(const SizedBox(
      height: 10,
    ));
    displayPrinterConnectWidget.add(Row(children: [
      Text(global.language("printer_paper_size")),
      const SizedBox(width: 10),
      Radio(
          value: 1,
          groupValue: printerPaperSize,
          onChanged: (value) {
            setState(() {
              printerPaperSize = value!;
            });
          }),
      const Text('58mm'),
      const SizedBox(width: 10),
      Radio(
          value: 2,
          groupValue: printerPaperSize,
          onChanged: (value) {
            setState(() {
              printerPaperSize = value!;
            });
          }),
      const Text('80mm'),
    ]));
    displayPrinterConnectWidget.add(const SizedBox(
      height: 10,
    ));
    displayPrinterConnectWidget.add(Row(children: [
      Checkbox(
          value: printBillAuto,
          onChanged: (value) {
            setState(() {
              printBillAuto = value!;
            });
          }),
      const SizedBox(width: 10),
      Text(global.language("printer_print_bill_auto")),
    ]));
    displayPrinterConnectWidget.add(const SizedBox(
      height: 10,
    ));
    displayPrinterConnectWidget.add(ElevatedButton(
        onPressed: () {
          printTest();
          showDialog(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                    title: Text(global.language("printer_connect_test")),
                    content:
                        Text(global.language("printer_connect_test_success")),
                    actions: [
                      ElevatedButton(
                        child: Text(global.language("success")),
                        onPressed: () async {
                          var data = LocalStrongDataModel(
                              printerCashierType: 0,
                              connectType: printerConnectType,
                              ipAddress: ipAddressController.text,
                              ipPort: int.tryParse(portController.text) ?? 0,
                              productName: "",
                              deviceName: "",
                              deviceId: "",
                              manufacturer: "",
                              vendorId: "",
                              productId: "",
                              paperSize: printerPaperSize,
                              printBillAuto: printBillAuto);
                          global.appLocalStore
                              .collection("dedepos")
                              .doc("device")
                              .set(data.toJson())
                              .then((value) {
                            global.loadConfig();
                            Navigator.pop(context);
                            Navigator.pop(context);
                          });
                        },
                      ),
                      ElevatedButton(
                        child: Text(global.language("fail")),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ));
        },
        child: AutoSizeText(
          global.language("printer_connect_test_and_save"),
          maxLines: 1,
          style: const TextStyle(fontSize: 20),
        )));

    return Container(
      padding: const EdgeInsets.only(top: 10),
      width: double.infinity,
      child: (printerConnectType == 0)
          ? printerListWidget()
          : Column(
              children: [
                printerListWidget(),
                const SizedBox(
                  height: 15,
                ),
                Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue),
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(children: displayPrinterConnectWidget)),
                const SizedBox(
                  height: 10,
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(global.language('printer_config')),
          actions: <Widget>[
            IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => getDeviceList()),
          ],
        ),
        body: SingleChildScrollView(
            child: Container(
          padding: const EdgeInsets.all(10),
          width: double.infinity,
          child: printerConnect(),
        )));
  }
}
