import 'package:auto_route/auto_route.dart';
import 'package:dedepos/app/app.dart';
import 'package:dedepos/core/core.dart';
import 'package:dedepos/core/environment.dart';
import 'package:dedepos/features/authentication/auth.dart';
import 'package:dedepos/features/shop/shop.dart';
import 'package:dedepos/flavors.dart';
import 'package:dedepos/routes/app_routers.dart';
import 'package:dedepos/services/user_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dedepos/global.dart' as global;

@RoutePage()
class AuthenticationPage extends StatefulWidget {
  const AuthenticationPage({super.key});

  @override
  State<AuthenticationPage> createState() => _AuthenticationPageState();
}

class _AuthenticationPageState extends State<AuthenticationPage> {
  final TextEditingController _emailController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');

  Color vfPrimaryColor = const Color(0xFF007BFF);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(clipBehavior: Clip.antiAlias, children: [
      const BackgroundGradientWidget(),
      const BackgroundClipperWidget(),
      Center(
        child: Container(
          width: 500,
          height: 600,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 7,
                offset: const Offset(0, 3), // changes position of shadow
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: BlocConsumer<AuthenticationBloc, AuthenticationState>(
                listener: (context, state) {
                  if (state is AuthenticationLoadedState) {
                    //context.router.push(const SelectShopRoute());

                    global.appStorage.write("apiUserName", _emailController.text);
                    global.appStorage.write("apiUserPassword", _passwordController.text);
                    global.appStorage.write("token", state.user.token);
                    context.router.pushAndPopUntil(const SelectShopRoute(), predicate: (route) => false);
                  } else if (state is AuthenticationAuthenticatedState) {
                    global.appStorage.write("token", state.user.token);
                    context.router.pushAndPopUntil(const InitShopRoute(), predicate: (route) => false);
                  } else if (state is AuthenticationErrorState) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else if (state is AuthenticationInitialState) {
                    serviceLocator<Log>().debug("stage change to AuthenticationInitialState");
                  }
                },
                builder: (context, state) {
                  if (state is AuthenticationLoadingState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        logo(),
                        const SizedBox(
                          height: 13.0,
                          width: 200,
                        ),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    );
                  }
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      logo(),
                      const SizedBox(height: 12.0),
                      userTextfield(),
                      const SizedBox(height: 12.0),
                      passwordTextfield(),
                      const SizedBox(height: 12.0),
                      buttonLogin(),
                      const SizedBox(height: 12.0),
                      loginSeparatorLine(),
                      const SizedBox(height: 12.0),
                      buttonLoginWithGoogle(),
                      const SizedBox(height: 12.0),
                      buttonLoginWithApple(),
                      const SizedBox(height: 12.0),
                      Visibility(visible: Environment().isDev, child: buttonLoginDev()),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      )
    ]));
  }

  Widget logo() {
    if (F.appFlavor == Flavor.VFPOS) {
      return Image.asset(
        'assets/icons/vf-pos-logo.png', // path to your image asset
        height: 150.0,
      );
    }

    return Image.asset(
      'assets/icons/dede-pos-icon.png', // path to your image asset
      height: 150.0,
    );
  }

  Widget userTextfield() {
    return TextField(
      controller: _emailController,
      decoration: const InputDecoration(
        hintText: 'Username',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget passwordTextfield() {
    return TextField(
      controller: _passwordController,
      decoration: const InputDecoration(
        hintText: 'Password',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(8.0),
          ),
        ),
      ),
      obscureText: true,
    );
  }

  Widget buttonLogin() {
    return ElevatedButton.icon(
      onPressed: () {
        // on click
        debugPrint('on login debug  ${_emailController.text} ${_passwordController.text}');

        final userName = _emailController.text;
        final password = _passwordController.text;
        context.read<AuthenticationBloc>().add(AuthenticationEvent.onLoginWithUserPasswordTapped(userName: userName, password: password));
      },
      icon: const Icon(Icons.person),
      label: const Text('Login'),
      style: Styles.successButtonStyle(),
    );
  }

  Widget buttonLoginWithGoogle() {
    return ElevatedButton.icon(
      onPressed: () {
        // on click
        context.read<AuthenticationBloc>().add(const LoginWithGoogleEvent());
      },
      icon: const Icon(Icons.mail_outline),
      label: const Text('Login with Google'),
      style: Styles.successButtonStyle(),
    );
  }

  Widget buttonLoginWithOther() {
    return ElevatedButton.icon(
      onPressed: () {
        // on click
        // context.router.push(const AuthenticationWithUserPasswordRoute());
      },
      icon: const Icon(Icons.mail_outline),
      label: const Text('Login with User/Password'),
      style: Styles.successButtonStyle(),
    );
  }

  Widget buttonLoginWithApple() {
    return ElevatedButton.icon(
      onPressed: () {
        // on click
        // context.router.push(const AuthenticationWithUserPasswordRoute());
      },
      icon: const Icon(Icons.mail_outline),
      label: const Text('Login with Apple'),
      style: Styles.successButtonStyle(),
    );
  }

  Widget buttonLoginDev() {
    return ElevatedButton.icon(
      onPressed: () {
        // on click
        // context.router.push(const AuthenticationWithUserPasswordRoute());
        // add select shop event
        loginDev();
      },
      icon: const Icon(Icons.mail_outline),
      label: const Text('Login Auto'),
      style: Styles.successButtonStyle(),
    );
  }

  Widget loginSeparatorLine() {
    return Padding(
      padding: const EdgeInsets.only(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[horizontalLine(), const Text(" OR "), horizontalLine()],
      ),
    );
  }

  Widget horizontalLine() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: 100,
          height: 1.0,
          color: Colors.black.withOpacity(0.6),
        ),
      );

  void loginDev() {
    // authen with dev user,dev password
    serviceLocator<LoginUserRepository>().loginWithUserPassword(username: AppConstant.userDev, password: AppConstant.passwordDev).then((response) async {
      if (response.isRight()) {
        final remoteUser = response.getOrElse(() => User());
        await serviceLocator<UserCacheService>().saveUser(remoteUser);

        // select shop
        serviceLocator<ShopAuthenticationRepository>().selectShop(shopid: AppConstant.shopIdDev).then((selectShopResponse) async {
          if (selectShopResponse.isRight()) {
            global.loginSuccess = true;
            context.read<AuthenticationBloc>().add(AuthenticationEvent.authenticated(user: remoteUser));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Auto Login Failed."),
                backgroundColor: Colors.red,
              ),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Auto Login Failed."),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}
