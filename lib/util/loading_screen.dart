import 'dart:async';
import 'package:dedepos/api/sync/master/sync_master.dart';
import 'package:flutter/material.dart';
import 'package:dedepos/global.dart' as global;
import 'package:loading_animation_widget/loading_animation_widget.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? timerSwitchToMenu;

  void init() async {
    // await global.appStorage.remove(global.syncPrinterTimeName);
    // await global.appStorage.remove(global.syncCategoryTimeName);
    // await global.appStorage.remove(global.syncInventoryTimeName);
    // await global.appStorage.remove(global.syncMemberTimeName);
    // await global.appStorage.remove(global.syncEmployeeTimeName);
    // await global.appStorage.remove(global.syncTableTimeName);
    // await global.appStorage.remove(global.syncTableZoneTimeName);
    // await global.appStorage.remove(global.syncDeviceTimeName);

    if (global.appMode == global.AppModeEnum.posRemote) {
      Timer(const Duration(seconds: 1), () {
        Navigator.of(context).pushReplacementNamed('client');
      });
    } else {
      timerSwitchToMenu = Timer.periodic(const Duration(seconds: 1), (timer) async {
        if (global.loginSuccess && global.syncDataSuccess) {
          Navigator.of(context).pushReplacementNamed('menu');
        }
        setState(() {});
      });
      syncMasterProcess();
    }
  }

  @override
  void dispose() {
    timerSwitchToMenu?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  @override
  Widget build(BuildContext context) {
    global.getDeviceModel(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                LoadingAnimationWidget.staggeredDotsWave(
                  color: Colors.blue,
                  size: 200,
                ),
                const SizedBox(
                  height: 10,
                ),
                Text(global.language("sync_data")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
