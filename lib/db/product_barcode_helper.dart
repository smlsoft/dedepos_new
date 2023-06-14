import 'dart:async';
import 'dart:convert';
import 'package:dedepos/core/logger/logger.dart';
import 'package:dedepos/core/service_locator.dart';
import 'package:dedepos/global.dart' as global;
import 'package:dedepos/global_model.dart';
import 'package:dedepos/objectbox.g.dart';
import 'package:dedepos/model/objectbox/product_barcode_struct.dart';

class ProductBarcodeHelper {
  final box = global.objectBoxStore.box<ProductBarcodeObjectBoxStruct>();

  void deleteByGuidFixedMany(List<String> guidfixed) {
    Condition<ProductBarcodeObjectBoxStruct>? ids;
    for (var guid in guidfixed) {
      if (ids == null) {
        ids = ProductBarcodeObjectBoxStruct_.guid_fixed.equals(guid);
      } else {
        ids = ids.or(ProductBarcodeObjectBoxStruct_.guid_fixed.equals(guid));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();

      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  int count() {
    return box.count();
  }

  void insertMany(List<ProductBarcodeObjectBoxStruct> values) {
    box.putMany(values);
  }

  Future insert(ProductBarcodeObjectBoxStruct value) async {
    return box.put(value);
  }

  List<ProductBarcodeObjectBoxStruct> packData(List<ProductBarcodeObjectBoxStruct> source) {
    List<ProductBarcodeObjectBoxStruct> results = [];
    for (var data in source) {
      ProductBarcodeObjectBoxStruct newData = ProductBarcodeObjectBoxStruct(
          barcode: data.barcode,
          names: data.names,
          name_all: data.name_all,
          prices: data.prices,
          unit_code: data.unit_code,
          unit_names: data.unit_names,
          new_line: 0,
          color_select: "",
          image_or_color: true,
          color_select_hex: "",
          guid_fixed: data.guid_fixed,
          item_code: data.item_code,
          item_guid: data.item_guid,
          descriptions: data.descriptions,
          item_unit_code: data.item_unit_code,
          options_json: "",
          images_url: data.images_url,
          product_count: 0);
      /*List<ProductOptionStruct> _jsonOption =  ProductOptionStruct.fromJson(jsonDecode(  _data.options));
      _data.options.forEach((_optionStr) {
        ProductOptionStruct _option =
            ProductOptionStruct.fromJson(jsonDecode(_optionStr));
        ProductOptionStruct _newOption = new ProductOptionStruct();
        _newOption.guid_fixed = _option.guid_fixed;
        _newOption.choice_type = _option.choice_type;
        _newOption.code = _option.code;
        _newOption.max_select = _option.max_select;
        _newOption.name1 = _option.name1;
        _newOption.name2 = _option.name2;
        _newOption.name3 = _option.name3;
        _newOption.name4 = _option.name4;
        _newOption.name5 = _option.name5;
        _newOption.isRequired = _option.isRequired;
        _option.choices.forEach((_choice) {
          ProductChoiceStruct _newChoice = new ProductChoiceStruct();
          _newChoice.barcode = _choice.barcode;
          _newChoice.is_default = _choice.is_default;
          _newChoice.item_unit_code = _choice.item_unit_code;
          _newChoice.name1 = _choice.name1;
          _newChoice.name2 = _choice.name2;
          _newChoice.name3 = _choice.name3;
          _newChoice.name4 = _choice.name4;
          _newChoice.name5 = _choice.name5;
          _newChoice.price = _choice.price;
          _newChoice.qty = _choice.qty;
          _newChoice.qty_max = _choice.qty_max;
          _newChoice.selected = _choice.selected;
          //_newChoice.suggest_code = _choice.suggest_code;
          _newOption.choices.add(_newChoice);
        });
        _new.options = _newOption.toJson().toString();
      });*/
      results.add(newData);
    }
    return results;
  }

  Future<List<ProductBarcodeObjectBoxStruct>> selectByBarcodeList(
    List<String> barcodeList,
  ) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(barcode: barcodeList.join(","));
      HttpGetDataModel json = HttpGetDataModel(code: "selectByBarcodeList", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return (jsonDecode(result) as List).map((e) => ProductBarcodeObjectBoxStruct.fromJson(e)).toList();
    } else {
      Condition<ProductBarcodeObjectBoxStruct>? ids;
      for (var barcode in barcodeList) {
        if (ids == null) {
          ids = ProductBarcodeObjectBoxStruct_.barcode.equals(barcode);
        } else {
          ids = ids.or(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode));
        }
      }
      if (ids != null) {
        return box.query(ids).build().find();
      } else {
        return [];
      }
    }
  }

  Future<ProductBarcodeObjectBoxStruct?> selectByBarcodeFirst(String barcode) async {
    if (global.appMode == global.AppModeEnum.posRemote) {
      HttpParameterModel jsonParameter = HttpParameterModel(barcode: barcode);
      HttpGetDataModel json = HttpGetDataModel(code: "selectByBarcodeFirst", json: jsonEncode(jsonParameter.toJson()));
      String result = await global.getFromServer(json: jsonEncode(json.toJson()));
      return ProductBarcodeObjectBoxStruct.fromJson(jsonDecode(result));
    } else {
      return box.query(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode)).build().findFirst();
    }
  }

  List<ProductBarcodeObjectBoxStruct> xselect({String where = "", String order = "", int limit = 0, int offset = 0}) {
    return box.query().build().find();
  }

  List<ProductBarcodeObjectBoxStruct> selectByCodeNameBarCode({required String word, required String order, required int limit, required int offset}) {
    Condition<ProductBarcodeObjectBoxStruct>? condition;

    List<String> wordBreak = global.wordSplit(word);
    serviceLocator<Log>().debug(wordBreak);
    for (int wordIndex = 0; wordIndex < wordBreak.length; wordIndex++) {
      var currentCondition = ProductBarcodeObjectBoxStruct_.item_code
          .contains(wordBreak[wordIndex])
          .or(ProductBarcodeObjectBoxStruct_.barcode.contains(wordBreak[wordIndex]))
          .or(ProductBarcodeObjectBoxStruct_.name_all.contains(wordBreak[wordIndex]));

      if (wordIndex == 0) {
        condition = currentCondition;
      } else {
        condition = condition?.and(currentCondition);
      }
    }
    var query = box.query(condition).build();
    if (limit > 0) {
      query.offset = offset;
      query.limit = limit;
    }
    return query.find();
  }

  void deleteAll() {
    box.removeAll();
  }

  bool deleteByBarcode(String barcode) {
    bool result = false;
    final find = box.query(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByBarcodeMany(List<String> barcodeList) {
    Condition<ProductBarcodeObjectBoxStruct>? ids;
    for (var barcode in barcodeList) {
      if (ids == null) {
        ids = ProductBarcodeObjectBoxStruct_.barcode.equals(barcode);
      } else {
        ids = ids.or(ProductBarcodeObjectBoxStruct_.barcode.equals(barcode));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  Future<int> deleteByCode(String code) async {
    return 0;
  }

  bool deleteByGuidFixed(String guidfixed) {
    bool result = false;
    final find = box.query(ProductBarcodeObjectBoxStruct_.barcode.equals(guidfixed)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }
}
