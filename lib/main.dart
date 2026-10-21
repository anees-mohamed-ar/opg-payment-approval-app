import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/theme/app_typography.dart';
import 'features/auth/Login_UI/login_view.dart';
import 'features/auth/apiService/api_service.dart';
import 'features/auth/logic/login_bloc.dart';
import 'features/shell/main_shell.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('userId');
  final isLoggedIn = userId != null && userId.isNotEmpty;

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({Key? key, required this.isLoggedIn}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'OPG Payment Approval',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: createAppleTextTheme(Theme.of(context).textTheme),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFAC945C),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      getPages: AppRoutes.routes,
      initialRoute: isLoggedIn ? AppRoutes.home : null,
      home: isLoggedIn
          ? const MainShell()
          : BlocProvider(
              create: (context) => LoginBloc(apiService: ApiService()),
              child: LoginView(),
            ),
    );
  }
}
