import 'package:buddhist_datetime_dateformat_sns/buddhist_datetime_dateformat_sns.dart';
import 'package:dedepos/core/logger/logger.dart';
import 'package:dedepos/core/service_locator.dart';
import 'package:dedepos/model/objectbox/pos_ticket_struct.dart';
import 'package:dedepos/features/pos/presentation/screens/pos_num_pad.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dedepos/db/bank_helper.dart';
import 'package:presentation_displays/display.dart';
import 'package:presentation_displays/displays_manager.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:dedepos/api/network/sync_model.dart';
import 'package:localstore/localstore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:developer' as dev;
import 'dart:io';
import 'package:dart_ping_ios/dart_ping_ios.dart';
import 'package:dedepos/db/bill_detail_extra_helper.dart';
import 'package:dedepos/db/bill_detail_helper.dart';
import 'package:dedepos/db/bill_pay_helper.dart';
import 'package:dedepos/db/employee_helper.dart';
import 'package:dedepos/db/member_helper.dart';
import 'package:dedepos/global_model.dart';
import 'package:dedepos/global.dart' as global;
import 'package:dedepos/model/system/bank_and_wallet_model.dart';
import 'package:dedepos/model/objectbox/bank_struct.dart';
import 'package:dedepos/model/objectbox/member_struct.dart';
import 'package:dedepos/model/json/payment_model.dart';
import 'package:dedepos/model/system/pos_pay_model.dart';
import 'package:dedepos/api/sync/master/sync_master.dart' as sync;
import 'package:dedepos/model/system/printer_model.dart';
import 'package:dedepos/model/objectbox/product_barcode_struct.dart';
import 'package:dedepos/model/objectbox/product_category_struct.dart';
import 'package:dedepos/objectbox.g.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:dedepos/model/objectbox/config_struct.dart';
import 'dart:async';
import 'db/promotion_helper.dart';
import 'db/promotion_temp_helper.dart';
import 'db/product_category_helper.dart';
import 'db/product_barcode_helper.dart';
import 'db/pos_log_helper.dart';
import 'db/bill_helper.dart';
import 'db/config_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:charset_converter/charset_converter.dart';
import 'model/json/language_model.dart';

DisplayManager displayManager = DisplayManager();
bool isInternalCustomerDisplayConnected = false;
late Display internalCustomerDisplay;
var httpClient = http.Client();
late BuildContext globalContext;
void posProcessRefresh = () {};
String ipAddress = "";
List<String> errorMessage = [];
List<InformationModel> informationList = <InformationModel>[];
bool initSuccess = false;
late List<LanguageSystemCodeModel> languageSystemCode;
late String pathApplicationDocumentsDirectory;
List<PosHoldProcessModel> posHoldProcessResult = [];
int posHoldActiveNumber = 0;
ProductCategoryHelper productCategoryHelper = ProductCategoryHelper();
ProductBarcodeHelper productBarcodeHelper = ProductBarcodeHelper();
MemberHelper memberHelper = MemberHelper();
EmployeeHelper employeeHelper = EmployeeHelper();
PosLogHelper posLogHelper = PosLogHelper();
BillHelper billHelper = BillHelper();
BillDetailHelper billDetailHelper = BillDetailHelper();
BillDetailExtraHelper billDetailExtraHelper = BillDetailExtraHelper();
BillPayHelper billPayHelper = BillPayHelper();
ConfigHelper configHelper = ConfigHelper();
PromotionHelper promotionHelper = PromotionHelper();
PromotionTempHelper promotionTempHelper = PromotionTempHelper();
int syncTimeIntervalMaxBySecond = 10;
int syncTimeIntervalSecond = 1;
final moneyFormat = NumberFormat("##,##0.##");
final qtyShortFormat = NumberFormat("##,##0");
String objectBoxDatabaseName = "smlposmobile.db";
String deviceId = "POS01";
String deviceName = "เครื่อง POS สำนักงานใหญ่ 1";
List<SyncDeviceModel> customerDisplayDeviceList = [];
List<SyncDeviceModel> posRemoteDeviceList = [];
//"http://192.168.1.4:8084";
String webServiceUrl = "http://smltest1.ddnsfree.com:8084";
String webServiceVersion = "/SMLJavaWebService/webresources/rest/";
String providerName = "DATA";
String databaseName = "DEMO"; // "DATA1 or DEMO";
bool speechToTextVisible = false;
bool loginSuccess = false;
GetStorage appStorage = GetStorage('AppStorage');
Localstore appLocalStore = Localstore.instance;
late LocalStrongDataModel appLocalStrongData;
bool firstSync = false;
bool loginProcess = false;
bool syncDataSuccess = false;
bool syncDataProcess = false;
PosPayModel payScreenData = PosPayModel();
bool lugenPaymentProvider = true;
List<PaymentProviderModel> lugenPaymentProviderList = [];
List<PaymentProviderModel> qrPaymentProviderList = [];
bool payScreenNumberPadIsActive = false;
double payScreenNumberPadLeft = 100;
double payScreenNumberPadTop = 100;
String payScreenNumberPadText = "";
double payScreenNumberPadAmount = 0;
PayScreenNumberPadWidgetEnum payScreenNumberPadWidget = PayScreenNumberPadWidgetEnum.number;
VoidCallback numberPadCallBack = () {};
String? userLanguage;
String userLoginCode = "001";
String userLoginName = "สมชาย";
String employeeLogin = "";
String employeeLoginName = "";
int machineNumber = 1;
String selectTableCode = "";
String selectTableGroup = "";
ThemeStruct posTheme = ThemeStruct();
GlobalKey<PosNumPadState> posNumPadProductWeightGlobalKey = GlobalKey();
bool transDisplayImage = true;
List<ProductCategoryObjectBoxStruct> productCategoryCodeSelected = [];
List<ProductCategoryObjectBoxStruct> productCategoryList = [];
List<ProductBarcodeObjectBoxStruct> productListByCategory = [];
List<ProductCategoryObjectBoxStruct> productCategoryChildList = [];
List<PrinterModel> printerList = [];
String cashierPrinterCode = 'E2'; // เครื่องพิมพ์สำหรับพิมพ์บิล
String tablePrinterCode = 'E3'; // เครื่องพิมพ์สำหรับพิมพ์โต๊/ปิดโต๊
String orderSummeryPrinterCode = "E1"; // ใบสรุปรายการสั่งอาหาร
AppModeEnum appMode = AppModeEnum.posTerminal;
bool apiConnected = false;
String apiUserName = ""; //maxkorn
String apiUserPassword = ""; //maxkorn
String apiShopID = ""; //2Eh6e3pfWvXTp0yV3CyFEhKPjdI
bool syncRefreshProductCategory = true;
bool syncRefreshProductBarcode = true;
bool syncRefreshPrinter = true;
String syncDateBegin = "2000-01-01T00:00:00";
String syncCategoryTimeName = "lastSyncCategory";
String syncProductBarcodeTimeName = "lastSyncProductBarcode";
String syncPrinterTimeName = "lastSyncPrinter";
String syncInventoryTimeName = "lastSyncInventory";
String syncMemberTimeName = "lastSyncMember";
String syncEmployeeTimeName = "lastSyncEmployee";
String syncBankTimeName = "lastSyncBank";
String syncTableTimeName = "lastSyncTable";
String syncTableZoneTimeName = "lastSyncTableZone";
String syncDeviceTimeName = "lastSyncDevice";
bool isOnline = false;
MemberObjectBoxStruct? userData;
PaymentModel? paymentData;
late Store objectBoxStore;
String dateFormatSync = "yyyy-MM-ddTHH:mm:ss";
PosVersionEnum posVersion = PosVersionEnum.vfpos;
PrinterCashierTypeEnum printerCashierType = PrinterCashierTypeEnum.thermal;
PrinterCashierConnectEnum printerCashierConnect = PrinterCashierConnectEnum.ip;
String printerCashierIpAddress = "";
int printerCashierIpPort = 9100;
bool customerDisplayDesktopMultiScreen = true;
String targetDeviceIpAddress = "";
int targetDeviceIpPort = 4040;
bool targetDeviceConnected = false;
Function? functionPosScreenRefresh;
DeviceModeEnum deviceMode = DeviceModeEnum.none;
PosScreenNewDataStyleEnum posScreenNewDataStyle = PosScreenNewDataStyleEnum.addLastLine;
DisplayMachineEnum displayMachine = DisplayMachineEnum.posTerminal;
PosTicketObjectBoxStruct posTicket = PosTicketObjectBoxStruct();
PosScreenModeEnum posScreenMode = PosScreenModeEnum.posSale;
bool posUseSaleType = true; // ใช้ประเภทการขายหรือไม่
String posSaleChannelCode = "XXX"; // XXX=หน้าร้าน
String posSaleChannelLogoUrl = "";

List<PosSaleChannelModel> posSaleChannelList = [];

enum PrinterCashierTypeEnum { thermal, dot, laser, inkjet }

enum PrinterCashierConnectEnum { ip, bluetooth, usb, serial, sunmi1 }

enum PosVersionEnum { pos, restaurant, vfpos }

enum SoundEnum { beep, fail, buttonTing }

enum DisplayMachineEnum { customerDisplay, posTerminal }

enum PosScreenModeEnum { posSale, posReturn }

enum AppModeEnum {
  // posTerminal = โปรแกรมที่ใช้งานได้เฉพาะเครื่อง POS เท่านั้น
  // posRemote = โปรแกรมที่ใช้งานได้ทุกเครื่อง และสามารถส่งคำสั่งไปยังเครื่อง POS ได้
  posTerminal,
  posRemote
}

enum PosScreenNewDataStyleEnum {
  // newLineOnly = ขึ้นบรรทัดใหม่เสมอ
  // addLastLine = ถ้า Barcode เดิม ให้เพิ่มในรายการล่าสุด
  // addAllLine = ถ้า Barcode เดิ่ม ให้เพิ่มในรายการทั้งหมด
  newLineOnly,
  addLastLine,
  addAllLine
}

enum DeviceModeEnum {
  none,
  iphone,
  ipad,
  windowsDesktop,
  macosDesktop,
  linuxDesktop,
  androidPhone,
  androidTablet,
}

int posScreenToInt() {
  switch (posScreenMode) {
    case PosScreenModeEnum.posSale:
      return 1;
    case PosScreenModeEnum.posReturn:
      return 2;
    default:
      return 0;
  }
}

Future<Position> determinePosition() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error('Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

bool isPhoneDevice() {
  return deviceMode == DeviceModeEnum.iphone || deviceMode == DeviceModeEnum.androidPhone;
}

bool isTabletDevice() {
  return deviceMode == DeviceModeEnum.ipad || deviceMode == DeviceModeEnum.androidTablet;
}

Future<void> getDeviceModel(BuildContext context) async {
  final deviceInfo = DeviceInfoPlugin();
  String model = '';

  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    model = androidInfo.model;
    var shortestSide = MediaQuery.of(context).size.shortestSide;
    if (shortestSide > 600) {
      deviceMode = DeviceModeEnum.androidTablet;
    } else {
      deviceMode = DeviceModeEnum.androidPhone;
    }
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    model = iosInfo.model!;
    model = model.toLowerCase();
    if (model.contains("iphone")) {
      deviceMode = DeviceModeEnum.iphone;
    } else if (model.contains("ipad")) {
      deviceMode = DeviceModeEnum.ipad;
    }
  } else if (Platform.isMacOS) {
    deviceMode = DeviceModeEnum.macosDesktop;
  } else if (Platform.isLinux) {
    deviceMode = DeviceModeEnum.linuxDesktop;
  } else if (Platform.isWindows) {
    deviceMode = DeviceModeEnum.windowsDesktop;
  }
}

void themeSelect(int mode) {
  switch (mode) {
    case 1:
      posTheme.background = Colors.cyan.shade50;
      posTheme.productLevelBackground = Colors.cyan.shade50;
      posTheme.productBottomBackground = Colors.cyan.shade100;
      posTheme.productLevelRootBackground = Colors.cyan.shade100;
      posTheme.productLevelRootBottomBackground = Colors.cyan.shade200;
      posTheme.transBackground = Colors.white;
      posTheme.transSelectedBackground = Colors.cyan.shade50;
      posTheme.transPayBottomBackground = Colors.cyan.shade500;
      posTheme.transPayBottomDisableBackground = Colors.cyan.shade100;
      break;
    case 2:
      // Colors new layout
      posTheme.background = const Color(0xFF001E40);
      posTheme.orange1 = const Color(0xFFE27D01);
      posTheme.secondary = const Color(0xFFE89100);
      posTheme.transSelectedBackground = Colors.cyan.shade50;
      posTheme.transBackground = Colors.white;
      break;
  }
}

String formatDoubleTrailingZero(double value) {
  return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
}

Future<Uint8List> thaiEncode(String word) async {
  if (Platform.isWindows) {
    try {
      if (word == "") {
        word = " ";
      }
      return await CharsetConverter.encode('windows-874', word);
    } catch (e) {
      return await CharsetConverter.encode('windows-874', " ");
    }
  } else {
    return await CharsetConverter.encode('TIS620', word);
  }
}

void playSound({SoundEnum sound = SoundEnum.beep, String word = ""}) async {
  /*audioPlayer = AudioPlayer();
  try {
    if (speechToTextVisible && word.isNotEmpty) {
      if (Platform.isAndroid || Platform.isIOS) {
        TextToSpeech tts = TextToSpeech();
        tts.setRate(1);
        tts.speak(word);
      }
    } else {
      switch (sound) {
        case SoundEnum.beep:
          if (Platform.isAndroid || Platform.isIOS) {
            FlutterBeep.beep();
          } else {
            if (Platform.isWindows) {
              playSoundForWindows('scan_success.wav');
            }
          }
          break;
        case SoundEnum.fail:
          if (Platform.isAndroid || Platform.isIOS) {
            FlutterBeep.beep();
          } else {
            if (Platform.isWindows) {
              playSoundForWindows('scan_fail.wav');
            }
          } /*audio8851959003374
            
              .setAsset('assets/audios/scan_fail.wav')95509747

              .then((value) => audio.play());*/
          break;
        case SoundEnum.buttonTing:
          if (Platform.isAndroid || Platform.isIOS) {
            FlutterBeep.beep();
          } else {
            if (Platform.isWindows) {
              playSoundForWindows('button_ting.wav');
            }
          }
          break;
      }
    }
  } catch (e) {
    print(e);
  }*/
}

String imageUrl(String guid) {
  return '$webServiceUrl/SMLJavaWebService/webresources/image/$guid?p=$providerName&d=$databaseName';
}

class Debounce {
  final int? milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debounce(this.milliseconds);

  run(VoidCallback action) {
    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(milliseconds: milliseconds!), action);
  }
}

List<String> wordSplit(String word) {
  List<String> split = [];
  String firstBreak = "ใโไเแ";
  String endBreak = "าๆฯะ";
  for (int index = 0; index < firstBreak.length; index++) {
    word = word.replaceAll(firstBreak[index], " ${firstBreak[index]}");
  }
  for (int index0 = 0; index0 < endBreak.length; index0++) {
    word = word.replaceAll(endBreak[index0], "${endBreak[index0]} ");
  }
  split = word.split(" ");
  return split;
}

double calcTextToNumber(String text) {
  double result = 0;
  String textTrim = text.trim();
  while (textTrim.contains(" ")) {
    textTrim = textTrim.replaceAll(" ", "");
  }
  if (textTrim.isNotEmpty) {
    textTrim = textTrim.replaceAll("X", "").replaceAll("x", "").replaceAll("+", "").replaceAll("-", "");
    result = double.parse(textTrim);
  }
  return result;
}

Future<String> billRunning() async {
  // Format : DEVICE-DATE-#####
  String dateNow = DateFormat('yyMMdd').format(DateTime.now());
  String result = "";
  bool success = false;
  while (success == false) {
    int number = 0;
    List<ConfigObjectBoxStruct> configGet = configHelper.select();
    if (configGet.isNotEmpty) {
      ConfigObjectBoxStruct config = configGet[0];
      List<String> split = config.last_doc_number.split("-");
      if (split.isNotEmpty) {
        number = int.tryParse(split[split.length - 1]) ?? 0;
        if (split.length > 1) {
          String date = split[1];
          if (date != dateNow) {
            number = 0;
          }
        }
      }
    }
    result = "${global.deviceId}-$dateNow-${(NumberFormat("00000")).format(number + 1)}";

    /// ค้นหาว่ามีเลขที่เอกสารนี้อยู่ในฐานข้อมูลหรือไม่
    var find = billHelper.selectByDocNumber(docNumber: result, posScreenMode: global.posScreenToInt());
    if (find == null) {
      success = true;
    } else {
      configHelper.update(ConfigObjectBoxStruct(device_id: global.deviceId, last_doc_number: result));
    }
  }
  return result;
}

Future<bool> hasNetwork() async {
  try {
    final result = await InternetAddress.lookup('example.com');
    final returnResult = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    return returnResult;
  } on SocketException catch (_) {
    return false;
  }
}

void showAlertDialog({required BuildContext context, required String title, required String message}) {
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      okButton,
    ],
  );
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

/*void printQueue(PrinterStruct printer) async {
  bool _loopPrint = true;
  while (_loopPrint) {
    List<PrintQueueStruct> _queueList = await PrintQueueHelper()
        .select(where: "printer_code='" + printer.code + "'");
    if (_queueList.isNotEmpty) {
      dev.log(printer.ip_address);
      for (var _queue in _queueList) {
        switch (_queue.code) {
          case 1:
            // Print Bill
            await printBill(
                docNo: _queue.doc_number, ipAddress: printer.ip_address);
            break;
          case 2:
            // Print Bill
            await printSendMoney(
                docNo: _queue.doc_number, ipAddress: printer.ip_address);
            break;
          case 3:
            // Receive Money
            await printReceiveMoney(
                docNo: _queue.doc_number, ipAddress: printer.ip_address);
            break;
          case 8:
            // Print Order To Kitchen (สั่งพิมพ์ครัว)
            await printOrderToKitchen(
                docNo: _queue.doc_number,
                lineNumber: _queue.line_number,
                ipAddress: "192.168.2.244");
            break;
          case 9:
            // Print Order Summery (สั่งพิมพ์ใบสรุป)
            await printOrderSummery(
                docNo: _queue.doc_number, ipAddress: printer.ip_address);
            break;
          case 10:
            // ใบเปิดโต๊ะ
            await printTableOpen(
                guid: _queue.doc_number, ipAddress: printer.ip_address);
            break;
        }
        await PrintQueueHelper().deleteById(_queue.guid);
      }
    } else
      _loopPrint = false;
  }
}*/

/*Future<void> printQueueStart() async {
  for (var _printer in printerList) {
    if (_printer.is_run_thread == false) {
      _printer.is_run_thread = true;
      printQueue(_printer);
      _printer.is_run_thread = false;
    }
  }
}*/

Future<void> printQueueStartServer() async {
  var url = "http://$targetDeviceIpAddress:$targetDeviceIpPort";
  var uri = Uri.parse(url);
  try {
    http.Response response = await http
        .post(uri,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(HttpPost(command: 'print_queue')))
        .timeout(const Duration(seconds: 2));
    if (response.statusCode == 200) {
      dev.log('Success');
    }
  } catch (e) {
    dev.log('failed : $e');
  }
}

String dateTimeFormat(DateTime dateTime, {bool showTime = true}) {
  var formatter = DateFormat.yMMMMEEEEd('th_TH');
  if (showTime) {
    return "${formatter.formatInBuddhistCalendarThai(dateTime)} - ${DateFormat.Hm().format(dateTime)}";
  } else {
    return formatter.formatInBuddhistCalendarThai(dateTime);
  }
}

Future<void> systemProcess() async {
  for (int index = 0; index < customerDisplayDeviceList.length; index++) {
    var url = "${customerDisplayDeviceList[index].ip}:5041";
    SyncDeviceModel info = SyncDeviceModel(device: deviceId, ip: "", holdNumberActive: 0, docModeActive: 0, connected: true, isClient: false, isCashierTerminal: false);
    var jsonData = HttpPost(command: "info", data: jsonEncode(info.toJson()));
    postToServer(
        ip: url,
        jsonData: jsonEncode(jsonData.toJson()),
        callBack: (value) {
          if (value.isNotEmpty) {
            try {
              SyncDeviceModel getInfo = SyncDeviceModel.fromJson(jsonDecode(value));
              customerDisplayDeviceList[index].connected = getInfo.connected;
            } catch (e) {
              serviceLocator<Log>().error(e);
            }
          }
        });
  }
}

Future<void> sendProcessToCustomerDisplay() async {
  for (int index = 0; index < customerDisplayDeviceList.length; index++) {
    if (customerDisplayDeviceList[index].connected) {
      var url = "${customerDisplayDeviceList[index].ip}:5041";
      try {
        var jsonData = HttpPost(command: "process", data: jsonEncode(posHoldProcessResult[posHoldActiveNumber].toJson()));
        dev.log("sendProcessToCustomerDisplay : $url");
        postToServer(ip: url, jsonData: jsonEncode(jsonData.toJson()), callBack: (value) {});
      } catch (e) {
        serviceLocator<Log>().error("$e : $url");
      }
    }
  }
  if (Platform.isAndroid && displayMachine == DisplayMachineEnum.posTerminal && isInternalCustomerDisplayConnected == true) {
    // Send to จอสอง
    displayManager.transferDataToPresentation(jsonEncode(posHoldProcessResult[posHoldActiveNumber].toJson()));
  }
}

Future<void> sendProcessToRemote() async {
  for (int index = 0; index < posRemoteDeviceList.length; index++) {
    if (posRemoteDeviceList[index].connected) {
      var url = "${posRemoteDeviceList[index].ip}:$targetDeviceIpPort";
      try {
        var jsonData = HttpPost(command: "process_result", data: jsonEncode(posHoldProcessResult[posRemoteDeviceList[index].holdNumberActive].toJson()));
        postToServer(ip: url, jsonData: jsonEncode(jsonData.toJson()), callBack: (_) {});
      } catch (e) {
        serviceLocator<Log>().error("$e : $url");
      }
    }
  }
}

double calcDiscountFormula({required double totalAmount, required String discountText}) {
  double sumDiscount = 0.0;
  List<String> split = discountText.trim().replaceAll(" ", "").replaceAll(" ", "").split(",");
  for (int index = 0; index < split.length; index++) {
    String discount = split[index];
    double result = 0.0;
    if (discount.contains("%")) {
      // ลด %
      double? percent = double.tryParse(discount.replaceAll("%", ""));
      if (percent != null) {
        result = totalAmount * (percent / 100);
        sumDiscount += result;
        totalAmount -= result;
      }
    } else {
      // ลด จำนวนเงิน
      double? discountMoney = double.tryParse(discount);
      if (discountMoney != null) {
        sumDiscount += discountMoney;
        totalAmount -= discountMoney;
      }
    }
  }
  return sumDiscount;
}

Future<void> createLogoImageFromBankProvider() async {
  List<BankObjectBoxStruct> bankDataList = BankHelper().selectAll();
  for (var element in bankDataList) {
    if (element.logo != "") {
      String base64 = element.logo.replaceFirst("data:image/png;base64,", "");
      Uint8List bytes = base64Decode(base64);
      File file = File("$pathApplicationDocumentsDirectory/bank${element.code.toLowerCase()}.png");
      file.writeAsBytes(bytes);
    }
  }
}

String findLogoImageFromCreditCardProvider(String code) {
  return "$pathApplicationDocumentsDirectory/bank${code.toLowerCase()}.png";
}

String language(String code) {
  String result = "";
  int left = 0;
  int right = languageSystemCode.length - 1;

  while (left <= right) {
    int middle = (left + right) ~/ 2;
    int comparison = languageSystemCode[middle].code.compareTo(code);

    if (comparison == 0) {
      int langLeft = 0;
      int langRight = languageSystemCode[middle].langs.length - 1;

      while (langLeft <= langRight) {
        int langMiddle = (langLeft + langRight) ~/ 2;
        int langComparison = languageSystemCode[middle].langs[langMiddle].code.compareTo(userLanguage ?? 'th');

        if (langComparison == 0) {
          result = languageSystemCode[middle].langs[langMiddle].text;
          break;
        } else if (langComparison < 0) {
          langLeft = langMiddle + 1;
        } else {
          langRight = langMiddle - 1;
        }
      }
      break;
    } else if (comparison < 0) {
      left = middle + 1;
    } else {
      right = middle - 1;
    }
  }

  if (result.trim().isEmpty) {
    dev.log(code);
  }
  return (result.trim().isEmpty) ? code : result;
}

Color colorFromHex(String hexColor) {
  final hexCode = hexColor.replaceAll('#', '');
  return Color(int.parse('FF$hexCode', radix: 16));
}

String posScreenListHeightName = "posScreenListHeight";
double posScreenListHeightGet() {
  return appStorage.read(posScreenListHeightName) ?? 1.0;
}

void posScreenListHeightSet(double value) {
  appStorage.write(posScreenListHeightName, value);
}

void loadConfig() {
  appLocalStrongData = LocalStrongDataModel();
  try {
    appLocalStore.collection("dedepos").doc("device").get().then((value) {
      try {
        appLocalStrongData = LocalStrongDataModel.fromJson(jsonDecode(jsonEncode(value)));
      } catch (_) {}
      {
        // ประเภทเครื่องพิมพ์ Cashier
        switch (appLocalStrongData.printerCashierType) {
          case 0:
            printerCashierType = PrinterCashierTypeEnum.thermal;
            break;
          case 1:
            printerCashierType = PrinterCashierTypeEnum.dot;
            break;
          case 2:
            printerCashierType = PrinterCashierTypeEnum.laser;
            break;
          case 3:
            printerCashierType = PrinterCashierTypeEnum.inkjet;
            break;
        }
      }
      {
        // การเชื่อมต่อเครื่องพิมพ์ Cashier
        switch (appLocalStrongData.connectType) {
          case 0:
            printerCashierConnect = PrinterCashierConnectEnum.ip;
            break;
          case 1:
            printerCashierConnect = PrinterCashierConnectEnum.bluetooth;
            break;
          case 3:
            printerCashierConnect = PrinterCashierConnectEnum.usb;
            break;
          case 100:
            printerCashierConnect = PrinterCashierConnectEnum.sunmi1;
            break;
        }
      }
      {
        printerCashierIpAddress = appLocalStrongData.ipAddress;
        printerCashierIpPort = appLocalStrongData.ipPort;
      }
    });
  } catch (e) {
    dev.log(e.toString());
  }
}

Future<void> registerRemoteToTerminal() async {
  if (appMode == AppModeEnum.posRemote) {
    var url = "http://$targetDeviceIpAddress:$targetDeviceIpPort?uuid=${const Uuid().v4()}";
    var uri = Uri.parse(url);
    try {
      SyncDeviceModel sendData =
          SyncDeviceModel(device: "XXX", ip: ipAddress, holdNumberActive: posHoldActiveNumber, docModeActive: 0, connected: true, isCashierTerminal: false, isClient: true);
      var jsonEncodeStr = jsonEncode(sendData.toJson());
      await http
          .post(uri,
              headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
              },
              body: jsonEncode(<String, String>{
                'command': 'register_remote_device',
                'data': jsonEncodeStr,
              }))
          .timeout(const Duration(seconds: 1))
          .then((response) {});
    } catch (_) {}
  }
}

/// Loading System
/// - _global:loadConfig
/// - Add qrPaymentProviderList
/// - register DartPingIOS
/// - setupObjectBox (core/objectbox.dart)
/// - register sync master
/// - สร้าง Process Result ตามจำนวน Hold บิล (global.generatePosHoldProcess)
Future<void> startLoading() async {
  {
    serviceLocator<Log>().debug("Start Loading... POS Screen ");
    loadConfig();
    // Payment
    qrPaymentProviderList.add(PaymentProviderModel(
      providercode: "",
      paymentcode: "promptpay",
      bookbankcode: "001",
      paymentlogo: "",
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "Prompt Pay", use: true)],
      countrycode: "TH",
      paymenttype: 1,
      feeRate: 0.0,
      wallettype: 101,
    ));
    // Lugen
    lugenPaymentProviderList.add(PaymentProviderModel(
      providercode: "LUGEN",
      paymentcode: "promptpay",
      bookbankcode: "002",
      paymentlogo: "",
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "Prompt Pay", use: true)],
      countrycode: "TH",
      paymenttype: 20,
      feeRate: 0.0,
      wallettype: 201,
    ));
    lugenPaymentProviderList.add(PaymentProviderModel(
      providercode: "LUGEN",
      paymentcode: "truemoney",
      bookbankcode: "002",
      paymentlogo: "",
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "True Money", use: true)],
      countrycode: "TH",
      paymenttype: 1,
      feeRate: 0.0,
      wallettype: 202,
    ));
    lugenPaymentProviderList.add(PaymentProviderModel(
      providercode: "LUGEN",
      bookbankcode: "002",
      paymentcode: "linepay",
      paymentlogo: "",
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "Line Pay", use: true)],
      countrycode: "TH",
      paymenttype: 1,
      feeRate: 0.0,
      wallettype: 203,
    ));
    lugenPaymentProviderList.add(PaymentProviderModel(
      providercode: "LUGEN",
      bookbankcode: "002",
      paymentcode: "alipay",
      paymentlogo: "",
      names: [LanguageModel(code: "th", codeTranslator: "th", name: "Alipay", use: true)],
      countrycode: "TH",
      paymenttype: 1,
      feeRate: 0.0,
      wallettype: 204,
    ));
  }
  //WidgetsFlutterBinding.ensureInitialized();
  //await GetStorage.init();

  //Widget _defaultHome = new PrinterConfigScreen();

  /*bool result = await appAuth.login();
  if (result) {
    //_defaultHome = new MenuScreen();
  }*/

  DartPingIOS.register();

  // objectbox
  // move to after login & Select shop
  // await setupObjectBox();

  int xxx = ProductBarcodeHelper().count();
  serviceLocator<Log>().debug("ProductBarcodeHelper().count() $xxx");
  //global.objectBoxStore =Store(getObjectBoxModel(), directory: value.path + '/xobjectbox');
  //global.objectBoxStore = await openStore(maxDBSizeInKB: 102400);
  {
    /// Sync Master (ข้อมูลหลัก)
    int syncMasterSecondCount = 0;

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (loginSuccess && syncDataProcess == false) {
        //log('Sync Data Master : ' + DateTime.now().toString());
        syncMasterSecondCount++;
        if (syncMasterSecondCount > syncTimeIntervalSecond) {
          sync.syncMasterProcess();
          syncTimeIntervalSecond = syncTimeIntervalSecond * 2;
          if (syncTimeIntervalSecond > syncTimeIntervalMaxBySecond) {
            syncTimeIntervalSecond = syncTimeIntervalMaxBySecond;
          }
          syncMasterSecondCount = 0;
        }
      }
    });
  }
  Timer.periodic(const Duration(seconds: 1), (timer) async {
    if (loginSuccess) {
      systemProcess();
      registerRemoteToTerminal();
    }
  });

  generatePosHoldProcess();
  pathApplicationDocumentsDirectory = (await getApplicationDocumentsDirectory()).path;

  initSuccess = true;
}

/// สร้าง Process Result ตามจำนวน Hold บิล
void generatePosHoldProcess() {
  for (int loop = 0; loop < 50; loop++) {
    posHoldProcessResult.add(PosHoldProcessModel(holdNumber: loop));
  }
}

Future<String> getFromServer({required String json}) async {
  final base64String = base64Encode(utf8.encode(json));
  // String url = "$httpServerIp:$httpServerPort?data=$base64String";

  String url = "$targetDeviceIpAddress:$targetDeviceIpPort";
  final response =
      await httpClient.get(Uri.http(url, '/', {'json': base64String}), headers: {"Content-Type": "application/json", "Cache-Control": "no-cache", "Accept": "text/event-stream"});
  if (response.statusCode == 200) {
    return response.body;
  } else {
    throw Exception('Failed to load data');
  }
}

Future<void> postToServer({required String ip, required String jsonData, required Function callBack}) async {
  String result = "";
  try {
    var request = http.Request("POST", Uri.parse("http://$ip"));
    request.headers["Content-Type"] = "application/json";
    request.headers["Cache-Control"] = "no-cache";
    request.headers["Accept"] = "text/event-stream";
    request.body = jsonData;
    // wait for the response
    httpClient.send(request).then((value) {
      value.stream.listen((data) {
        result = utf8.decode(data);
        callBack(result);
      }, onError: (e, s) {});
    });
  } catch (e) {
    serviceLocator<Log>().error("sendToServer : $e");
  }
}

Future<String> postToServerAndWait({required String ip, required String jsonData}) async {
  String result = "";
  try {
    var request = http.Request("POST", Uri.parse("http://$ip"));
    request.headers["Content-Type"] = "application/json";
    request.headers["Cache-Control"] = "no-cache";
    request.headers["Accept"] = "text/event-stream";
    request.body = jsonData;
    // wait for the response
    var value = await httpClient.send(request);
    if (value.statusCode == 200) {
      result = utf8.decode(await value.stream.toBytes());
    }
  } catch (e) {
    serviceLocator<Log>().error("sendToServer : $e");
  }
  return result;
}

void openCashDrawer() async {
  PaperSize paper = PaperSize.mm80;
  CapabilityProfile profile = await CapabilityProfile.load();
  NetworkPrinter printer = NetworkPrinter(paper, profile);

  try {
    PosPrintResult res = await printer.connect(printerCashierIpAddress, port: printerCashierIpPort);
    if (res == PosPrintResult.success) {
      printer.drawer();
      printer.disconnect();
    }
  } catch (e) {
    serviceLocator<Log>().error(e);
  }
}

String getImageForTest() {
  List<String> images = [
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/cokecan_1024x1024@2x.png?v=1586878773',
    '',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/c3ef1fb0352b565a9b710dc50b9790c8_1024x1024@2x.jpg?v=1588397618',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/green_cross_500ml_1024x1024@2x.jpg?v=1590209308',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/1MGpbJWKQ_Mha_cHowinO9xm7gNpK6Jnk_1024x1024@2x.jpg?v=1586007533',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/40456_1024x1024@2x.jpg?v=1587914211',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/15464fbbc5eb8baa71425d9c2ed97ea7_1024x1024@2x.jpg?v=1588397501',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/251_FIT_N__RIGHT_FOUR_SEASONS_330ML_1024x1024@2x.jpg?v=1586836584',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/nestle_ice_cream_oreo_cone_1_1024x1024@2x.jpg?v=1587117184',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/1ts9iXyMxStMrVq_md9dNcYw3PtHxwqtq_1024x1024@2x.png?v=1585991136',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/faa22afb6b279e9a57ac6756d7100c5a_medium_96b3c449-e5c9-4b18-909f-16089453972a_360x.png?v=1587173843',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/VITAMILKCHOCOSHAKE300ML-500x500_1024x1024@2x.jpg?v=1586880107',
    'https://cdn.shopify.com/s/files/1/0280/7126/4308/products/unnamed_1024x1024@2x.jpg?v=1587129692'
  ];
  return images[Random().nextInt(images.length)];
}

Future<String> getIpAddress() async {
  // Get a list of the network interfaces available on the device
  List<NetworkInterface> interfaces = await NetworkInterface.list();

  // Iterate through the list of interfaces and return the first non-loopback IPv4 address
  for (NetworkInterface interface in interfaces) {
    if (interface.name == 'lo') continue; // Skip the loopback interface
    for (InternetAddress address in interface.addresses) {
      if (address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }

  // If no non-loopback IPv4 address was found, return null
  return "";
}

Future scanServerByName(String name) async {
  List<SyncDeviceModel> ipList = [];
  String ipAddress = await getIpAddress();
  String subNet = ipAddress.substring(0, ipAddress.lastIndexOf("."));
  for (int i = 1; i < 255; i++) {
    String ip = "$subNet.$i";
    ipList.add(SyncDeviceModel(device: "", ip: ip, holdNumberActive: 0, docModeActive: 0, connected: false, isClient: false, isCashierTerminal: false));
  }
  int countTread = 0;
  bool loopScan = true;
  while (loopScan) {
    await Future.delayed(const Duration(seconds: 1));
    for (int index = 0; index < ipList.length; index++) {
      if (!ipList[index].connected) {
        if (countTread < 10) {
          countTread++;
          String url = "http://${ipList[index].ip}:$targetDeviceIpPort/scan?uuid=${const Uuid().v4()}";
          try {
            http.post(Uri.parse(url)).timeout(const Duration(seconds: 1)).then((result) {
              countTread--;
              if (result.statusCode == 200) {
                if (result.body.isNotEmpty) {
                  serviceLocator<Log>().debug("Connected to ${ipList[index].ip}");
                  SyncDeviceModel server = SyncDeviceModel.fromJson(jsonDecode(result.body));
                  if (server.device == name && server.isCashierTerminal) {
                    ipList[index].connected = true;
                    loopScan = false;
                    targetDeviceIpAddress = ipList[index].ip;
                    targetDeviceConnected = true;
                  }
                }
              }
            }).onError((error, stackTrace) {
              countTread--;
            }).catchError((error) {
              countTread--;
            }).whenComplete(() {
              countTread--;
            });
          } catch (_) {
            countTread--;
          }
        } else {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
  }
}

bool isTabletScreen() {
  return (deviceMode == DeviceModeEnum.androidTablet || deviceMode == DeviceModeEnum.ipad);
}

bool isDesktopScreen() {
  return (deviceMode == DeviceModeEnum.macosDesktop || deviceMode == DeviceModeEnum.linuxDesktop || deviceMode == DeviceModeEnum.windowsDesktop);
}

String syncFindLastUpdate(List<SyncMasterStatusModel> dataList, String tableName) {
  for (var item in dataList) {
    if (item.tableName == tableName) {
      return DateFormat(dateFormatSync).format(DateTime.parse(item.lastUpdate));
    }
  }
  return DateFormat(dateFormatSync).format(DateTime.parse(syncDateBegin));
}

void testPrinterConnect() async {
  if (printerList.isNotEmpty) {
    for (var printer in printerList) {
      try {
        final Socket socket = await Socket.connect(printer.printer_ip_address, printer.printer_port, timeout: const Duration(seconds: 5));
        printer.is_ready = true;
        socket.destroy();
      } catch (e) {
        serviceLocator<Log>().error(e.toString());
        printer.is_ready = false;
        errorMessage.add("${language("printer")} : ${printer.name}/${printer.printer_ip_address}:${printer.printer_port} ${language("not_ready")} $e");
      }
    }
  }
}
