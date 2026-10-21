import 'dart:async';
import 'package:get/get.dart';
import '../../Aprovel/providers.dart';

class HomeController extends GetxController {
  // Dashboard Metrics
  var pendingApprovalsCount = 0.obs;
  var totalAmount = 0.0.obs;
  var isLoadingStats = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    if (isLoadingStats.value) return;
    try {
      isLoadingStats.value = true;
      final approvalController = Get.isRegistered<POApprovalController>()
          ? Get.find<POApprovalController>()
          : Get.put(POApprovalController());

      await approvalController.loadUserRole();
      final vouchers = await approvalController.fetchVoucherData(1);

      pendingApprovalsCount.value = vouchers.length;

      double sum = 0.0;
      for (var v in vouchers) {
        sum += double.tryParse(v.amount?.replaceAll(',', '') ?? '0') ?? 0.0;
      }
      totalAmount.value = sum;
    } catch (e) {
      print('Error fetching dashboard stats: $e');
    } finally {
      isLoadingStats.value = false;
    }
  }
}
