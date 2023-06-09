import 'package:dedepos/bloc/bill_bloc.dart';
import 'package:dedepos/model/objectbox/bill_struct.dart';
import 'package:dedepos/features/pos/presentation/screens/pos_cancel_bill_detail.dart';
import 'package:dedepos/features/pos/presentation/screens/pos_util.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedepos/global.dart' as global;

class PosCancelBillScreen extends StatefulWidget {
  @override
  const PosCancelBillScreen({Key? key}) : super(key: key);

  @override
  State<PosCancelBillScreen> createState() => _PosCancelBillScreenState();
}

class _PosCancelBillScreenState extends State<PosCancelBillScreen> {
  List<BillObjectBoxStruct> dataList = [];

  @override
  void initState() {
    super.initState();
    context.read<BillBloc>().add(BillLoad());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BillBloc, BillState>(
      builder: (context, state) {
        if (state is BillLoadSuccess) {
          context.read<BillBloc>().add(BillLoadFinish());
          dataList = state.result;
        }
        return Scaffold(
            appBar: AppBar(
              title: Text(global.language("cancel_bill")),
            ),
            body: Padding(
              padding: const EdgeInsets.all(10),
              child: GridView.builder(
                itemCount: dataList.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 250,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2,
                ),
                itemBuilder: (context, index) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: (dataList[index].is_cancel)
                          ? Colors.red.shade100
                          : Colors.blue.shade100,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PosCancelBillDetailScreen(
                              docNumber: dataList[index].doc_number),
                        ),
                      );
                    },
                    child: posBill(dataList[index]),
                  );
                },
              ),
            ));
      },
    );
  }
}
