import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/models/payment_model/Voucher.dart';
import '../../core/utils/date_utils.dart';
import '../../core/theme/app_typography.dart';
import '../../routes/app_routes.dart';
import '../Report/po_details_report_provider.dart';
import '../home/logic/home_controller.dart';
import 'po_approval_screen.dart';
import 'providers.dart';

/// Exported alias used by MainShell
class InboxTab extends StatelessWidget {
  const InboxTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const InboxScreen();
}

class InboxScreen extends StatefulWidget {
  const InboxScreen({Key? key}) : super(key: key);

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final POApprovalController controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    controller = Get.isRegistered<POApprovalController>()
        ? Get.find<POApprovalController>()
        : Get.put(POApprovalController());
    _searchController.addListener(() {
      controller.searchController.text = _searchController.text;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCompactHeader(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PendingList(controller: controller),
              _RejectedList(controller: controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          // Minimal Search Input
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                style: getAppleStyle(fontSize: 13, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: getAppleStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFAC945C), size: 18),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            controller.searchController.clear();
                          },
                          child: const Icon(Icons.clear, size: 16, color: Colors.grey),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 30),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFAC945C), width: 1.2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Compact Segmented Tabs
          Obx(() {
            final allVouchers = controller.filteredData;
            final pending = allVouchers.where((v) => !_isRejected(v)).toList();
            final rejected = allVouchers.where((v) => _isRejected(v)).toList();

            return Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: const Color(0xFFAC945C),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey.shade700,
                labelPadding: const EdgeInsets.symmetric(horizontal: 10),
                labelStyle: getAppleStyle(fontWeight: FontWeight.w600, fontSize: 12),
                unselectedLabelStyle: getAppleStyle(fontWeight: FontWeight.w500, fontSize: 12),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    height: 32,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Pending'),
                        if (pending.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${pending.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    height: 32,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Rejected'),
                        if (rejected.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${rejected.length}',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  bool _isRejected(Voucher v) {
    return [
      v.level1, v.level2_1, v.level2_2, v.level2_3,
      v.level3, v.level4, v.level5, v.level6, v.level7,
    ].any((l) => (l?.toLowerCase() ?? '').contains('rejected'));
  }
}

// ─── Pending List ────────────────────────────────────────────────────────────

class _PendingList extends StatelessWidget {
  final POApprovalController controller;
  const _PendingList({required this.controller});

  bool _isRejected(Voucher v) => [
        v.level1, v.level2_1, v.level2_2, v.level2_3,
        v.level3, v.level4, v.level5, v.level6, v.level7,
      ].any((l) => (l?.toLowerCase() ?? '').contains('rejected'));

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isInitialLoad.value && controller.filteredData.isEmpty) {
        return _buildShimmer();
      }

      final pending = controller.filteredData
          .where((v) => !_isRejected(v))
          .toList();

      if (pending.isEmpty) {
        return _buildEmptyState(
          icon: Icons.check_circle_outline_rounded,
          color: const Color(0xFF059669),
          title: 'All caught up!',
          subtitle: 'No pending approvals for you right now.',
        );
      }

      return Stack(
        children: [
          Column(
            children: [
              _buildCompactSelectAllBar(context, pending),
              Expanded(
                child: RefreshIndicator(
                  color: const Color(0xFFAC945C),
                  onRefresh: controller.refreshData,
                  child: ListView.builder(
                    controller: controller.scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
                    itemCount:
                        pending.length + (controller.isLoadingMore.value ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= pending.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFFAC945C))),
                        );
                      }
                      final voucher = pending[i];
                      final globalIndex =
                          controller.filteredData.indexOf(voucher);
                      return _PendingVoucherCard(
                        voucher: voucher,
                        index: globalIndex,
                        controller: controller,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            right: 18,
            bottom: 66 + MediaQuery.of(context).padding.bottom,
            child: _buildFloatingActionBar(context, pending),
          ),
        ],
      );
    });
  }

  Widget _buildCompactSelectAllBar(BuildContext context, List<Voucher> pending) {
    return Obx(() {
      final selectedCount =
          controller.selectedItems.values.where((v) => v).length;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => controller.toggleSelectAll(),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 20,
                    width: 20,
                    child: Checkbox(
                      value: controller.isAllSelected,
                      onChanged: (_) => controller.toggleSelectAll(),
                      activeColor: const Color(0xFFAC945C),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Select All',
                    style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: const Color(0xFF475569)),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (selectedCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFAC945C).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedCount selected',
                  style: GoogleFonts.publicSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF8E6500)),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFloatingActionBar(BuildContext context, List<Voucher> pending) {
    return Obx(() {
      final selected =
          controller.selectedItems.values.where((v) => v).length;
      if (selected == 0) return const SizedBox.shrink();
      return AnimatedScale(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        scale: selected > 0 ? 1.0 : 0.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingIconActionButton(
              tooltip: 'Approve ($selected)',
              icon: Icons.check_rounded,
              color: const Color(0xFF10B981),
              onTap: () => _showActionDialog(context, true, controller),
            ),
            const SizedBox(height: 10),
            _FloatingIconActionButton(
              tooltip: 'Reject ($selected)',
              icon: Icons.close_rounded,
              color: const Color(0xFFEF4444),
              onTap: () => _showActionDialog(context, false, controller),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showActionDialog(
      BuildContext context, bool isApprove, POApprovalController controller) async {
    final remarksCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Icon(isApprove ? Icons.check_circle_outline : Icons.highlight_off,
              color: isApprove ? const Color(0xFF059669) : Colors.red),
          const SizedBox(width: 10),
          Text(isApprove ? 'Approve Vouchers' : 'Reject Vouchers',
              style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isApprove
                  ? 'Approve all selected vouchers?'
                  : 'Reject all selected vouchers?',
              style: GoogleFonts.publicSans(fontSize: 14),
            ),
            if (!isApprove) ...[
              const SizedBox(height: 14),
              TextField(
                controller: remarksCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason (optional)',
                  hintText: 'Enter reason...',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('Cancel',
                  style: GoogleFonts.publicSans(color: Colors.grey[700]))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isApprove ? const Color(0xFF059669) : Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Confirm',
                style: GoogleFonts.publicSans(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final selectedVouchers = controller.selectedItems.entries
          .where((e) => e.value)
          .map((e) => controller.filteredData[e.key])
          .toList();

      if (selectedVouchers.isEmpty) return;

      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          content: Row(children: [
            const CircularProgressIndicator(color: Color(0xFFAC945C)),
            const SizedBox(width: 16),
            Text('Processing...', style: GoogleFonts.publicSans()),
          ]),
        ),
      );

      int successCount = 0;
      for (final v in selectedVouchers) {
        final result = await controller.approveVoucherWithResult(
          v,
          isApprove,
          remarks: isApprove ? null : remarksCtrl.text,
        );
        if (result.status == ApprovalStatus.approved ||
            result.status == ApprovalStatus.pushedToTally ||
            result.status == ApprovalStatus.rejected) {
          successCount++;
        }
      }

      // Refresh other controllers to keep dashboard & history in sync
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchDashboardStats();
      }
      if (Get.isRegistered<PaymentVoucherController>()) {
        Get.find<PaymentVoucherController>().refreshVouchers();
      }

      Navigator.of(Get.context!).pop();
      if (successCount > 0) {
        Get.snackbar(
          isApprove ? 'Approved' : 'Rejected',
          '$successCount voucher(s) ${isApprove ? 'approved' : 'rejected'} successfully.',
          backgroundColor: isApprove ? const Color(0xFF059669) : Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          borderRadius: 12,
          margin: const EdgeInsets.all(16),
        );
      }
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          height: 90,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      {required IconData icon,
      required Color color,
      required String title,
      required String subtitle}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: color.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(title,
              style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B))),
          const SizedBox(height: 6),
          Text(subtitle,
              style:
                  GoogleFonts.publicSans(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Pending Voucher Card ─────────────────────────────────────────────────────

class _PendingVoucherCard extends StatelessWidget {
  final Voucher voucher;
  final int index;
  final POApprovalController controller;

  const _PendingVoucherCard({
    required this.voucher,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isSelected = controller.selectedItems[index] ?? false;
      final amount = controller.parseAmount(voucher.amount);

      return GestureDetector(
        onLongPress: () => controller.toggleItemSelection(index),
        onTap: () => Get.toNamed(
          AppRoutes.voucherDetails,
          arguments: {
            'voucherId': voucher.voucherId ?? '',
            'voucherAmount': amount,
          },
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFFEF3C7)
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFAC945C)
                  : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Checkbox
                GestureDetector(
                  onTap: () => controller.toggleItemSelection(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFAC945C)
                          : Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFAC945C)
                            : Colors.grey.shade400,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check,
                            color: Colors.white, size: 16)
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Voucher #${voucher.voucherNumber ?? 'N/A'}',
                              style: getAppleStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            DateUtilsHelper.formatDate(voucher.date ?? ''),
                            style: getAppleStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              voucher.ledgerName ?? 'Unknown Payee',
                              style: getAppleStyle(
                                fontSize: 13.5,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (voucher.department != null &&
                              voucher.department!.trim().isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFAC945C).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFAC945C)
                                        .withOpacity(0.3)),
                              ),
                              child: Text(
                                voucher.department!.trim(),
                                style: getAppleStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8A6E40),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '₹${_formatIndian(amount)}',
                              style: GoogleFonts.publicSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF065F46),
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_rounded,
                              color: Color(0xFFAC945C), size: 20),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  String _formatIndian(double amount) {
    final formatter = NumberFormat.currency(
      symbol: '',
      decimalDigits: 0,
      locale: 'en_IN',
    );
    return formatter.format(amount).trim();
  }
}

// ─── Rejected List ────────────────────────────────────────────────────────────

class _RejectedList extends StatelessWidget {
  final POApprovalController controller;
  const _RejectedList({required this.controller});

  bool _isRejected(Voucher v) => [
        v.level1, v.level2_1, v.level2_2, v.level2_3,
        v.level3, v.level4, v.level5, v.level6, v.level7,
      ].any((l) => (l?.toLowerCase() ?? '').contains('rejected'));

  String _getRejectionReason(Voucher v) {
    final levels = [
      v.level1, v.level2_1, v.level2_2, v.level2_3,
      v.level3, v.level4, v.level5, v.level6, v.level7,
    ];
    for (final l in levels) {
      if ((l?.toLowerCase() ?? '').contains('rejected')) {
        // Extract reason if present
        final reasonMatch = RegExp(r'\(Reason: (.+?)\)', caseSensitive: false)
            .firstMatch(l ?? '');
        if (reasonMatch != null) return reasonMatch.group(1) ?? '';
        return l ?? '';
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isInitialLoad.value && controller.filteredData.isEmpty) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFFAC945C)));
      }

      final rejected = controller.filteredData
          .where((v) => _isRejected(v))
          .toList();

      if (rejected.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.thumb_up_outlined,
                  size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No rejected vouchers',
                  style: GoogleFonts.publicSans(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text('Vouchers rejected by you will appear here.',
                  style: GoogleFonts.publicSans(
                      fontSize: 13, color: Colors.grey.shade500),
                  textAlign: TextAlign.center),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: rejected.length,
        itemBuilder: (ctx, i) {
          final v = rejected[i];
          final reason = _getRejectionReason(v);
          final amount = controller.parseAmount(v.amount);
          return GestureDetector(
            onTap: () => Get.toNamed(
              AppRoutes.voucherDetails,
              arguments: {
                'voucherId': v.voucherId ?? '',
                'voucherAmount': amount,
              },
            ),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cancel_rounded,
                            color: Colors.red, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voucher #${v.voucherNumber ?? 'N/A'}',
                              style: GoogleFonts.publicSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: const Color(0xFF0F172A)),
                            ),
                            Text(
                              v.ledgerName ?? 'Unknown Payee',
                              style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${_formatIndian(amount)}',
                            style: GoogleFonts.publicSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            DateUtilsHelper.formatDate(v.date ?? ''),
                            style: GoogleFonts.publicSans(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Colors.red, size: 15),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              reason,
                              style: GoogleFonts.publicSans(
                                fontSize: 12,
                                color: Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Tap to view details →',
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  String _formatIndian(double amount) {
    final formatter =
        NumberFormat.currency(symbol: '', decimalDigits: 0, locale: 'en_IN');
    return formatter.format(amount).trim();
  }
}

// ─── Action Button ─────────────────────────────────────────────────────────────

class _FloatingIconActionButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FloatingIconActionButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
        ),
      ),
    );
  }
}
