import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/models/payment_model/PaymentVoucher.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/payment_aprovel_status.dart';
import '../../core/theme/app_typography.dart';
import '../Report/po_details_report_provider.dart';
import '../../routes/app_routes.dart';

/// Exported alias used by MainShell
class HistoryTab extends StatelessWidget {
  const HistoryTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const HistoryScreen();
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final PaymentVoucherController controller =
      Get.isRegistered<PaymentVoucherController>()
          ? Get.find<PaymentVoucherController>()
          : Get.put(PaymentVoucherController());

  final TextEditingController _searchController = TextEditingController();
  late final TabController _tabController;

  final List<Map<String, dynamic>> _filters = [
    {'label': 'All', 'color': Colors.blueGrey},
    {
      'label': 'In Progress',
      'color': Color(0xFFD97706),
    },
    {
      'label': 'Tally Sent',
      'color': Colors.deepPurple,
    },
    {
      'label': 'Rejected',
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _searchController.addListener(() {
      controller.searchVouchers(_searchController.text);
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
        _buildSearchAndDateFilterBar(),
        _buildActiveDateFilterChip(),
        _buildFilterTabBar(),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            children: _filters.map((filter) {
              return _HistoryTabContent(
                controller: controller,
                filterLabel: filter['label'] as String,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                style: getAppleStyle(fontSize: 13, color: const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  hintText: 'Search by voucher, payee...',
                  hintStyle: getAppleStyle(fontSize: 12.5, color: Colors.grey.shade500),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFFAC945C), size: 18),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            controller.searchVouchers('');
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

          // Month Filter Button
          Obx(() {
            final isMonthActive = controller.selectedMonth.value != null;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showMonthPicker,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isMonthActive
                        ? const Color(0xFFAC945C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isMonthActive
                          ? const Color(0xFFAC945C)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        size: 16,
                        color: isMonthActive ? Colors.white : const Color(0xFFAC945C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Month',
                        style: getAppleStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isMonthActive ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(width: 6),

          // Date Range Filter Button
          Obx(() {
            final isRangeActive = controller.selectedMonth.value == null &&
                (controller.startDate.value != null || controller.endDate.value != null);
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showDateRangePicker,
                borderRadius: BorderRadius.circular(10),
                child: Ink(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isRangeActive
                        ? const Color(0xFFAC945C)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isRangeActive
                          ? const Color(0xFFAC945C)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 16,
                        color: isRangeActive ? Colors.white : const Color(0xFFAC945C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Range',
                        style: getAppleStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isRangeActive ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 42,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: AnimatedBuilder(
          animation: _tabController.animation!,
          builder: (context, _) {
            final position = _tabController.animation!.value;
            final count = _filters.length;
            return LayoutBuilder(
              builder: (context, constraints) {
                final tabWidth = constraints.maxWidth / count;
                return Stack(
                  children: [
                    // Moving sliding indicator pill
                    Positioned(
                      left: position * tabWidth,
                      width: tabWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Labels row
                    Row(
                      children: _filters.asMap().entries.map((entry) {
                        final i = entry.key;
                        final f = entry.value;
                        final isCurrentTab = position.round() == i;
                        final color = f['color'] as Color;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () => _tabController.animateTo(i),
                            behavior: HitTestBehavior.opaque,
                            child: Center(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrentTab
                                          ? color
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Flexible(
                                    child: Text(
                                      f['label'] as String,
                                      style: getAppleStyle(
                                        fontSize: 11.5,
                                        fontWeight: isCurrentTab
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                        color: isCurrentTab
                                            ? const Color(0xFF0F172A)
                                            : Colors.grey.shade600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveDateFilterChip() {
    return Obx(() {
      final selectedMonth = controller.selectedMonth.value;
      final start = controller.startDate.value;
      final end = controller.endDate.value;

      if (selectedMonth == null && start == null && end == null) {
        return const SizedBox.shrink();
      }

      String filterText = '';
      if (selectedMonth != null) {
        filterText = DateFormat('MMMM yyyy').format(selectedMonth);
      } else if (start != null && end != null) {
        filterText = '${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(end)}';
      } else if (start != null) {
        filterText = 'From ${DateFormat('dd MMM yyyy').format(start)}';
      } else if (end != null) {
        filterText = 'Until ${DateFormat('dd MMM yyyy').format(end)}';
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFAC945C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFAC945C).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    selectedMonth != null
                        ? Icons.calendar_month_rounded
                        : Icons.date_range_rounded,
                    size: 13,
                    color: const Color(0xFF8E6500),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filterText,
                    style: getAppleStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8E6500),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: controller.clearDateFilter,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Color(0xFF8E6500),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: controller.clearDateFilter,
              child: Text(
                'Clear filter',
                style: getAppleStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: controller.startDate.value ?? now.subtract(const Duration(days: 30)),
      end: controller.endDate.value ?? now,
    );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFFAC945C),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      controller.setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _showMonthPicker() async {
    // Detect year from current data if available, fallback to now
    int detectedYear = DateTime.now().year;
    for (final v in controller.paymentVouchers) {
      final parsed = controller.parseVoucherDate(v.date);
      if (parsed != null && parsed.year > 2000 && parsed.year < 2100) {
        detectedYear = parsed.year;
        break;
      }
    }

    int selectedYear = controller.selectedMonth.value?.year ?? detectedYear;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Month',
                        style: getAppleStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: () => setModalState(() => selectedYear--),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$selectedYear',
                            style: getAppleStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFAC945C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: () => setModalState(() => selectedYear++),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.0,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      final monthIndex = index + 1;
                      final monthDate = DateTime(selectedYear, monthIndex);
                      final isSelected = controller.selectedMonth.value != null &&
                          controller.selectedMonth.value!.year == selectedYear &&
                          controller.selectedMonth.value!.month == monthIndex;
                      final monthName = DateFormat('MMM').format(monthDate);

                      return GestureDetector(
                        onTap: () {
                          controller.setMonth(monthDate);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFAC945C)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFAC945C)
                                  : Colors.grey.shade200,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            monthName,
                            style: getAppleStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  if (controller.selectedMonth.value != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          controller.clearDateFilter();
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Clear Selection',
                          style: getAppleStyle(
                            fontSize: 13,
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

}

enum _VoucherStatus { approved, rejected, inProgress, tally }

_VoucherStatus _getStatus(PaymentVoucher v) {
  if (v.sentToTally == 1) return _VoucherStatus.tally;

  final levels = [
    v.level1, v.level2_1, v.level2_2, v.level2_3,
    v.level3, v.level4, v.level5, v.level6, v.level7,
  ];
  final any = (String needle) =>
      levels.any((l) => (l?.toLowerCase() ?? '').contains(needle));

  if (any('rejected')) return _VoucherStatus.rejected;

  final approvalStatus = PaymentApprovalStatus();
  final isFullyApproved = approvalStatus.isFullyApproved(v);

  if (isFullyApproved || any('pushed to tally') || any('tally')) {
    return _VoucherStatus.tally;
  }

  final anyApproved = any('approved');
  if (anyApproved) return _VoucherStatus.inProgress;
  return _VoucherStatus.inProgress;
}

bool _matchesFilter(PaymentVoucher v, String filter) {
  if (filter == 'All') return true;
  final status = _getStatus(v);
  switch (filter) {
    case 'Approved':
    case 'Tally Done':
    case 'Pushed to Tally':
    case 'Tally Sent':
      return status == _VoucherStatus.tally;
    case 'Rejected':
      return status == _VoucherStatus.rejected;
    case 'In Progress':
      return status == _VoucherStatus.inProgress;
    default:
      return true;
  }
}

class _HistoryTabContent extends StatefulWidget {
  final PaymentVoucherController controller;
  final String filterLabel;

  const _HistoryTabContent({
    Key? key,
    required this.controller,
    required this.filterLabel,
  }) : super(key: key);

  @override
  State<_HistoryTabContent> createState() => _HistoryTabContentState();
}

class _HistoryTabContentState extends State<_HistoryTabContent>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !widget.controller.isLoading.value &&
        !widget.controller.isMoreLoading.value &&
        widget.controller.hasMore.value) {
      widget.controller.loadMoreVouchers();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Obx(() {
      if (widget.controller.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: Color(0xFFAC945C)));
      }
      final filtered = widget.controller.filteredVouchers
          .where((v) => _matchesFilter(v, widget.filterLabel))
          .toList();

      if (filtered.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('No vouchers found',
                  style: getAppleStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B))),
              const SizedBox(height: 6),
              Text('No activity under "${widget.filterLabel}".',
                  style: getAppleStyle(
                      fontSize: 13, color: Colors.grey.shade500)),
            ],
          ),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFFAC945C),
        onRefresh: widget.controller.refreshVouchers,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount:
              filtered.length + (widget.controller.isMoreLoading.value ? 1 : 0),
          itemBuilder: (ctx, i) {
            if (i >= filtered.length) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFAC945C))),
              );
            }
            return _buildVoucherCardWidget(filtered[i]);
          },
        ),
      );
    });
  }

  Widget _buildVoucherCardWidget(PaymentVoucher v) {
    final status = _getStatus(v);
    final statusConfig = _statusConfig(status);
    final amount = double.tryParse(v.amount?.toString() ?? '0') ?? 0;

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
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
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
                Expanded(
                  child: Text(
                    'Voucher #${v.voucherNumber ?? 'N/A'}',
                    style: getAppleStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
                // Status chip
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        (statusConfig['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: (statusConfig['color'] as Color)
                            .withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusConfig['icon'] as IconData,
                        size: 12,
                        color: statusConfig['color'] as Color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusConfig['label'] as String,
                        style: getAppleStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: statusConfig['color'] as Color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.ledgerName ?? 'Unknown Payee',
                    style: getAppleStyle(
                      fontSize: 13.5,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w400,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (v.department != null && v.department!.trim().isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFAC945C).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: const Color(0xFFAC945C).withOpacity(0.3),
                          width: 1),
                    ),
                    child: Text(
                      v.department!.trim(),
                      style: getAppleStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8A6E40),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _buildLevelChips(v),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.currency_rupee,
                    size: 14, color: Color(0xFF059669)),
                Text(
                  _formatIndian(amount),
                  style: getAppleStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  DateUtilsHelper.formatDate(v.date?.toString() ?? ''),
                  style: getAppleStyle(
                      fontSize: 12.5, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Color(0xFFAC945C)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelChips(PaymentVoucher voucher) {
    final amount = double.tryParse(voucher.amount?.toString() ?? '0') ?? 0;
    final department = voucher.department;
    final approvalStatus = PaymentApprovalStatus();
    final skipCentralCommittee =
        approvalStatus.shouldSkipCentralCommittee(department, amount);
    final skipTo23 = approvalStatus.shouldSkipToLevel23(department);
    final requiredLevel =
        approvalStatus.getRequiredApprovalLevel(amount, department: department);

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

    List<String> levelOrder;
    if (skipCentralCommittee) {
      levelOrder = ['L1', 'L3', 'L4', 'L5', 'L6', 'L7'];
    } else if (skipTo23) {
      levelOrder = ['L1', 'L2.3', 'L3', 'L4', 'L5', 'L6', 'L7'];
    } else {
      levelOrder = ['L1', 'L2.1', 'L2.2', 'L2.3', 'L3', 'L4', 'L5', 'L6', 'L7'];
    }

    int maxLevelIndex = requiredLevel - 1;
    if (maxLevelIndex >= levelOrder.length) {
      maxLevelIndex = levelOrder.length - 1;
    }
    final activeLevels = levelOrder.take(maxLevelIndex + 1).toList();

    List<Widget> chipWidgets = [];
    for (int i = 0; i < activeLevels.length; i++) {
      final levelKey = activeLevels[i];
      final value = levels[levelKey]?.trim() ?? '';
      final lower = value.toLowerCase();

      final isApproved = value.isNotEmpty &&
          !lower.contains('waiting') &&
          !lower.contains('rejected') &&
          !lower.contains('skipped');
      final isRejected = lower.contains('rejected');
      final isSkipped = lower.contains('skipped');

      Color bgColor;
      Color borderColor;
      Color textColor;
      IconData iconData;
      Color iconColor;

      if (isRejected) {
        bgColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        textColor = const Color(0xFFDC2626);
        iconData = Icons.cancel;
        iconColor = const Color(0xFFDC2626);
      } else if (isApproved) {
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF86EFAC);
        textColor = const Color(0xFF16A34A);
        iconData = Icons.check_circle;
        iconColor = const Color(0xFF16A34A);
      } else if (isSkipped) {
        bgColor = const Color(0xFFF3F4F6);
        borderColor = const Color(0xFFD1D5DB);
        textColor = const Color(0xFF6B7280);
        iconData = Icons.double_arrow_rounded;
        iconColor = const Color(0xFF9CA3AF);
      } else {
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFFDE68A);
        textColor = const Color(0xFFD97706);
        iconData = Icons.access_time_rounded;
        iconColor = const Color(0xFFD97706);
      }

      chipWidgets.add(
        Tooltip(
          message: '$levelKey: ${value.isEmpty ? 'Pending' : value}',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  levelKey,
                  style: getAppleStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(iconData, size: 13, color: iconColor),
              ],
            ),
          ),
        ),
      );

      if (i < activeLevels.length - 1) {
        chipWidgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 3),
            child: Icon(Icons.arrow_forward_ios_rounded,
                size: 9, color: Color(0xFFCBD5E1)),
          ),
        );
      }
    }

    final isTally = voucher.sentToTally == 1 ||
        (voucher.sentToTally?.toString() == '1') ||
        _getStatus(voucher) == _VoucherStatus.tally;
    if (isTally) {
      chipWidgets.add(
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 3),
          child: Icon(Icons.arrow_forward_ios_rounded,
              size: 9, color: Color(0xFFCBD5E1)),
        ),
      );
      chipWidgets.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFAF5FF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFD8B4FE), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tally',
                style: getAppleStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7E22CE),
                ),
              ),
              const SizedBox(width: 3),
              const Icon(Icons.cloud_done_rounded,
                  size: 13, color: Color(0xFF7E22CE)),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: chipWidgets,
      ),
    );
  }

  Map<String, dynamic> _statusConfig(_VoucherStatus status) {
    switch (status) {
      case _VoucherStatus.tally:
        return {
          'label': 'Tally Sent',
          'icon': Icons.cloud_done_rounded,
          'color': Colors.deepPurple,
        };
      case _VoucherStatus.approved:
        return {
          'label': 'Approved',
          'icon': Icons.check_circle_rounded,
          'color': const Color(0xFF059669),
        };
      case _VoucherStatus.rejected:
        return {
          'label': 'Rejected',
          'icon': Icons.cancel_rounded,
          'color': Colors.red,
        };
      case _VoucherStatus.inProgress:
        return {
          'label': 'In Progress',
          'icon': Icons.hourglass_top_rounded,
          'color': const Color(0xFFD97706),
        };
    }
  }

  String _formatIndian(double amount) {
    final formatter =
        NumberFormat.currency(symbol: '', decimalDigits: 0, locale: 'en_IN');
    return formatter.format(amount).trim();
  }
}
