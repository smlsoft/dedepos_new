import 'dart:async';
import 'dart:convert';
import 'package:dedepos/api/client.dart';
import 'package:dedepos/api/sync/api_repository.dart';
import 'package:dedepos/api/user_repository.dart';
import 'package:dedepos/db/employee_helper.dart';
import 'package:dedepos/db/bank_helper.dart';
import 'package:dedepos/db/printer_helper.dart';
import 'package:dedepos/db/product_barcode_helper.dart';
import 'package:dedepos/db/product_category_helper.dart';
import 'package:dedepos/api/sync/model/sync_bank_model.dart';
import 'package:dedepos/api/sync/model/sync_employee_model.dart';
import 'package:dedepos/api/sync/model/sync_printer_model.dart';
import 'package:dedepos/model/objectbox/bank_struct.dart';
import 'package:dedepos/api/sync/model/sync_inventory_model.dart';
import 'package:dedepos/api/sync/model/item_remove_model.dart';
import 'package:dedepos/model/objectbox/employees_struct.dart';
import 'package:dedepos/model/objectbox/printer_struct.dart';
import 'package:dedepos/model/objectbox/product_barcode_struct.dart';
import 'package:dedepos/model/objectbox/product_category_struct.dart';
import 'package:dedepos/global.dart' as global;
import 'package:dedepos/global_model.dart';
import 'package:dedepos/model/json/product_option_model.dart';
import 'package:dedepos/objectbox.g.dart';
import 'package:intl/intl.dart';

Future syncEmployee(List<ItemRemoveModel> removeList,
    List<SyncEmployeeModel> newDataList) async {
  List<String> removeMany = [];
  List<EmployeeObjectBoxStruct> manyForInsert = [];

  // Delete
  for (var removeData in removeList) {
    try {
      global.syncTimeIntervalSecond = 1;
      removeMany.add(removeData.guidfixed);
    } catch (e) {
      print(e);
    }
  }
  // Insert
  for (var newData in newDataList) {
    global.syncTimeIntervalSecond = 1;
    removeMany.add(newData.guidfixed);

    EmployeeObjectBoxStruct newEmployee = EmployeeObjectBoxStruct(
      guidfixed: newData.guidfixed,
      code: newData.code,
      email: newData.email,
      isenabled: newData.isenabled,
      name: newData.name,
      profilepicture: newData.profilepicture,
    );

    print("Sync Employee : " + newData.code + " " + newData.name);
    manyForInsert.add(newEmployee);
  }
  if (removeMany.isNotEmpty) {
    EmployeeHelper().deleteByGuidFixedMany(removeMany);
  }
  if (manyForInsert.isNotEmpty) {
    EmployeeHelper().insertMany(manyForInsert);
  }
}

Future<void> syncEmployeeCompare(
    List<SyncMasterStatusModel> masterStatus) async {
  ApiRepository apiRepository = ApiRepository();

  // Sync พนักงาน
  String lastUpdateTime = global.appStorage.read(global.syncEmployeeTimeName) ??
      global.syncDateBegin;
  if (EmployeeHelper().count() == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  lastUpdateTime =
      DateFormat(global.dateFormatSync).format(DateTime.parse(lastUpdateTime));
  var getLastUpdateTime = global.syncFindLastUpdate(masterStatus, "employee");
  if (lastUpdateTime != getLastUpdateTime) {
    print("syncEmployee Start");
    var loop = true;
    var offset = 0;
    var limit = 10000;
    while (loop) {
      await apiRepository
          .serverEmployee(
              offset: offset, limit: limit, lastupdate: lastUpdateTime)
          .then((value) {
        if (value.success) {
          var dataList = value.data["employee"];
          List<ItemRemoveModel> removeList = (dataList["remove"] as List)
              .map((removeCate) => ItemRemoveModel.fromJson(removeCate))
              .toList();
          List<SyncEmployeeModel> newDataList = (dataList["new"] as List)
              .map((newCate) => SyncEmployeeModel.fromJson(newCate))
              .toList();
          print("offset : " +
              offset.toString() +
              " remove : " +
              removeList.length.toString() +
              " insert : " +
              newDataList.length.toString());
          if (newDataList.isEmpty && removeList.isEmpty) {
            loop = false;
          } else {
            syncEmployee(removeList, newDataList);
          }
        } else {
          print("************************************************* Error");
          loop = false;
        }
      });
      offset += limit;
    }
    print(
        "Update SyncEmployee Success : " + EmployeeHelper().count().toString());
    global.appStorage.write(global.syncEmployeeTimeName, getLastUpdateTime);
  }
}