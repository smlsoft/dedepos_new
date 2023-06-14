import 'dart:convert';
import 'package:dedepos/api/client.dart';
import 'package:dedepos/core/logger/logger.dart';
import 'package:dedepos/core/service_locator.dart';
import 'package:dedepos/global_model.dart' as global_model;
import 'package:dio/dio.dart';

// GET {{host}}/master-sync/list?lastupdate=2010-01-02T15:04&module=productunit&limit=1&offset=0&action=new
class ApiRepository {
  Future<List<global_model.SyncMasterStatusModel>> serverMasterStatus() async {
    Dio client = Client().init();

    try {
      String query = "/master-sync/status";
      final response = await client.get(query);
      try {
        final Map<dynamic, dynamic> rawData = json.decode(response.toString());
        return rawData.entries
            .map((e) => global_model.SyncMasterStatusModel()
              ..tableName = e.key
              ..lastUpdate = e.value)
            .toList();
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverEmployee({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query = "/master-sync/list?lastupdate=$lastupdate&module=employee&offset=$offset&limit=$limit&action=all";
      final response = await client.get(query);
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverPrinter({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query = "/master-sync/list?lastupdate=$lastupdate&module=printer&offset=$offset&limit=$limit&action=all";
      final response = await client.get(query);
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverProductCategory({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query = "/master-sync/list?lastupdate=$lastupdate&module=productcategory&offset=$offset&limit=$limit&action=all";
      final response = await client.get(query);
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> serverProductBarcode({
    int limit = 0,
    int offset = 0,
    String lastupdate = '',
  }) async {
    Dio client = Client().init();

    try {
      String query = "/master-sync/list?lastupdate=$lastupdate&module=productbarcode&offset=$offset&limit=$limit&action=all";
      final response = await client.get(query);
      try {
        final rawData = json.decode(response.toString());
        if (rawData['error'] != null) {
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }
        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMasterBank() async {
    Dio client = Client().init();

    try {
      final response = await client.get('/paymentmaster');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().debug(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(ex);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMasterUpdate({int page = 1, int limit = 50, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/master-sync?lastUpdate=$time&page=$page&limit=$limit');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getInventoryFetchUpdate({int page = 0, int perPage = 1, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/inventory/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getCategoryFetchUpdate({int page = 0, int limit = 1, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/category/fetchupdate?lastUpdate=$time&page=$page&limit=$limit');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getMemberFetchUpdate({int page = 0, int perPage = 1, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/member/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getPrinterFetchUpdate({int page = 0, int perPage = 1, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/restaurant/printer/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getTableFetchUpdate({int page = 0, int perPage = 1, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/restaurant/table/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getZoneFetchUpdate({int page = 0, int perPage = 1, String time = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/restaurant/zone/fetchupdate?lastUpdate=$time&page=$page&limit=$perPage');
      try {
        final rawData = json.decode(response.toString());

        //   print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getCategoryList({
    int page = 0,
    int perPage = 20,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/category?page=$page&limit=$perPage&q=$search');
      try {
        final rawData = json.decode(response.toString());

        serviceLocator<Log>().trace(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getInventoryList({int page = 0, int perPage = 1, String search = ""}) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/inventory?page=$page&limit=$perPage&q=$search');
      try {
        final rawData = json.decode(response.toString());

        serviceLocator<Log>().trace(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getInventoryId(String id) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/inventory/$id');
      try {
        final rawData = json.decode(response.toString());

        serviceLocator<Log>().trace(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }

  Future<ApiResponse> getEmployeeList({
    int page = 0,
    int perPage = 20,
    String search = "",
  }) async {
    Dio client = Client().init();

    try {
      final response = await client.get('/employee?page=$page&limit=$perPage&q=$search');
      try {
        final rawData = json.decode(response.toString());

        //print(rawData);

        if (rawData['error'] != null) {
          String errorMessage = '${rawData['code']}: ${rawData['message']}';
          serviceLocator<Log>().error(errorMessage);
          throw Exception('${rawData['code']}: ${rawData['message']}');
        }

        return ApiResponse.fromMap(rawData);
      } catch (ex) {
        serviceLocator<Log>().error(ex);
        throw Exception(ex);
      }
    } on DioError catch (ex) {
      String errorMessage = ex.response.toString();
      serviceLocator<Log>().error(errorMessage);
      throw Exception(errorMessage);
    }
  }
}
