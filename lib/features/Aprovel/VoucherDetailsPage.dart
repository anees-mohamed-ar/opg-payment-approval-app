import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/config/config_new.dart';
import '../../core/models/payment_model/Voucher.dart';
import '../../core/utils/payment_aprovel_status.dart';
import '../../core/theme/app_typography.dart';
import '../Report/po_details_report_provider.dart';
import '../home/logic/home_controller.dart';
import 'po_approval_screen.dart';
import 'providers.dart';

class VoucherDetailsPage extends StatefulWidget {
  final String voucherId;
  final double amount;

  VoucherDetailsPage({
    Key? key,
    required this.voucherId,
    required dynamic amount,
  })  : amount = amount is String
            ? double.tryParse(amount) ?? 0.0
            : amount is num
                ? amount.toDouble()
                : 0.0,
        super(key: key);

  @override
  _VoucherDetailsPageState createState() => _VoucherDetailsPageState();
}

class _VoucherDetailsPageState extends State<VoucherDetailsPage> {
  List<dynamic> voucherDetails = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> approvalData = {};
  bool isApproving = false;
  bool isRejecting = false;
  final controller = Get.find<POApprovalController>();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });
    await Future.wait([_fetchVoucherDetails(), _fetchApprovalDetails()]);
    setState(() => isLoading = false);
  }

  // ─── Formatting ─────────────────────────────────────────────────────────────

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';
    final number = amount is String
        ? double.tryParse(amount) ?? 0.0
        : amount is num
            ? amount.toDouble()
            : 0.0;
    return NumberFormat.currency(
            symbol: '₹', decimalDigits: 2, locale: 'en_IN')
        .format(number);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final d = DateTime.parse(date.toString());
      return DateFormat('dd MMM yyyy').format(d);
    } catch (_) {
      return date.toString();
    }
  }

  // ─── Data Fetching ───────────────────────────────────────────────────────────

  Future<void> _fetchApprovalDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${Config_new.baseUrl}/opg/vouchers/payment-approve/voucher/${widget.voucherId}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() => approvalData = data['data'] ?? {});
      } else {
        setState(() => approvalData = {});
      }
    } catch (_) {
      setState(() => approvalData = {});
    }
  }

  Future<void> _fetchVoucherDetails() async {
    try {
      final response = await http
          .get(Uri.parse(
              '${Config_new.baseUrl}/opg/vouchers/voucher-details/${widget.voucherId}'))
          .timeout(const Duration(seconds: 10));
      final data = json.decode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          voucherDetails = data['data'] is List ? data['data'] : [data['data']];
        });
      } else {
        setState(() {
          voucherDetails = [];
          errorMessage = data['error'] ?? 'No voucher data available';
        });
      }
    } on SocketException {
      setState(() => errorMessage = 'No internet connection');
    } on TimeoutException {
      setState(() => errorMessage = 'Request timed out');
    } catch (_) {
      setState(() => errorMessage = 'Failed to load voucher details');
    }
  }

  // ─── Approval State Checks ────────────────────────────────────────────────────

  bool _isVoucherRejected() {
    return [
      approvalData['level1'],
      approvalData['level2_1'],
      approvalData['level2_2'],
      approvalData['level2_3'],
      approvalData['level3'],
      approvalData['level4'],
      approvalData['level5'],
      approvalData['level6'],
      approvalData['level7'],
    ].any((l) => (l?.toString().toLowerCase() ?? '').contains('rejected'));
  }

  // Determines if current user is the pending approver
  bool _isCurrentUserPendingApprover() {
    if (controller.userRole.isEmpty) return false;
    return controller.filteredData
        .any((v) => v.voucherId == widget.voucherId);
  }

  // ─── Action Handlers ─────────────────────────────────────────────────────────

  Future<void> _handleAction(bool isApprove) async {
    final remarksCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(children: [
          Icon(isApprove ? Icons.check_circle_outline : Icons.highlight_off,
              color: isApprove ? const Color(0xFF059669) : Colors.red),
          const SizedBox(width: 10),
          Text(isApprove ? 'Approve Voucher' : 'Reject Voucher',
              style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.bold, fontSize: 18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isApprove
                  ? 'Are you sure you want to approve this voucher?'
                  : 'Are you sure you want to reject this voucher?',
              style: GoogleFonts.publicSans(fontSize: 14),
            ),
            if (!isApprove) ...[
              const SizedBox(height: 14),
              TextField(
                controller: remarksCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Rejection Reason (optional)',
                  hintText: 'Enter reason for rejection...',
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

    if (confirmed != true) return;

    setState(() {
      if (isApprove)
        isApproving = true;
      else
        isRejecting = true;
    });

    try {
      final fetchId = widget.voucherId;
      final latestVoucher = await controller.fetchVoucherById(fetchId);
      if (latestVoucher == null) {
        throw Exception('Failed to fetch latest voucher data.');
      }
      final updatedVoucher = latestVoucher.copyWith(
        payDate: latestVoucher.payDate ??
            (voucherDetails.isNotEmpty
                ? voucherDetails.first['pay_date']?.toString()
                : null),
      );

      final result = await controller.approveVoucherWithResult(
        updatedVoucher,
        isApprove,
        remarks: isApprove ? null : remarksCtrl.text,
      );

      // Refresh other controllers to keep dashboard & history in sync
      if (Get.isRegistered<HomeController>()) {
        Get.find<HomeController>().fetchDashboardStats();
      }
      if (Get.isRegistered<PaymentVoucherController>()) {
        Get.find<PaymentVoucherController>().refreshVouchers();
      }

      if (mounted) {
        if (result.status == ApprovalStatus.approved ||
            result.status == ApprovalStatus.pushedToTally ||
            result.status == ApprovalStatus.rejected) {
          Get.back();
          Get.snackbar(
            isApprove ? 'Approved!' : 'Rejected',
            isApprove
                ? 'Voucher approved successfully.'
                : 'Voucher rejected successfully.',
            backgroundColor:
                isApprove ? const Color(0xFF059669) : Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            borderRadius: 12,
            margin: const EdgeInsets.all(16),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to ${isApprove ? 'approve' : 'reject'}: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted)
        setState(() {
          isApproving = false;
          isRejecting = false;
        });
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: Text(
          'Voucher Details',
          style: GoogleFonts.publicSans(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFAC945C), Color(0xFF8A6E40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFAC945C)))
          : RefreshIndicator(
              color: const Color(0xFFAC945C),
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (_isVoucherRejected()) _buildRejectedBanner(),
                    if (voucherDetails.isNotEmpty) ..._buildVoucherCards(),
                    if (voucherDetails.isEmpty && errorMessage.isNotEmpty)
                      _buildError(),
                    const SizedBox(height: 16),
                    _buildApprovalTimeline(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isVoucherRejected()
          ? null
          : (_isCurrentUserPendingApprover()
              ? _buildActionButtons()
              : _buildWaitingBar()),
    );
  }

  Widget _buildRejectedBanner() {
    // Find the rejection info
    final levels = {
      'level1': approvalData['level1'],
      'level2_1': approvalData['level2_1'],
      'level2_2': approvalData['level2_2'],
      'level2_3': approvalData['level2_3'],
      'level3': approvalData['level3'],
      'level4': approvalData['level4'],
      'level5': approvalData['level5'],
      'level6': approvalData['level6'],
      'level7': approvalData['level7'],
    };
    String rejectedBy = '';
    String rejectionReason = '';
    for (final e in levels.entries) {
      if ((e.value?.toString().toLowerCase() ?? '').contains('rejected')) {
        rejectedBy = e.value.toString();
        final m =
            RegExp(r'\(Reason: (.+?)\)', caseSensitive: false).firstMatch(rejectedBy);
        if (m != null) rejectionReason = m.group(1) ?? '';
        break;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'This voucher has been rejected',
                style: getAppleStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red.shade800),
              ),
            ],
          ),
          if (rejectionReason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: $rejectionReason',
              style: getAppleStyle(
                  fontSize: 13, color: Colors.red.shade700),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildVoucherCards() {
    final grouped = <String, List<dynamic>>{};
    for (final v in voucherDetails) {
      final id = v['master_id']?.toString() ?? 'ungrouped';
      grouped.putIfAbsent(id, () => []).add(v);
    }
    return grouped.values.map(_buildVoucherCard).toList();
  }

  Widget _buildVoucherCard(List<dynamic> vouchers) {
    final first = vouchers.first;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first['party_name'] ?? 'N/A',
                        style: getAppleStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Voucher No: ${first['pay_no'] ?? 'N/A'}  ·  ${_formatDate(first['pay_date'])}',
                        style: getAppleStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Total',
                        style: getAppleStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                    Text(
                      _formatCurrency(widget.amount),
                      style: getAppleStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: const Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            // Table
            _buildTable(vouchers),
            if (first['narration'] != null &&
                first['narration'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes_rounded,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        first['narration'],
                        style: getAppleStyle(
                            fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<dynamic> vouchers) {
    final headers = ['Ref Type', 'Bill Name', 'Bill Date', 'Dept', 'Amount'];
    return Column(
      children: [
        // Header row
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFAC945C),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: headers.map((h) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 8),
                  child: Text(
                    h,
                    style: getAppleStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600),
                    textAlign:
                        h == 'Amount' ? TextAlign.right : TextAlign.left,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Data rows
        ...vouchers.asMap().entries.map((entry) {
          final v = entry.value;
          return Container(
            color: entry.key.isEven ? Colors.white : Colors.grey.shade50,
            child: Row(
              children: [
                _tableCell(v['bill_type']?.toString() ?? 'N/A'),
                _tableCell(v['bill_name']?.toString() ?? 'N/A'),
                _tableCell(_formatDate(v['pay_date'])),
                _tableCell(v['department']?.toString() ?? 'N/A'),
                _tableCell(
                  _formatCurrency(v['bill_amount']),
                  align: TextAlign.right,
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _tableCell(String text, {TextAlign align = TextAlign.left}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Text(
          text,
          style: getAppleStyle(fontSize: 10, color: Colors.grey.shade800),
          textAlign: align,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 12),
          Text(errorMessage,
              style: GoogleFonts.publicSans(color: Colors.red, fontSize: 14)),
        ],
      ),
    );
  }

  // ─── Approval Timeline ────────────────────────────────────────────────────────

  Widget _buildApprovalTimeline() {
    if (approvalData.isEmpty) return const SizedBox.shrink();

    // Build timeline entries
    final entries = _buildTimelineEntries();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline_rounded,
                    color: Color(0xFFAC945C), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Approval Trail',
                  style: getAppleStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...entries,
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTimelineEntries() {
    const levelLabels = {
      'level1': 'HOD / SBU Head',
      'level2_1': 'Central Committee 1',
      'level2_2': 'Central Committee 2',
      'level2_3': 'Central Committee 3',
      'level3': 'M(A/cs)',
      'level4': 'HO-Operations',
      'level5': 'P(F&A)',
      'level6': 'Head-Commercial',
      'level7': 'CEO',
    };

    final orderedKeys = [
      'level1', 'level2_1', 'level2_2', 'level2_3',
      'level3', 'level4', 'level5', 'level6', 'level7',
    ];

    final entries = <Widget>[];
    for (int i = 0; i < orderedKeys.length; i++) {
      final key = orderedKeys[i];
      final raw = approvalData[key]?.toString() ?? '';
      if (raw.isEmpty || raw.toLowerCase() == 'waiting') continue;

      final isLast = i == orderedKeys.length - 1 ||
          orderedKeys
              .sublist(i + 1)
              .every((k) =>
                  (approvalData[k]?.toString() ?? '').isEmpty ||
                  approvalData[k].toString().toLowerCase() == 'waiting');

      final isApproved = raw.toLowerCase().contains('approved');
      final isRejected = raw.toLowerCase().contains('rejected');
      final isSkipped = raw.toLowerCase().contains('skipped');
      final isPushed = raw.toLowerCase().contains('pushed to tally');

      Color dotColor;
      IconData dotIcon;
      if (isPushed) {
        dotColor = Colors.deepPurple;
        dotIcon = Icons.cloud_done_rounded;
      } else if (isApproved) {
        dotColor = const Color(0xFF059669);
        dotIcon = Icons.check_rounded;
      } else if (isRejected) {
        dotColor = Colors.red;
        dotIcon = Icons.close_rounded;
      } else if (isSkipped) {
        dotColor = Colors.grey;
        dotIcon = Icons.skip_next_rounded;
      } else {
        dotColor = const Color(0xFFD97706);
        dotIcon = Icons.hourglass_top_rounded;
      }

      // Parse approver name and time
      final approvedMatch =
          RegExp(r'(approved|rejected|pushed) by (.+?) on (.+?)( \(|$)',
                  caseSensitive: false)
              .firstMatch(raw);
      String name = '';
      String time = '';
      if (approvedMatch != null) {
        name = approvedMatch.group(2) ?? '';
        time = approvedMatch.group(3) ?? '';
      }

      // Rejection reason
      final reasonMatch =
          RegExp(r'\(Reason: (.+?)\)', caseSensitive: false).firstMatch(raw);
      final reason = reasonMatch?.group(1) ?? '';

      entries.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline dot + line
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Icon(dotIcon, color: dotColor, size: 16),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelLabels[key] ?? key,
                      style: getAppleStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: const Color(0xFF0F172A)),
                    ),
                    if (name.isNotEmpty)
                      Text(
                        'by $name',
                        style: getAppleStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    if (time.isNotEmpty)
                      Text(
                        time,
                        style: getAppleStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic),
                      ),
                    if (isSkipped && name.isEmpty)
                      Text(
                        'Skipped',
                        style: getAppleStyle(
                            fontSize: 12, color: Colors.grey),
                      ),
                    if (reason.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Reason: $reason',
                          style: getAppleStyle(
                              fontSize: 11, color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return entries;
  }

  // ─── Bottom Action Buttons ────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: isRejecting || isApproving
                  ? null
                  : () => _handleAction(false),
              icon: isRejecting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.red))
                  : const Icon(Icons.close_rounded, color: Colors.red),
              label: Text('Reject',
                  style: getAppleStyle(
                      fontSize: 14,
                      color: Colors.red,
                      fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: isApproving || isRejecting
                  ? null
                  : () => _handleAction(true),
              icon: isApproving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_rounded, color: Colors.white),
              label: Text('Approve',
                  style: getAppleStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingBar() {
    final voucher = Voucher(
      voucherId: widget.voucherId,
      amount: widget.amount.toString(),
      department: voucherDetails.isNotEmpty
          ? voucherDetails.first['department']?.toString()
          : null,
      level1: approvalData['level1']?.toString(),
      level2_1: approvalData['level2_1']?.toString(),
      level2_2: approvalData['level2_2']?.toString(),
      level2_3: approvalData['level2_3']?.toString(),
      level3: approvalData['level3']?.toString(),
      level4: approvalData['level4']?.toString(),
      level5: approvalData['level5']?.toString(),
      level6: approvalData['level6']?.toString(),
      level7: approvalData['level7']?.toString(),
    );

    final approvalStatus = PaymentApprovalStatus();
    final isFullyApproved = approvalStatus.isFullyApproved(voucher);

    final isPushed = approvalData['sent_to_tally'] == 1 ||
        approvalData['sent_to_tally'] == '1' ||
        isFullyApproved ||
        [
          approvalData['level1'],
          approvalData['level2_1'],
          approvalData['level2_2'],
          approvalData['level2_3'],
          approvalData['level3'],
          approvalData['level4'],
          approvalData['level5'],
          approvalData['level6'],
          approvalData['level7'],
        ].any((l) =>
            (l?.toString().toLowerCase() ?? '').contains('pushed to tally'));

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isPushed
              ? Colors.deepPurple.shade50
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isPushed
                  ? Colors.deepPurple.shade200
                  : Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              isPushed
                  ? Icons.cloud_done_rounded
                  : Icons.hourglass_empty_rounded,
              color: isPushed ? Colors.deepPurple : Colors.grey.shade500,
            ),
            const SizedBox(width: 10),
            Text(
              isPushed
                  ? 'Pushed to Tally — fully processed'
                  : 'Awaiting another approver at your level',
              style: getAppleStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isPushed
                    ? Colors.deepPurple.shade700
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
