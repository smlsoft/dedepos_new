// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncCustomerDisplayModel _$SyncCustomerDisplayModelFromJson(
        Map<String, dynamic> json) =>
    SyncCustomerDisplayModel(
      code: json['code'] as String,
      phone: json['phone'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$SyncCustomerDisplayModelToJson(
        SyncCustomerDisplayModel instance) =>
    <String, dynamic>{
      'code': instance.code,
      'phone': instance.phone,
      'name': instance.name,
    };

SyncDeviceModel _$SyncDeviceModelFromJson(Map<String, dynamic> json) =>
    SyncDeviceModel(
      device: json['device'] as String,
      ip: json['ip'] as String,
      connected: json['connected'] as bool,
      isCashierTerminal: json['isCashierTerminal'] as bool,
      isClient: json['isClient'] as bool,
      holdNumberActive: json['holdNumberActive'] as int,
      docModeActive: json['docModeActive'] as int,
      processSuccess: json['processSuccess'] as bool? ?? true,
    );

Map<String, dynamic> _$SyncDeviceModelToJson(SyncDeviceModel instance) =>
    <String, dynamic>{
      'device': instance.device,
      'ip': instance.ip,
      'connected': instance.connected,
      'isCashierTerminal': instance.isCashierTerminal,
      'isClient': instance.isClient,
      'holdNumberActive': instance.holdNumberActive,
      'docModeActive': instance.docModeActive,
      'processSuccess': instance.processSuccess,
    };

SyncStaffDeviceModel _$SyncStaffDeviceModelFromJson(
        Map<String, dynamic> json) =>
    SyncStaffDeviceModel(
      serverShopId: json['serverShopId'] as String,
      serverIp: json['serverIp'] as String,
      clientName: json['clientName'] as String,
      clientGuid: json['clientGuid'] as String,
      clientIp: json['clientIp'] as String,
    );

Map<String, dynamic> _$SyncStaffDeviceModelToJson(
        SyncStaffDeviceModel instance) =>
    <String, dynamic>{
      'serverShopId': instance.serverShopId,
      'serverIp': instance.serverIp,
      'clientName': instance.clientName,
      'clientGuid': instance.clientGuid,
      'clientIp': instance.clientIp,
    };
