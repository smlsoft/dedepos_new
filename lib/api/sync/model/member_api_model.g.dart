// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'member_api_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MemberApiModel _$MemberApiModelFromJson(Map<String, dynamic> json) =>
    MemberApiModel(
      guidfixed: json['guidfixed'] as String? ?? "",
      address: json['address'] as String? ?? "",
      branchcode: json['branchcode'] as String? ?? "",
      branchtype: json['branchtype'] as int,
      contacttype: json['contacttype'] as int,
      name: json['name'] as String,
      personaltype: json['personaltype'] as int,
      surname: json['surname'] as String? ?? "",
      taxid: json['taxid'] as String? ?? "",
      telephone: json['telephone'] as String? ?? "",
      zipcode: json['zipcode'] as String? ?? "",
    );

Map<String, dynamic> _$MemberApiModelToJson(MemberApiModel instance) =>
    <String, dynamic>{
      'guidfixed': instance.guidfixed,
      'address': instance.address,
      'branchcode': instance.branchcode,
      'branchtype': instance.branchtype,
      'contacttype': instance.contacttype,
      'name': instance.name,
      'personaltype': instance.personaltype,
      'surname': instance.surname,
      'taxid': instance.taxid,
      'telephone': instance.telephone,
      'zipcode': instance.zipcode,
    };
