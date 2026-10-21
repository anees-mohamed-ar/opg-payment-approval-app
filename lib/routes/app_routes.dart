import 'package:get/get.dart';

import '../features/Aprovel/VoucherDetailsPage.dart';
import '../features/Aprovel/providers.dart';
import '../features/auth/Login_UI/login_view.dart';
import '../features/shell/main_shell.dart';

class AppRoutes {
  static const String login = '/login';
  static const String home = '/home';
  static const String voucherDetails = '/voucherDetails';

  static List<GetPage> routes = [
    GetPage(name: login, page: () => LoginView()),
    GetPage(name: home, page: () => const MainShell()),
    GetPage(
      name: voucherDetails,
      page: () {
        Get.lazyPut(() => POApprovalController());
        final args = Get.arguments as Map<String, dynamic>;
        return VoucherDetailsPage(
          voucherId: args['voucherId'] ?? '',
          amount: args['voucherAmount'] ?? 0.0,
        );
      },
    ),
  ];
}
