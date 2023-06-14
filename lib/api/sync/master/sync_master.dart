import 'dart:async';
import 'dart:convert';
import 'package:dedepos/api/client.dart';
import 'package:dedepos/api/sync/api_repository.dart';
import 'package:dedepos/api/sync/master/sync_bank.dart';
import 'package:dedepos/api/sync/master/sync_employee.dart';
import 'package:dedepos/api/user_repository.dart';
import 'package:dedepos/core/logger/logger.dart';
import 'package:dedepos/core/service_locator.dart';
import 'package:dedepos/db/printer_helper.dart';
import 'package:dedepos/db/product_barcode_helper.dart';
import 'package:dedepos/db/product_category_helper.dart';
import 'package:dedepos/api/sync/model/sync_printer_model.dart';
import 'package:dedepos/api/sync/model/sync_inventory_model.dart';
import 'package:dedepos/api/sync/model/item_remove_model.dart';
import 'package:dedepos/model/objectbox/printer_struct.dart';
import 'package:dedepos/model/objectbox/product_barcode_struct.dart';
import 'package:dedepos/model/objectbox/product_category_struct.dart';
import 'package:dedepos/global.dart' as global;
import 'package:dedepos/global_model.dart';
import 'package:dedepos/model/json/product_option_model.dart';
import 'package:dedepos/objectbox.g.dart';
import 'package:intl/intl.dart';

Future syncProductCategory(data) async {
  List<String> removeMany = [];
  List<ProductCategoryObjectBoxStruct> manyForInsert = [];

  // Delete
  List<ItemRemoveModel> removes = (data["remove"] as List).map((removeCate) => ItemRemoveModel.fromJson(removeCate)).toList();
  for (var removeData in removes) {
    try {
      global.syncTimeIntervalSecond = 1;
      removeMany.add(removeData.guidfixed);
      global.syncRefreshProductCategory = true;
    } catch (e) {
      serviceLocator<Log>().debug(e);
    }
  }
  // Insert
  List<SyncCategoryModel> newDataList = (data["new"] as List).map((newCate) => SyncCategoryModel.fromJson(newCate)).toList();
  for (var newData in newDataList) {
    global.syncTimeIntervalSecond = 1;
    removeMany.add(newData.guidfixed);

    ProductCategoryObjectBoxStruct newProduct = ProductCategoryObjectBoxStruct(
      guid_fixed: newData.guidfixed,
      parent_guid_fixed: newData.parentguid,
      names: [],
      image_url: newData.imageuri,
      use_image_or_color: newData.useimageorcolor,
      colorselect: newData.colorselect,
      colorselecthex: newData.colorselecthex,
      codelist: jsonEncode(newData.codelist),
      xorder: newData.xsorts![0].xorder,
      category_count: newData.childcount,
    );
    // ทดสอบ รูป
    //newProduct.image_url = global.getImageForTest();

    serviceLocator<Log>().debug("Sync Product Category : ${newData.guidfixed} ${newData.names![0].name} ${newData.parentguid}");
    newProduct.names.add(newData.names![0].name);
    manyForInsert.add(newProduct);
  }
  if (removeMany.isNotEmpty) {
    global.syncRefreshProductCategory = true;
    ProductCategoryHelper().deleteByGuidFixedMany(removeMany);
  }
  if (manyForInsert.isNotEmpty) {
    global.syncRefreshProductCategory = true;
    ProductCategoryHelper().insertMany(manyForInsert);
  }
  if (global.syncRefreshProductCategory) {
    // Update Count Group
    final box = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();
    List<ProductCategoryObjectBoxStruct> selectCategory = box.getAll();
    for (var category in selectCategory) {
      final count = box.query(ProductCategoryObjectBoxStruct_.parent_guid_fixed.equals(category.guid_fixed)).build().count();
      if (count > 0) {
        category.category_count = count;
        box.put(category);
      }
    }
  }
}

void syncProductBarcode(List<ItemRemoveModel> removeList, List<SyncProductBarcodeModel> newDataList) {
  List<String> manyForDelete = [];
  List<ProductBarcodeObjectBoxStruct> manyForInsert = [];

  // Delete
  for (var removeData in removeList) {
    //print("Remove Product Barcode : " + removeData.guidfixed);
    try {
      global.syncTimeIntervalSecond = 1;
      manyForDelete.add(removeData.guidfixed);
      global.syncRefreshProductBarcode = true;
    } catch (e) {
      serviceLocator<Log>().error(e);
    }
  }
  // Insert
  for (var newData in newDataList) {
    //print("Insert Product Barcode : " + newData.barcode);
    global.syncTimeIntervalSecond = 1;
    manyForDelete.add(newData.guidfixed);
    List<String> packNameValues = [];
    List<String> packUnitNameValues = [];
    List<String> packPriceValues = [];
    String nameAll = "";
    for (int index = 0; index < newData.names.length; index++) {
      packNameValues.add(newData.names[index].name);
      nameAll += "${newData.names[index].name},";
    }
    for (int index = 0; index < newData.itemunitnames.length; index++) {
      packUnitNameValues.add(newData.itemunitnames[index].name);
    }

    // 0=ราคาทั่วไป,1=ราคาสมาชิก
    for (int index = 0; index < newData.prices!.length; index++) {
      packPriceValues.add(newData.prices![index].price.toString());
    }
    String optionsJson = "";
    if (newData.options != null) {
      for (SyncProductOptionModel option in newData.options!) {
        List<String> packOptionNames = [];
        for (int index = 0; index < option.names.length; index++) {
          packOptionNames.add(option.names[index].name);
        }
        ProductOptionModel newOption = ProductOptionModel(
          guid_fixed: option.guid,
          choice_type: option.choicetype,
          max_select: option.maxselect,
          names: packOptionNames,
          choices: [],
        );
        for (SyncProductChoiceModel choice in option.choices) {
          List<String> packChoiceNames = [];
          for (int index = 0; index < choice.names.length; index++) {
            packChoiceNames.add(choice.names[index].name);
          }
          ProductChoiceModel newChoice = ProductChoiceModel(
            guid_fixed: choice.guid,
            guid_code: option.guid,
            names: packChoiceNames,
            product_code: choice.refproductcode,
            barcode: choice.refbarcode,
            is_default: choice.isdefault,
            item_unit_code: choice.refunitcode,
            price: choice.price,
            qty: choice.qty,
            selected: false,
          );
          newOption.choices.add(newChoice);
        }
        if (optionsJson != "") {
          optionsJson += ",";
        }
        optionsJson += jsonEncode(newOption.toJson());
      }
    }
    optionsJson = "[$optionsJson]";
    ProductBarcodeObjectBoxStruct newBarcode = ProductBarcodeObjectBoxStruct(
      guid_fixed: newData.guidfixed,
      names: packNameValues,
      name_all: nameAll,
      product_count: 0,
      barcode: newData.barcode,
      item_guid: "",
      descriptions: [],
      item_code: newData.itemcode,
      item_unit_code: newData.itemunitcode,
      unit_names: packUnitNameValues,
      prices: packPriceValues,
      new_line: 0,
      unit_code: newData.itemunitcode,
      options_json: optionsJson,
      images_url: newData.imageuri,
      image_or_color: newData.useimageorcolor,
      color_select: newData.colorselect,
      color_select_hex: newData.colorselecthex,
    );
    // newBarcode.images_url = global.getImageForTest();
    newBarcode.image_or_color = true;

    manyForInsert.add(newBarcode);
    global.syncRefreshProductBarcode = true;
    // Update ข้อมูลใน Memory
    for (int index = 0; index < global.productCategoryCodeSelected.length; index++) {
      if (global.productCategoryCodeSelected[index].guid_fixed == newData.guidfixed) {
        global.productCategoryCodeSelected[index].names.add(newData.names[0].name);
        global.productCategoryCodeSelected[index].image_url = newData.imageuri;

        /*global.productGroupCodeSelected[_index].xorder =
            newData.xsorts![0].xorder;
        global.productGroupCodeSelected[_index].parent_group_guid =
            newData.parentguid;*/
        break;
      }
    }
    global.syncRefreshProductBarcode = true;
  }
  if (manyForDelete.isNotEmpty) {
    ProductBarcodeHelper().deleteByGuidFixedMany(manyForDelete);
  }
  if (manyForInsert.isNotEmpty) {
    ProductBarcodeHelper().insertMany(manyForInsert);
  }
  // Update Count Group
  /*final box = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>();
  List<ProductBarcodeObjectBoxStruct> selectGroup = box.getAll();
  for (var group in selectGroup) {
    final count = box
        .query(ProductBarcodeObjectBoxStruct_.parent_group_guid
            .equals(group.item_code))
        .build()
        .count();
    if (count > 0) {
      group.group_count = count;
      box.put(group);
    }
  }*/
}

Future syncPrinter(data) async {
  List<String> manyForDelete = [];
  List<PrinterObjectBoxStruct> manyForInsert = [];

  // Delete
  List<ItemRemoveModel> removes = (data["remove"] as List).map((removeCate) => ItemRemoveModel.fromJson(removeCate)).toList();
  for (var removeData in removes) {
    try {
      global.syncTimeIntervalSecond = 1;
      manyForDelete.add(removeData.guidfixed);
      global.syncRefreshPrinter = true;
    } catch (e) {
      serviceLocator<Log>().error(e);
    }
  }
  // Insert
  List<SyncPrinterModel> newDataList = (data["new"] as List).map((newCate) => SyncPrinterModel.fromJson(newCate)).toList();
  for (var newData in newDataList) {
    global.syncTimeIntervalSecond = 1;
    manyForDelete.add(newData.guidfixed);
    PrinterObjectBoxStruct newPrinter = PrinterObjectBoxStruct(
      code: newData.code,
      guid_fixed: newData.guidfixed,
      name1: newData.name1,
      type: newData.type,
      print_ip_address: newData.address,
    );
    manyForInsert.add(newPrinter);
    global.syncRefreshPrinter = true;
  }
  if (manyForDelete.isNotEmpty) {
    PrinterHelper().deleteByGuidFixedMany(manyForDelete);
  }
  if (manyForInsert.isNotEmpty) {
    PrinterHelper().insertMany(manyForInsert);
  }
}

/*
flutter: bankmaster 2023-02-14T02:39:48Z
flutter: bookbank 0001-01-01T00:00:00Z
flutter: device 2023-02-14T02:36:53Z
flutter: employee 0001-01-01T00:00:00Z
flutter: kitchen 2023-02-14T02:36:29Z
flutter: member 0001-01-01T00:00:00Z
flutter: printer 2023-02-06T03:37:40Z
flutter: product 0001-01-01T00:00:00Z
flutter: productbarcode 2023-02-14T07:57:02Z
flutter: productcategory 2023-02-14T07:55:01Z
flutter: productunit 2023-02-17T04:14:39Z
flutter: qrpayment 0001-01-01T00:00:00Z
flutter: shoptable 2023-02-14T02:35:51Z
flutter: shopzone 0001-01-01T00:00:00Z
flutter: staff 2023-02-14T02:39:22Z
*/

Future syncMasterData() async {
  ApiRepository apiRepository = ApiRepository();
  global.syncDataProcess = true;
  String lastUpdateTime = global.appStorage.read(global.syncCategoryTimeName) ?? global.syncDateBegin;
  if (ProductCategoryHelper().count() == 0) {
    lastUpdateTime = global.syncDateBegin;
  }
  try {
    List<SyncMasterStatusModel> masterStatus = await apiRepository.serverMasterStatus();
    {
      // หมวดสินค้า
      final productCategoryCount = ProductCategoryHelper().count();
      if (productCategoryCount == 0) {
        lastUpdateTime = global.syncDateBegin;
      }
      lastUpdateTime = DateFormat(global.dateFormatSync).format(DateTime.parse(lastUpdateTime));
      var getLastUpdateTime = global.syncFindLastUpdate(masterStatus, "productcategory");
      if (lastUpdateTime != getLastUpdateTime) {
        serviceLocator<Log>().debug("serverProductCategory Start");
        await apiRepository.serverProductCategory(offset: 0, limit: 1000, lastupdate: lastUpdateTime).then((value) {
          if (value.success) {
            syncProductCategory(value.data["productcategory"]).then((_) {
              //print("Update syncCategoryTimeName Success");
              global.appStorage.write(global.syncCategoryTimeName, getLastUpdateTime);
            });
          }
        });
        serviceLocator<Log>().debug("serverProductCategory End : ${ProductCategoryHelper().count()}");
      }
    }
    {
      // Sync Barcode
      String lastUpdateTime = global.appStorage.read(global.syncProductBarcodeTimeName) ?? global.syncDateBegin;
      if (ProductBarcodeHelper().count() == 0) {
        lastUpdateTime = global.syncDateBegin;
      }
      lastUpdateTime = DateFormat(global.dateFormatSync).format(DateTime.parse(lastUpdateTime));
      var getLastUpdateTime = global.syncFindLastUpdate(masterStatus, "productbarcode");
      if (lastUpdateTime != getLastUpdateTime) {
        serviceLocator<Log>().debug("serverProductBarcode Start");
        // Test
        // lastUpdateTime = global.syncDateBegin;
        //
        var loop = true;
        var offset = 0;
        var limit = 10000;
        while (loop) {
          await apiRepository.serverProductBarcode(offset: offset, limit: limit, lastupdate: lastUpdateTime).then((value) {
            if (value.success) {
              var dataList = value.data["productbarcode"];
              List<ItemRemoveModel> removeList = (dataList["remove"] as List).map((removeCate) => ItemRemoveModel.fromJson(removeCate)).toList();
              List<SyncProductBarcodeModel> newDataList = (dataList["new"] as List).map((newCate) => SyncProductBarcodeModel.fromJson(newCate)).toList();
              serviceLocator<Log>().debug("offset : $offset remove : ${removeList.length} insert : ${newDataList.length}");
              if (newDataList.isEmpty && removeList.isEmpty) {
                loop = false;
              } else {
                syncProductBarcode(removeList, newDataList);
              }
            } else {
              serviceLocator<Log>().debug("************************************************* Error");
              loop = false;
            }
          });
          offset += limit;
        }
        serviceLocator<Log>().debug("Update syncProductBarcodeTimeName Success : ${ProductBarcodeHelper().count()}");
        global.appStorage.write(global.syncProductBarcodeTimeName, getLastUpdateTime);
      }
    }
    syncEmployeeCompare(masterStatus);
    syncBankCompare(masterStatus);
    global.syncDataSuccess = true;
    global.syncDataProcess = false;
  } catch (e) {
    global.syncDataProcess = false;
  }
}

Future syncMasterProcess() async {
  if (global.appMode == global.AppModeEnum.posTerminal) {
    // Sync เฉพาะเครื่อง POS Terminal
    global.isOnline = await global.hasNetwork();
    if (global.isOnline) {
      if (global.apiConnected == false) {
        if (global.loginProcess == false) {
          global.loginProcess = true;
          UserRepository userRepository = UserRepository();
          await userRepository.authenUser(global.apiUserName, global.apiUserPassword).then((result) async {
            if (result.success) {
              global.apiConnected = true;
              global.appStorage.write("token", result.data["token"]);
              serviceLocator<Log>().debug("Login Success");
              ApiResponse selectShop = await userRepository.selectShop(global.apiShopID);
              if (selectShop.success) {
                serviceLocator<Log>().debug("Select Shop Success");
                global.loginSuccess = true;
              }
            }
          }).catchError((e) {
            serviceLocator<Log>().error(e);
          }).whenComplete(() async {
            global.loginProcess = false;
          });
        }
      }
      if (global.apiConnected == true && global.loginSuccess == true && global.syncDataProcess == false) {
        syncMasterData();
      }
    }
  }
}
