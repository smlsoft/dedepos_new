class FindPriceStruct {
  final int price_type; // 1=Barcode,2=Unit Code
  final String unit_code;
  final String unit_name;
  final String barcode;
  final double price;

  const FindPriceStruct(
      {this.price_type = 0,
      this.unit_code = '',
      this.unit_name = '',
      this.barcode = '',
      this.price = 0});
}
