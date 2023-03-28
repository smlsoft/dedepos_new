// ignore_for_file: non_constant_identifier_names
import 'package:json_annotation/json_annotation.dart';

part 'sale_invoice.g.dart';

@JsonSerializable()
class SaleInvoice {
  late DateTime date_time;
  late String doc_number;
  late String customer_code;
  late String customer_name;
  late String customer_telephone;
  late double total_amount;
  late String person_code;
  late String person_name;
  late String createDatetime;
  late int issync = 0;
  late String syncdatetime;

  SaleInvoice({
    this.doc_number = "",
    this.customer_code = "",
    this.customer_name = "",
    this.customer_telephone = "",
    this.total_amount = 0,
    this.person_code = "",
    this.person_name = "",
    this.createDatetime = "",
    this.issync = 0,
    this.syncdatetime = "",
  }) : this.date_time = DateTime.now();

  factory SaleInvoice.fromJson(Map<String, dynamic> json) =>
      _$SaleInvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$SaleInvoiceToJson(this);
}
