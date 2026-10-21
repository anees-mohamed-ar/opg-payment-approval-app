import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opg_pro/features/Aprovel/providers.dart';
import 'package:shimmer/shimmer.dart'; // Add this import

import '../../core/models/payment_model/Voucher.dart';
import '../../core/utils/date_utils.dart';
import '../../routes/app_routes.dart';

class POApprovalScreen extends StatelessWidget {
  final POApprovalController controller = Get.put(POApprovalController());
  late TextEditingController searchController;

  String _formatIndianCurrency(double amount) {
    String amountStr = amount.toStringAsFixed(2);
    List<String> parts = amountStr.split('.');
    String integerPart = parts[0];
    String decimalPart = parts[1];

    if (integerPart.length <= 3) {
      return '$integerPart.$decimalPart';
    }

    String lastThree = integerPart.substring(integerPart.length - 3);
    String rest = integerPart.substring(0, integerPart.length - 3);

    List<String> restParts = [];
    for (int i = rest.length; i > 0; i -= 2) {
      int start = (i - 2) < 0 ? 0 : i - 2;
      restParts.insert(0, rest.substring(start, i));
    }

    String formatted = '${restParts.join(',')},$lastThree.$decimalPart';
    return formatted;
  }

  Future<void> _showConfirmationDialog(bool isApprove) async {
    final remarksController = TextEditingController();

    final action = await Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_outline : Icons.highlight_off,
              color: isApprove ? Colors.green : Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              isApprove ? 'Approve Vouchers' : 'Reject Vouchers',
              style: GoogleFonts.publicSans(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Are you sure you want to approve the selected vouchers?'
                  : 'Are you sure you want to reject the selected vouchers?',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                height: 1.5,
              ),
            ),
            if (!isApprove) ...[
              const SizedBox(height: 16),
              TextField(
                controller: remarksController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason / Remarks',
                  hintText: 'Enter reason for rejection...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Get.back(result: false),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.close, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Cancel',
                  style: GoogleFonts.publicSans(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: isApprove ? Colors.green[50] : Colors.red[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Get.back(result: true),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isApprove ? Icons.check : Icons.block,
                  size: 18,
                  color: isApprove ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Confirm',
                  style: GoogleFonts.publicSans(
                    color: isApprove ? Colors.green : Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (action == true) {
      final selectedVouchers = controller.selectedItems.entries
          .where((entry) => entry.value)
          .map((entry) => controller.filteredData[entry.key])
          .toList();

      if (selectedVouchers.isEmpty) {
        Get.snackbar(
          'Info',
          'Please select at least one voucher',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.blueGrey,
          colorText: Colors.white,
          icon: const Icon(Icons.info_outline, color: Colors.white),
        );
        return;
      }

      final remarks = remarksController.text;

      // Show a progress dialog while processing
      showDialog(
        context: Get.context!,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text('Processing approvals...', style: GoogleFonts.publicSans()),
            ],
          ),
        ),
      );

      List<ApprovalResult> results = [];
      for (final voucher in selectedVouchers) {
        try {
          final result = await controller.approveVoucherWithResult(
            voucher,
            isApprove,
            remarks: isApprove ? null : remarks,
          );
          results.add(result);
        } catch (e) {
          results.add(ApprovalResult(
            voucherNumber: voucher.voucherNumber ?? 'Unknown',
            status: ApprovalStatus.unknown,
          ));
        }
      }
      Navigator.of(Get.context!).pop(); // Close progress dialog
      showDialog(
        context: Get.context!,
        builder: (context) => ApprovalResultDialog(results: results),
      );
    }
  }

  Widget _buildVoucherCard(Voucher voucher, int index) {
    return Obx(() {
      final isRejected = [
        voucher.level1,
        voucher.level2,
        voucher.level3,
        voucher.level4,
        voucher.level5,
        voucher.level6,
        voucher.level7,
      ].any((level) => level?.toLowerCase().contains('rejected') ?? false);

      final amount = controller.parseAmount(voucher.amount);
      final isSelected = controller.selectedItems[index] ?? false;
      final shouldShowCheckbox = !isRejected;

      return Container(
        width: MediaQuery.of(Get.context!).size.width / 2 - 24,
        margin: EdgeInsets.all(8),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: isRejected ? Colors.red[50] : null,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              Get.toNamed(
                AppRoutes.voucherDetails,
                arguments: {
                  'voucherId': voucher.voucherId ?? '',
                  'voucherData': voucher,
                  'voucherAmount':
                      double.tryParse(voucher.amount.toString()) ?? 0.0,
                },
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (shouldShowCheckbox)
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) =>
                              controller.toggleItemSelection(index),
                          activeColor: Color(0xFF8E6500),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      Expanded(
                        child: Row(
                          children: [
                            RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: ' Bank Payment',
                                    style: GoogleFonts.publicSans(
                                      fontSize:
                                          12, // Reduced size for "Bank Payment"
                                      color: isRejected
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ': ${voucher.voucherNumber ?? 'N/A'}',
                                    style: GoogleFonts.publicSans(
                                      fontWeight: FontWeight.bold,
                                      fontSize:
                                          14, // Original size for voucher number
                                      color: isRejected
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(width: 30),
                            Icon(Icons.calendar_today,
                                size: 14, color: Colors.orange),
                            SizedBox(width: 4),
                            Text(
                              DateUtilsHelper.formatDate(voucher.date ?? ''),
                              style: GoogleFonts.publicSans(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isRejected)
                        Icon(Icons.cancel, size: 18, color: Colors.red),
                    ],
                  ),
                  SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Row(
                      children: [
                        SizedBox(width: 4),
                        Expanded(
                          child: RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: 'TO:  ',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: voucher.ledgerName ?? 'N/A',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight
                                        .bold, // Normal weight for the rest
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Row(
                      children: [
                        // Amount section on the left
                        Icon(Icons.currency_rupee,
                            size: 14, color: Colors.green),
                        SizedBox(width: 1),
                        Text(
                          _formatIndianCurrency(amount),
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // This spacer pushes the Details button to the right
                        Expanded(child: SizedBox()),
                        // Enhanced Details button on the right
                        GestureDetector(
                          onTap: () {
                            Get.toNamed(
                              AppRoutes.voucherDetails,
                              arguments: {
                                'voucherId': voucher.voucherId ?? '',
                                'voucherData': voucher,
                                'voucherAmount': double.tryParse(
                                        voucher.amount.toString()) ??
                                    0.0,
                              },
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue
                                  .shade700, // Darker shade for better contrast
                              borderRadius: BorderRadius.circular(
                                  6), // Slightly larger radius
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 2,
                                  offset: Offset(0, 1),
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade600,
                                  Colors.blue.shade800
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.details,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Details',
                                  style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.w600, // Slightly bolder
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: List.generate(
            6, // Number of shimmer items
            (index) => Container(
              margin: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              height: 120,
              width: double.infinity,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoader() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Obx(
          () => controller.hasMoreData.value
              ? SizedBox.shrink()
              : Text(
                  'No more vouchers',
                  style: GoogleFonts.publicSans(color: Colors.grey),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final role = controller.userRole.value;
          final dept = controller.userDepartment.value;
          String headerText = 'Payment Approval';
          if (role.isNotEmpty && dept.isNotEmpty) {
            headerText = '$role ($dept)';
          } else if (role.isNotEmpty) {
            headerText = '$role - Payment Approval';
          } else if (dept.isNotEmpty) {
            headerText = '$dept - Payment Approval';
          }

          return Text(
            headerText,
            style: GoogleFonts.publicSans(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          );
        }),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFAC945C), Color(0xFF8A6E4F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 4,
      ),
      body: Obx(() {
        if (controller.isInitialLoad.value && controller.filteredData.isEmpty) {
          return _buildShimmerLoader();
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: controller
                    .searchController, // Use the controller from your GetX controller
                decoration: InputDecoration(
                  hintText: 'Search vouchers...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Obx(() {
                if (controller.filteredData.isEmpty) {
                  return const SizedBox.shrink();
                }
                final selectedCount = controller.selectedItems.values.where((v) => v).length;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: controller.isAllSelected,
                        onChanged: (val) => controller.toggleSelectAll(),
                        activeColor: const Color(0xFF8E6500),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Select All',
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Spacer(),
                      if (selectedCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFAC945C).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$selectedCount selected',
                            style: GoogleFonts.publicSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8E6500),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
              Expanded(
                child: Obx(() {
                  if (controller.filteredData.isEmpty &&
                      !controller.isInitialLoad.value) {
                    return Center(
                      child: Text(
                        'No vouchers available for approval at your level',
                        style: GoogleFonts.publicSans(fontSize: 16),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: controller.refreshData,
                    child: ListView.builder(
                      controller: controller.scrollController,
                      itemCount: controller.filteredData.length +
                          (controller.hasMoreData.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= controller.filteredData.length) {
                          return _buildLoader();
                        }
                        return _buildVoucherCard(
                            controller.filteredData[index], index);
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      }),
      floatingActionButton: Obx(() {
        if (controller.userRole.isEmpty || controller.filteredData.isEmpty) {
          return SizedBox.shrink();
        }

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () => _showConfirmationDialog(true),
              backgroundColor: Colors.green,
              child: Icon(Icons.check, color: Colors.white),
              heroTag: 'approveButton',
            ),
            SizedBox(height: 16),
            FloatingActionButton(
              onPressed: () => _showConfirmationDialog(false),
              backgroundColor: Colors.red,
              child: Icon(Icons.close, color: Colors.white),
              heroTag: 'rejectButton',
            ),
          ],
        );
      }),
    );
  }
}

class ApprovalResultDialog extends StatelessWidget {
  final List<ApprovalResult> results;
  const ApprovalResultDialog({Key? key, required this.results})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Wider, fixed-height, scrollable dialog with vertical detail layout
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700, // Increased width
        height: 400, // Fixed height
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.assignment_turned_in, color: Colors.blue, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Text('Approval Report',
                      style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => Divider(),
                  itemBuilder: (context, i) {
                    final r = results[i];
                    IconData icon;
                    Color color;
                    String statusText;
                    if (r.status == ApprovalStatus.pushedToTally) {
                      icon = Icons.cloud_done;
                      color = Colors.deepPurple;
                      statusText = 'Pushed to Tally';
                    } else if (r.status == ApprovalStatus.approved) {
                      icon = Icons.check_circle;
                      color = Colors.green;
                      statusText = 'Approved (not final)';
                    } else if (r.status == ApprovalStatus.rejected) {
                      icon = Icons.cancel;
                      color = Colors.red;
                      statusText = 'Rejected';
                    } else {
                      icon = Icons.info_outline;
                      color = Colors.grey;
                      statusText = 'Unknown';
                    }
                    final date = r.voucherDate ?? '-';
                    final amount = r.voucherAmount != null
                        ? '₹${r.voucherAmount!.toStringAsFixed(2)}'
                        : '-';
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Icon(icon, color: color, size: 32),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Voucher: ${r.voucherNumber}',
                                style: GoogleFonts.publicSans(
                                    fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: GoogleFonts.publicSans(
                                          fontSize: 13,
                                          color: color,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              // Replace this Row with a Wrap to prevent overflow
                              Wrap(
                                spacing: 24,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today,
                                      size: 14, color: Colors.orange),
                                  Text(
                                    date,
                                    style: GoogleFonts.publicSans(fontSize: 13),
                                  ),
                                  Icon(Icons.currency_rupee,
                                      size: 14, color: Colors.green),
                                  Text(
                                    amount,
                                    style: GoogleFonts.publicSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close',
                    style: GoogleFonts.publicSans(
                        fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ApprovalStatus { approved, pushedToTally, rejected, unknown }

class ApprovalResult {
  final String voucherNumber;
  final ApprovalStatus status;
  final String? voucherDate;
  final double? voucherAmount;
  ApprovalResult(
      {required this.voucherNumber,
      required this.status,
      this.voucherDate,
      this.voucherAmount});
}
