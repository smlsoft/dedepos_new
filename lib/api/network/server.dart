import "dart:developer" as dev;
import 'package:dedepos/api/network/sync_model.dart';
import 'package:dedepos/core/core.dart';
import 'package:dedepos/db/pos_log_helper.dart';
import 'package:dedepos/global_model.dart';
import 'package:dedepos/model/objectbox/pos_log_struct.dart';
import 'package:dedepos/model/objectbox/product_barcode_struct.dart';
import 'package:dedepos/model/objectbox/product_category_struct.dart';
import 'package:dedepos/model/objectbox/staff_client_struct.dart';
import 'package:dedepos/objectbox.g.dart';
import 'package:dedepos/features/pos/presentation/screens/pos_process.dart';
import 'package:dedepos/util/pos_compile_process.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:dedepos/db/product_barcode_helper.dart';
import 'package:dedepos/global.dart' as global;
import 'package:dedepos/util/network.dart' as network;

Future<void> startServer() async {
  global.ipAddress = await network.ipAddress();
  if (global.ipAddress.isNotEmpty) {
    network.connectivity();
    global.targetDeviceIpAddress = global.ipAddress;
    var server =
        await HttpServer.bind(global.ipAddress, global.targetDeviceIpPort);
    dev.log(
        "Server running on IP : ${server.address} On Port : ${server.port}");
    await for (HttpRequest request in server) {
      try {
        if (global.loginSuccess) {
          var contentType = request.headers.contentType;
          var response = request.response;
          if (request.method == 'GET') {
            String json = request.uri.query.split("json=")[1];
            HttpGetDataModel httpGetData = HttpGetDataModel.fromJson(
                jsonDecode(utf8.decode(base64Decode(json))));
            switch (httpGetData.code) {
              case "get_all_category":
                List<ProductCategoryObjectBoxStruct> boxData = global
                    .objectBoxStore
                    .box<ProductCategoryObjectBoxStruct>()
                    .getAll();
                response
                    .write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
                break;
              case "get_all_barcode":
                List<ProductBarcodeObjectBoxStruct> boxData = global
                    .objectBoxStore
                    .box<ProductBarcodeObjectBoxStruct>()
                    .getAll();
                response
                    .write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
                break;
              case "PosLogHelper.selectByGuidFixed":
                final box = global.objectBoxStore.box<PosLogObjectBoxStruct>();
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                List<PosLogObjectBoxStruct> boxData = (box.query(
                        PosLogObjectBoxStruct_.guid_auto_fixed
                            .equals(jsonCategory.guid))
                      ..order(PosLogObjectBoxStruct_.log_date_time))
                    .build()
                    .find();
                response
                    .write(jsonEncode(boxData.map((e) => e.toJson()).toList()));
                break;
              case "get_process":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                int holdNumber = jsonCategory.holdNumber;
                int docMode = jsonCategory.docMode;
                global.posHoldProcessResult[holdNumber].posProcess =
                    await PosProcess()
                        .process(holdNumber: holdNumber, docMode: docMode);
                response.write(jsonEncode(
                    global.posHoldProcessResult[holdNumber].toJson()));
                break;
              case "PosLogHelper.holdCount":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                int result =
                    await PosLogHelper().holdCount(jsonCategory.holdNumber);
                response.write(result.toString());
                break;
              case "selectByBarcodeFirst":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                ProductBarcodeObjectBoxStruct? result =
                    await ProductBarcodeHelper()
                        .selectByBarcodeFirst(jsonCategory.barcode);
                response.write(jsonEncode(result?.toJson()));
                break;
              case "selectByBarcodeList":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                List<String> barcodeList = jsonCategory.barcode.split(",");
                List<ProductBarcodeObjectBoxStruct> result =
                    await ProductBarcodeHelper()
                        .selectByBarcodeList(barcodeList);
                response
                    .write(jsonEncode(result.map((e) => e.toJson()).toList()));
                break;
              case "selectByCategoryParentGuid":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                String parentGuid = jsonCategory.parentGuid;
                final box =
                    global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
                final result = box
                    .query(ProductCategoryObjectBoxStruct_.parent_guid_fixed
                        .equals(parentGuid))
                    .order(ProductCategoryObjectBoxStruct_.xorder)
                    .build()
                    .find();
                response
                    .write(jsonEncode(result.map((e) => e.toJson()).toList()));
                break;
              case "selectByParentCategoryGuidOrderByXorder":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                String parentGuid = jsonCategory.parentGuid;
                final box =
                    global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
                final result = (box.query(ProductCategoryObjectBoxStruct_
                        .parent_guid_fixed
                        .equals(parentGuid))
                      ..order(ProductCategoryObjectBoxStruct_.xorder))
                    .build()
                    .find();
                response
                    .write(jsonEncode(result.map((e) => e.toJson()).toList()));
                break;
              case "selectByCategoryGuidFindFirst":
                HttpParameterModel jsonCategory =
                    HttpParameterModel.fromJson(jsonDecode(httpGetData.json));
                String guid = jsonCategory.guid;
                final box =
                    global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
                ProductCategoryObjectBoxStruct? result = box
                    .query(
                        ProductCategoryObjectBoxStruct_.guid_fixed.equals(guid))
                    .build()
                    .findFirst();
                response.write(jsonEncode(result?.toJson()));
                break;
            }
          } else if (request.method == 'POST') {
            if (request.uri.path == '/scan') {
              bool isTerminal =
                  (global.appMode == global.AppModeEnum.posTerminal);

              bool isClient = (global.appMode == global.AppModeEnum.posRemote);
              SyncDeviceModel resultData = SyncDeviceModel(
                  device: global.deviceName,
                  ip: global.ipAddress,
                  connected: true,
                  isCashierTerminal: isTerminal,
                  holdNumberActive: 0,
                  docModeActive: 0,
                  isClient: isClient);
              response.write(jsonEncode(resultData.toJson()));
            } else if (contentType?.mimeType == 'application/json') {
              try {
                var data = await utf8.decoder.bind(request).join();
                var jsonDecodeStr = jsonDecode(data);
                var httpPost = HttpPost.fromJson(jsonDecodeStr);
                switch (httpPost.command) {
                  case "register_staff_device":
                    SyncStaffDeviceModel jsonCategory =
                        SyncStaffDeviceModel.fromJson(
                            jsonDecode(httpPost.data));
                    bool found = false;
                    int foundIndex = -1;
                    for (int index = 0;
                        index < global.staffClientList.length;
                        index++) {
                      if (global.staffClientList[index].guid ==
                          jsonCategory.clientGuid) {
                        found = true;
                        foundIndex = index;
                        break;
                      }
                    }
                    if (found) {
                      global.staffClientList.removeAt(foundIndex);
                    }
                    global.staffClientList.add(StaffClientObjectBoxStruct(
                        guid: jsonCategory.clientGuid,
                        name: jsonCategory.clientName,
                        device_guid: jsonCategory.clientGuid,
                        device_ip: jsonCategory.clientIp));
                    response.write("success");
                    break;
                  case "process_result":
                    PosHoldProcessModel result =
                        PosHoldProcessModel.fromJson(jsonDecode(httpPost.data));
                    global.posHoldProcessResult[result.holdNumber] = result;
                    PosProcess().sumCategoryCount(
                        value: global.posHoldProcessResult[result.holdNumber]
                            .posProcess);
                    if (global.functionPosScreenRefresh != null) {
                      global.functionPosScreenRefresh!(result.holdNumber);
                    }
                    break;
                  case "PosLogHelper.insert":
                    PosLogObjectBoxStruct jsonData =
                        PosLogObjectBoxStruct.fromJson(
                            jsonDecode(httpPost.data));
                    final box =
                        global.objectBoxStore.box<PosLogObjectBoxStruct>();
                    response.write(box.put(jsonData));
                    for (int index = 0;
                        index < global.posRemoteDeviceList.length;
                        index++) {
                      if (global.posRemoteDeviceList[index].holdNumberActive ==
                          jsonData.hold_number) {
                        global.posRemoteDeviceList[index].processSuccess =
                            false;
                      }
                    }
                    posCompileProcess(
                            holdNumber: jsonData.hold_number,
                            docMode: jsonData.doc_mode)
                        .then((_) {
                      PosProcess().sumCategoryCount(
                          value: global
                              .posHoldProcessResult[global.posHoldActiveNumber]
                              .posProcess);
                      if (global.functionPosScreenRefresh != null) {
                        global.functionPosScreenRefresh!(
                            global.posHoldActiveNumber);
                      }
                    });
                    break;
                  case "PosLogHelper.deleteByHoldNumber":
                    int holdNumber = int.parse(httpPost.data);
                    int docMode = 0; //********* Dummy
                    final box =
                        global.objectBoxStore.box<PosLogObjectBoxStruct>();
                    final ids = box
                        .query(PosLogObjectBoxStruct_.hold_number
                            .equals(holdNumber))
                        .build()
                        .findIds();
                    box.removeMany(ids);
                    posCompileProcess(holdNumber: holdNumber, docMode: docMode)
                        .then((_) {
                      PosProcess().sumCategoryCount(
                          value: global
                              .posHoldProcessResult[holdNumber].posProcess);
                      if (global.functionPosScreenRefresh != null) {
                        global.functionPosScreenRefresh!(
                            global.posHoldActiveNumber);
                      }
                    });
                    break;
                  case "get_device_name":
                    // Return ชื่อเครื่อง server , ip server
                    response.write(jsonEncode(
                        jsonDecode('{"device": "${global.deviceName}"}')
                            as Map));
                    break;
                  case "register_remote_device":
                    // ลงทะเบียนเครื่องช่วยขาย
                    SyncDeviceModel posClientDevice =
                        SyncDeviceModel.fromJson(jsonDecode(httpPost.data));
                    int indexFound = -1;
                    for (int index = 0;
                        index < global.posRemoteDeviceList.length;
                        index++) {
                      if (global.posRemoteDeviceList[index].device ==
                          posClientDevice.device) {
                        indexFound = index;
                        break;
                      }
                    }
                    if (indexFound != -1) {
                      global.posRemoteDeviceList[indexFound].ip =
                          posClientDevice.ip;
                      global.posRemoteDeviceList[indexFound].holdNumberActive =
                          posClientDevice.holdNumberActive;
                      serviceLocator<Log>().debug(
                          "register_remote_device : ${posClientDevice.ip},hold_number : ${global.posRemoteDeviceList[indexFound].holdNumberActive}");
                    } else {
                      global.posRemoteDeviceList.add(posClientDevice);
                      serviceLocator<Log>().debug(
                          "register_remote_device : ${posClientDevice.device} : ${global.posRemoteDeviceList.length}");
                    }
                    break;
                  case "register_customer_display_device":
                    // ลงทะเบียนเครื่องแสดงผลลูกค้า
                    SyncDeviceModel customerDisplayDevice =
                        SyncDeviceModel.fromJson(jsonDecode(httpPost.data));
                    bool found = false;
                    for (var device in global.customerDisplayDeviceList) {
                      if (device.device == customerDisplayDevice.device) {
                        found = true;
                        break;
                      }
                    }
                    if (!found) {
                      global.customerDisplayDeviceList
                          .add(customerDisplayDevice);
                      serviceLocator<Log>().debug(
                          "register_customer_display_device : ${customerDisplayDevice.device} : ${global.customerDisplayDeviceList.length}");
                    }
                    break;
                  case "change_customer_by_phone":
                    // รับข้อมูลหมายเลขโทรศัพท์ แล้วมาค้นหาชื่อ และประมวลผล
                    SyncCustomerDisplayModel postCustomer =
                        SyncCustomerDisplayModel.fromJson(
                            jsonDecode(httpPost.data));
                    String customerCode = postCustomer.phone;
                    String customerName = "";
                    String customerPhone = postCustomer.phone;
                    SyncCustomerDisplayModel result = SyncCustomerDisplayModel(
                        code: customerCode,
                        phone: customerPhone,
                        name: customerName);
                    response.write(jsonEncode(result.toJson()));
                    try {
                      global.posHoldProcessResult[global.posHoldActiveNumber]
                          .customerCode = customerCode;
                      global.posHoldProcessResult[global.posHoldActiveNumber]
                          .customerName = customerName;
                      global.posHoldProcessResult[global.posHoldActiveNumber]
                          .customerPhone = customerPhone;
                      // ประมวลผลหน้าจอขายใหม่
                      PosProcess().sumCategoryCount(
                          value: global
                              .posHoldProcessResult[global.posHoldActiveNumber]
                              .posProcess);
                      if (global.functionPosScreenRefresh != null) {
                        global.functionPosScreenRefresh!(
                            global.posHoldActiveNumber);
                      }
                    } catch (e) {
                      serviceLocator<Log>().error(e);
                    }
                    break;
                  /*case "get_table_group":
              List<TableGroupStruct> _groupList =
                  await global.tableGroupHelper.select(order: "idx");
              var _data = jsonEncode(_groupList.map((i) => i.toJson()).toList())
                  .toString();
              _res..write(_data);
              break;
            case "get_table_and_sum":
              List<TableStruct> _groupList = await global.tableHelper
                  .selectAndSumOrderAmount(where: httpPost.where);
              var _data = jsonEncode(_groupList.map((i) => i.toJson()).toList())
                  .toString();
              _res..write(_data);
              break;
            case "update_table":
              TableStruct _data =
                  TableStruct.fromJson(jsonDecode(httpPost.value));
              bool _result = await global.tableHelper.update(_data);
              _res..write(_result);
              break;
            case "insert_table_log":
              TableLogStruct _data =
                  TableLogStruct.fromJson(jsonDecode(httpPost.value));
              int _result = await global.tableLogHelper.insert(_data);
              _res..write(_result);
              break;*/
                  /*case "insert_print_queue":
              PrintQueueStruct _data =
                  PrintQueueStruct.fromJson(jsonDecode(httpPost.value));
              int _result = await global.printQueueHelper.insert(_data);
              _res..write(_result);
              break;*/
                  /*case "insert_order":
              OrderSummeryStruct _data =
                  OrderSummeryStruct.fromJson(jsonDecode(httpPost.value));
              String _result = await global.orderHelper.saveOrder(_data);
              _res..write(_result);
              break;*/
                  /*case "print_queue":
              global.printQueueStart();
              break;*/
                  /*case "select":
              List<List<Map>> _result = [];
              for (var _query in httpPost.query) {
                _result.add(await global.clientDb!.rawQuery(_query));
              }
              _res..write(jsonEncode(_result));
              break;*/
                }
              } catch (e) {
                stderr.writeln(e.toString());
              }
            }
          }
          await response.flush();
          await response.close();
        }
      } catch (e) {
        print(e.toString());
      }
    }
  }
}

/*Future<String> getDeviceName(String ip) async {
  var _url = "http://" + ip + ":" + global.serverDevicePort.toString();
  var _uri = Uri.parse(_url);
  try {
    http.Response _response = await http
        .post(_uri,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(<String, String>{'command': 'device', 'wifi_ip': ''}))
        .timeout(const Duration(seconds: 2));
    if (_response.statusCode == 200) {
      var _fromJson = jsonDecode(_response.body.toString());
      return _fromJson["device"];
      ;
    } else {}
  } catch (e) {
    print('failed');
  }
  return "";
}*/
