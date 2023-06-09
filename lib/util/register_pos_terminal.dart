import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:dedepos/api/clickhouse/clickhouse_api.dart';
import 'package:dedepos/core/request.dart';
import 'package:dedepos/core/service_locator.dart';
import 'package:dedepos/features/authentication/auth.dart';
import 'package:dedepos/features/shop/shop.dart';
import 'package:dedepos/global_model.dart';
import 'package:dedepos/routes/app_routers.dart';
import 'package:dedepos/services/user_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:dedepos/global.dart' as global;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

@RoutePage()
class RegisterPosTerminalPage extends StatefulWidget {
  const RegisterPosTerminalPage({Key? key}) : super(key: key);
  @override
  _RegisterPosTerminalPageState createState() =>
      _RegisterPosTerminalPageState();
}

class _RegisterPosTerminalPageState extends State<RegisterPosTerminalPage> {
  late Timer findTerminalTimer;

  @override
  void initState() {
    super.initState();
    if (global.posTerminalPinCode.isEmpty) {
      initPinCode();
    } else {
      checkPinCode();
    }
    findTerminalTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      var responseData = await clickHouseSelect(
          "SELECT status,token,deviceid,access_token,shipid FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'");
      ResponseDataModel result = ResponseDataModel.fromJson(responseData);
      if (result.data.isNotEmpty) {
        if (result.data[0]['status'] == 1) {
          global.posTerminalPinTokenId = result.data[0]['token'];
          global.deviceId = result.data[0]['deviceid'];

          SharedPreferences sharedPreferences =
              await SharedPreferences.getInstance();
          sharedPreferences.setString(
              'pos_terminal_token', global.posTerminalPinTokenId);
          sharedPreferences.setString('pos_device_id', global.deviceId);

          // do authen with token
          String accessToken = result.data[0]['access_token'];
          String shopId = result.data[0]['shipid'];
          serviceLocator<Request>().updateAuthorization(accessToken);

          serviceLocator<LoginUserRepository>()
              .profile()
              .then((response) async {
            if (response.isRight()) {
              // save user cache
              User remoteUser = response.getOrElse(() => User());
              remoteUser = remoteUser.copyWith(token: accessToken);

              await serviceLocator<UserCacheService>().saveUser(remoteUser);
              // select shop
              serviceLocator<ShopAuthenticationRepository>()
                  .selectShop(shopid: shopId)
                  .then((selectShopResponse) async {
                if (selectShopResponse.isRight()) {
                  global.loginSuccess = true;
                  // add user autenticate bloc
                  context
                      .read<AuthenticationBloc>()
                      .add(AuthenticationEvent.authenticated(user: remoteUser));

                  if (mounted) {
                    context.router.pushAndPopUntil(const LoginByEmployeeRoute(),
                        predicate: (route) => false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Failed Not Selected Shop"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              });
            }
          });
        }
      }
    });
  }

  Future<void> checkPinCode() async {
    // ตรวจสอบว่า ClickHouse ไม่มี PinCode เพิ่มให้ใหม่
    var responseData = await clickHouseSelect(
        "SELECT status,token,deviceid FROM poscenter.pinlist WHERE pincode='${global.posTerminalPinCode}'");
    ResponseDataModel result = ResponseDataModel.fromJson(responseData);
    if (result.data.isEmpty) {
      await clickHouseExecute(
          "INSERT INTO poscenter.pinlist (pincode,status) VALUES ('${global.posTerminalPinCode}',0)");
    }
  }

  Future<void> initPinCode() async {
    global.posTerminalPinCode = global.generateRandomPin(8);
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.setString(
        'pos_terminal_pin_code', global.posTerminalPinCode);
    await clickHouseExecute(
        "INSERT INTO poscenter.pinlist (pincode,status) VALUES ('${global.posTerminalPinCode}',0)");
    setState(() {});
  }

  @override
  void dispose() {
    findTerminalTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text("ลงทะเบียนเครื่อง POS Terminal",
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),
                        const Text(
                            "กรุณาแจ้ง รหัสด้านล่างไปยัง Admin แล้วรอการตอบกลับ"),
                        const Text(
                            "เมื่อได้รับอนุมติ โปรแกรมจะเข้าสู่ระบบ Login อัตโนมัติ"),
                        const SizedBox(height: 50),
                        Row(
                          children: [
                            for (var pinChar
                                in global.posTerminalPinCode.split(''))
                              Expanded(
                                  child: Container(
                                      margin: const EdgeInsets.all(5),
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                          color: Colors.white,
                                          border:
                                              Border.all(color: Colors.black),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius: 5,
                                              offset: Offset(0,
                                                  3), // changes position of shadow
                                            ),
                                          ]),
                                      child: Text(pinChar,
                                          textAlign: TextAlign.center,
                                          style:
                                              const TextStyle(fontSize: 30))))
                          ],
                        ),
                        const SizedBox(height: 50),
                        const Text("กรณีต้องการเปลี่ยนเครื่องไปใช้ข้อมูลอื่น"),
                        const Text(
                            "ให้กดปุ่ม ลงทะเบียนใหม่ แล้วแจ้ง Admin เพื่ออนุมัติการลงทะเบียนใหม่"),
                        const SizedBox(height: 10),
                        ElevatedButton(
                            onPressed: () async {
                              await initPinCode();
                            },
                            child: const Text("ลงทะเบียนใหม่")),
                      ],
                    )))));
  }
}
