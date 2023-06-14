import 'dart:convert';

import 'package:dedepos/global.dart' as global;
import 'package:dedepos/global_model.dart';
import 'package:dedepos/model/objectbox/product_category_struct.dart';
import 'package:dedepos/objectbox.g.dart';

class ProductCategoryHelper {
  final box = global.objectBoxStore.box<ProductCategoryObjectBoxStruct>();

  int insert(ProductCategoryObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<ProductCategoryObjectBoxStruct> values) {
    box.putMany(values);
  }

  Future<List<ProductCategoryObjectBoxStruct>> selectByParentCategoryGuidOrderByXorder({String parentGuid = ""}) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(parentGuid: parentGuid);
      HttpGetDataModel json = HttpGetDataModel(code: "selectByParentCategoryGuidOrderByXorder", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return (jsonDecode(result) as List).map((e) => ProductCategoryObjectBoxStruct.fromJson(e)).toList();
    } else {
      return (box.query(ProductCategoryObjectBoxStruct_.parent_guid_fixed.equals(parentGuid))..order(ProductCategoryObjectBoxStruct_.xorder)).build().find();
    }
  }

  Future<ProductCategoryObjectBoxStruct?> selectByCategoryGuidFindFirst(String guid) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(guid: guid);
      HttpGetDataModel json = HttpGetDataModel(code: "selectByCategoryGuidFindFirst", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return ProductCategoryObjectBoxStruct.fromJson(jsonDecode(result));
    } else {
      return box.query(ProductCategoryObjectBoxStruct_.guid_fixed.equals(guid)).build().findFirst();
    }
  }

  Future<List<ProductCategoryObjectBoxStruct>> selectByCategoryParentGuid(String parentGuid) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(parentGuid: parentGuid);
      HttpGetDataModel json = HttpGetDataModel(code: "selectByCategoryParentGuid", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return (jsonDecode(result) as List).map((e) => ProductCategoryObjectBoxStruct.fromJson(e)).toList();
    } else {
      return box.query(ProductCategoryObjectBoxStruct_.parent_guid_fixed.equals(parentGuid)).order(ProductCategoryObjectBoxStruct_.xorder).build().find();
    }
  }

  bool deleteByGuidFixed(String guidfixed) {
    bool result = false;
    final find = box.query(ProductCategoryObjectBoxStruct_.guid_fixed.equals(guidfixed)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixed) {
    Condition<ProductCategoryObjectBoxStruct>? ids;
    for (var guid in guidFixed) {
      if (ids == null) {
        ids = ProductCategoryObjectBoxStruct_.guid_fixed.equals(guid);
      } else {
        ids = ids.or(ProductCategoryObjectBoxStruct_.guid_fixed.equals(guid));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  bool deleteByGuid(String guid) {
    bool result = false;
    final find = box.query(ProductCategoryObjectBoxStruct_.guid_fixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteAll() {
    box.removeAll();
  }

  int count() {
    return box.count();
  }
}
