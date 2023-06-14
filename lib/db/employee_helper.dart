import 'package:dedepos/global.dart' as global;
import 'package:dedepos/model/objectbox/employees_struct.dart';
import 'package:dedepos/objectbox.g.dart';

class EmployeeHelper {
  final box = global.objectBoxStore.box<EmployeeObjectBoxStruct>();

  int insert(EmployeeObjectBoxStruct value) {
    return box.put(value);
  }

  void insertMany(List<EmployeeObjectBoxStruct> values) {
    box.putMany(values);
  }

  bool deleteByGuidFixed(String guid) {
    bool result = false;
    final find = box.query(EmployeeObjectBoxStruct_.guidfixed.equals(guid)).build().findFirst();
    if (find != null) {
      result = box.remove(find.id);
    }
    return result;
  }

  void deleteByGuidFixedMany(List<String> guidFixedList) {
    Condition<EmployeeObjectBoxStruct>? ids;
    for (var guidFixed in guidFixedList) {
      if (ids == null) {
        ids = EmployeeObjectBoxStruct_.guidfixed.equals(guidFixed);
      } else {
        ids = ids.or(EmployeeObjectBoxStruct_.guidfixed.equals(guidFixed));
      }
    }
    if (ids != null) {
      final find = box.query(ids).build().find();
      box.removeMany(find.map((data) => data.id).toList());
    }
  }

  List<EmployeeObjectBoxStruct> getAll() {
    return (box.query()).build().find();
  }

  List<EmployeeObjectBoxStruct> select({String word = ""}) {
    if (word.trim().isEmpty) {
      return (box.query()).build().find();
    }
    return (box.query()).build().find();
  }

  int count() {
    return (box.query()).build().count();
  }

  void deleteAll() {
    box.removeAll();
  }
}
