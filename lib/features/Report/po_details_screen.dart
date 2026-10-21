import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:opg_pro/features/Report/po_details_report_provider.dart';

import '../../core/models/payment_model/PaymentVoucher.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/payment_aprovel_status.dart';
import '../Aprovel/VoucherDetailsPage2.dart';

class ReportPaymentVoucherList extends StatefulWidget {
  @override
  _ReportPaymentVoucherListState createState() =>
      _ReportPaymentVoucherListState();
}

class _ReportPaymentVoucherListState extends State<ReportPaymentVoucherList> {
  final PaymentVoucherController controller =
      Get.put(PaymentVoucherController());
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final PaymentApprovalStatus approvalStatus = PaymentApprovalStatus();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      controller.searchVouchers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !controller.isLoading.value &&
        controller.hasMore.value) {
      controller.loadMoreVouchers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Payment Vouchers',
          style: TextStyle(
            fontFamily: 'inter',
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFAC945C), Color(0xFFAC945C)]),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: RefreshIndicator(
                onRefresh: () async {
                  await controller.refreshVouchers();
                },
                color: Color(0xFF00308C),
                child: _buildVoucherList()),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search vouchers...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF00308C)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    controller.searchVouchers('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildVoucherList() {
    return Obx(() {
      if (controller.isLoading.value && controller.paymentVouchers.isEmpty) {
        return Center(child: _buildLoadingIndicator());
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Error loading vouchers',
                style: TextStyle(
                  fontFamily: 'inter',
                  color: Colors.red,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 8),
              Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'inter',
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: controller.refreshVouchers,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00308C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: TextStyle(
                    fontFamily: 'inter',
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.filteredVouchers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                'No vouchers found',
                style: TextStyle(
                  fontFamily: 'inter',
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              if (_searchController.text.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                  },
                  child: Text(
                    'Clear search',
                    style: TextStyle(
                      fontFamily: 'inter',
                      color: Color(0xFF00308C),
                    ),
                  ),
                ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        physics: AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 16),
        itemCount: controller.filteredVouchers.length +
            (controller.hasMore.value ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= controller.filteredVouchers.length) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(child: _buildLoadingIndicator()),
            );
          }

          final voucher = controller.filteredVouchers[index];
          return _buildVoucherCard(voucher);
        },
      );
    });
  }

  Widget _buildVoucherCard(PaymentVoucher voucher) {
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final requiredLevel = approvalStatus.getRequiredApprovalLevel(amount);
    final isFullyApproved = _isAllLevelsApproved(voucher, requiredLevel);

    // Format amount with commas (Indian style)
    final formattedAmount = _formatIndianCurrency(amount);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(
            color: isFullyApproved ? Colors.brown : Colors.orange,
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          // In _buildVoucherCard method, replace the Get.toNamed with:
          onTap: () {
            if (voucher.voucherId != null && voucher.voucherId!.isNotEmpty) {
              Get.to(
                () => VoucherDetailsPage2(
                  voucherId: voucher.voucherId!,
                  amount: amount,
                ),
                // Optional: Add a named route if you prefer
                // arguments: {
                //   'voucherId': voucher.voucherId!,
                //   'voucherAmount': amount,
                // },
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row with voucher number and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'inter',
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: ' Bank Payment: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: '${voucher.voucherNumber ?? '0.00'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Date and amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        SizedBox(width: 4),
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'inter',
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'Date: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: voucher.date != null
                                    ? DateUtilsHelper.formatDate(voucher.date!)
                                    : 'N/A',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '₹$formattedAmount',
                      style: TextStyle(
                        fontFamily: 'inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isFullyApproved ? Colors.green[700] : Colors.black,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Ledger info
                if (voucher.ledgerName?.isNotEmpty ?? false) ...[
                  Row(
                    children: [
                      SizedBox(width: 4),
                      Flexible(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontFamily: 'inter',
                              color: Colors.black,
                            ),
                            children: [
                              TextSpan(
                                text: 'Party Name: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              TextSpan(
                                text: voucher.ledgerName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                // Approval levels - Only show required levels
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildProcessedApprovalLevels(voucher),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Add this new helper method to check if all levels are approved
  bool _isAllLevelsApproved(PaymentVoucher voucher, int requiredLevel) {
    for (int i = 1; i <= requiredLevel; i++) {
      final levelValue = _getLevelValue(voucher, i);
      if (levelValue == null ||
          levelValue.isEmpty ||
          levelValue.toLowerCase().contains('waiting') ||
          levelValue.toLowerCase().contains('rejected')) {
        return false;
      }
    }
    return true;
  }

// Helper method to get level value by number
  String? _getLevelValue(PaymentVoucher voucher, int levelNumber) {
    switch (levelNumber) {
      case 1:
        return voucher.level1;
      case 2:
        return voucher.level2;
      case 3:
        return voucher.level3;
      case 4:
        return voucher.level4;
      case 5:
        return voucher.level5;
      case 6:
        return voucher.level6;
      case 7:
        return voucher.level7;
      default:
        return null;
    }
  }

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

  List<Widget> _buildProcessedApprovalLevels(PaymentVoucher voucher) {
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final department = voucher.department;
    final skipCentralCommittee =
        approvalStatus.shouldSkipCentralCommittee(department, amount);
    final requiredLevel =
        approvalStatus.getRequiredApprovalLevel(amount, department: department);

    // Map level keys to voucher fields
    Map<String, String?> levels = {
      'L1': voucher.level1,
      'L2.1': voucher.level2_1,
      'L2.2': voucher.level2_2,
      'L2.3': voucher.level2_3,
      'L3': voucher.level3,
      'L4': voucher.level4,
      'L5': voucher.level5,
      'L6': voucher.level6,
      'L7': voucher.level7,
    };

    // Build eligible level order based on skip logic
    List<String> levelOrder = skipCentralCommittee
        ? ['L1', 'L3', 'L4', 'L5', 'L6', 'L7']
        : ['L1', 'L2.1', 'L2.2', 'L2.3', 'L3', 'L4', 'L5', 'L6', 'L7'];
    // Only show up to the required approval level
    int maxLevelIndex = requiredLevel - 1;
    if (maxLevelIndex >= levelOrder.length)
      maxLevelIndex = levelOrder.length - 1;
    var processedLevels = levelOrder
        .take(maxLevelIndex + 1)
        .map((levelKey) => MapEntry(levelKey, levels[levelKey]))
        .toList();

    final chips = processedLevels.map((entry) {
      final level = entry.key;
      final value = entry.value?.trim() ?? '';
      final isApproved = value.isNotEmpty &&
          !value.toLowerCase().contains('waiting') &&
          !value.toLowerCase().contains('rejected') &&
          !value.toLowerCase().contains('skipped');
      final isRejected = value.toLowerCase().contains('rejected');
      final isSkipped = value.toLowerCase().contains('skipped');
      final isWaiting =
          value.isEmpty || value.toLowerCase().contains('waiting');
      Color? bgColor;
      Color? borderColor;
      Color? textColor;
      IconData iconData;
      Color iconColor;
      if (isRejected) {
        bgColor = Colors.red[50];
        borderColor = Colors.red[300];
        textColor = Colors.red[600];
        iconData = Icons.cancel;
        iconColor = Colors.red;
      } else if (isApproved) {
        bgColor = Colors.green[50];
        borderColor = Colors.green[300];
        textColor = Colors.green[600];
        iconData = Icons.check_circle;
        iconColor = Colors.green;
      } else if (isSkipped) {
        bgColor = Colors.grey[100];
        borderColor = Colors.grey[400];
        textColor = Colors.grey[600];
        iconData = Icons.double_arrow;
        iconColor = Colors.grey;
      } else {
        bgColor = Colors.orange[50];
        borderColor = Colors.orange[300];
        textColor = Colors.orange[600];
        iconData = Icons.access_time;
        iconColor = Colors.orange;
      }
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: '$level: ${value.isEmpty ? 'Pending' : value}',
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontFamily: 'inter',
                    fontSize: 10,
                    color: textColor,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  iconData,
                  size: 16,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();

    // Add Tally icon if pushed (safe for PaymentVoucher)
    final sentToTally = (voucher.toJson()['sent_to_tally'] ?? '').toString();
    if ((sentToTally == '1' || sentToTally.toLowerCase() == 'yes') &&
        chips.isNotEmpty) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Tooltip(
            message: 'Pushed to Tally',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.deepPurple[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.deepPurple),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_done, size: 16, color: Colors.deepPurple),
                  SizedBox(width: 4),
                  Text('Tally',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.deepPurple,
                          fontFamily: 'inter')),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return chips;
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 24,
      height: 24,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation(Color(0xFF00308C)),
      ),
    );
  }
}
