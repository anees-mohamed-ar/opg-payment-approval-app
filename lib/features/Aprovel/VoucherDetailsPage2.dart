import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/config/config_new.dart';
import 'package:get/get.dart';
import '../../core/utils/payment_aprovel_status.dart';
import 'providers.dart';

class VoucherDetailsPage2 extends StatefulWidget {
  final String voucherId;
  final double amount;

  VoucherDetailsPage2({
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

class _VoucherDetailsPageState extends State<VoucherDetailsPage2> {
  List<dynamic> voucherDetails = [];
  bool isLoading = true;
  String errorMessage = '';
  Map<String, dynamic> approvalData = {};

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

    await Future.wait([
      _fetchVoucherDetails(),
      _fetchApprovalDetails(),
    ]);

    setState(() => isLoading = false);
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '₹0.00';

    final number = amount is String
        ? double.tryParse(amount) ?? 0.0
        : amount is num
            ? amount.toDouble()
            : 0.0;

    final formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    );
    return formatter.format(number);
  }

  Future<void> _fetchApprovalDetails() async {
    try {
      final url =
          '${Config_new.baseUrl}/opg/vouchers/payment-approve/voucher/${widget.voucherId}';
      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        setState(() {
          approvalData = data['data'] ?? {};
        });
      } else {
        setState(() {
          approvalData = {};
        });
      }
    } catch (e) {
      print('Error fetching approval details: $e');
      setState(() {
        approvalData = {};
      });
    }
  }

  Future<void> _fetchVoucherDetails() async {
    try {
      final url =
          '${Config_new.baseUrl}/opg/vouchers/voucher-details/${widget.voucherId}';
      print("URL: $url");
      print("master_id: ${widget.voucherId}");
      final response = await http.get(Uri.parse(url));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final details = data['data'] is List ? data['data'] : [data['data']];
        setState(() {
          voucherDetails = details;
        });
      } else {
        setState(() {
          voucherDetails = [];
          errorMessage = data['error'] ?? 'No voucher data available';
        });
      }
    } on SocketException {
      setState(() {
        errorMessage = 'No internet connection';
      });
    } on TimeoutException {
      setState(() {
        errorMessage = 'Request timed out';
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load voucher details';
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Ensure POApprovalController is registered before using Get.find
    if (!Get.isRegistered<POApprovalController>()) {
      Get.put(POApprovalController());
    }
    final controller = Get.find<POApprovalController>();
    final skipCentralCommittee = controller.shouldSkipCentralCommittee();
    final approvalStatus = PaymentApprovalStatus();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Voucher Details',
          style: GoogleFonts.publicSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFAC945C), Color(0xFFAC945C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Color(0xFFAC945C)),
      );
    }

    final hasVoucherData = voucherDetails.isNotEmpty;
    final hasApprovalData = approvalData.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasVoucherData) ..._buildVoucherCards(),
          if (!hasVoucherData && errorMessage.isNotEmpty) _buildNoDataMessage(),
          if (hasApprovalData) _buildApprovalStatusCard(),
        ],
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: Colors.blue.shade600,
            ),
            const SizedBox(height: 16),
            Text(
              'No Bill in info',
              style: GoogleFonts.publicSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage.isNotEmpty
                  ? errorMessage
                  : 'No voucher details found for ID: ${widget.voucherId}',
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFAC945C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.publicSans(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVoucherCards() {
    final groupedVouchers = <String, List<dynamic>>{};
    for (var voucher in voucherDetails) {
      final masterId = voucher['master_id']?.toString() ?? 'ungrouped';
      groupedVouchers.putIfAbsent(masterId, () => []).add(voucher);
    }

    return groupedVouchers.values
        .map((vouchers) => _buildVoucherCard(vouchers))
        .toList();
  }

  Widget _buildVoucherCard(List<dynamic> vouchers) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
                children: [
                  TextSpan(text: 'Party Name: '),
                  TextSpan(
                    text: vouchers.first['party_name'] ?? 'N/A',
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left Side: Voucher No + Value
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: 'Voucher No: '),
                      TextSpan(
                        text: vouchers.first['pay_no'] ?? 'N/A',
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right Side: Date + Value
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                    children: [
                      const TextSpan(text: 'Date: '),
                      TextSpan(
                        text: _formatDate(vouchers.first['pay_date']),
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Color(0xFFAC945C),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        'Ref Type',
                        style: GoogleFonts.publicSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        'Bill Name',
                        style: GoogleFonts.publicSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        'Bill Date',
                        style: GoogleFonts.publicSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border(
                            right: BorderSide(color: Colors.grey.shade300)),
                      ),
                      child: Text(
                        'Department',
                        style: GoogleFonts.publicSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Amount',
                        style: GoogleFonts.publicSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...vouchers
                .map((voucher) => Container(
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: Colors.grey.shade300)),
                              ),
                              child: Text(
                                voucher['bill_type']?.toString() ?? 'N/A',
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: Colors.grey.shade300)),
                              ),
                              child: Text(
                                voucher['bill_name']?.toString() ?? 'N/A',
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: Colors.grey.shade300)),
                              ),
                              child: Text(
                                _formatDate(voucher['pay_date']),
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border(
                                    right: BorderSide(
                                        color: Colors.grey.shade300)),
                              ),
                              child: Text(
                                voucher['department']?.toString() ?? 'N/A',
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                _formatCurrency(voucher['bill_amount']),
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
            if (vouchers.first['narration'] != null &&
                vouchers.first['narration'].toString().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Narration: ${vouchers.first['narration']}',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Align(
                alignment: Alignment.centerRight,
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Total Amount: ',
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      TextSpan(
                        text: _formatCurrency(widget.amount),
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalStatusCard() {
    final controller = Get.find<POApprovalController>();
    final skipCentralCommittee = controller.shouldSkipCentralCommittee();
    final approvalStatus = PaymentApprovalStatus();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _buildApprovalStatus(),
      ),
    );
  }

  Widget _buildApprovalStatus() {
    final controller = Get.find<POApprovalController>();
    final skipCentralCommittee = controller.shouldSkipCentralCommittee();
    final approvalStatus = PaymentApprovalStatus();

    bool isApproved(String level) {
      return approvalData[level]
              ?.toString()
              .toLowerCase()
              .contains('approved') ??
          false;
    }

    Map<String, String> getApprovalInfo(String level) {
      final value = approvalData[level]?.toString() ?? '';
      final regExp = RegExp(r'approved by (.+?) on (.+)');
      final match = regExp.firstMatch(value.toLowerCase());

      if (match != null && match.groupCount == 2) {
        return {
          'by': match.group(1) ?? '',
          'date': match.group(2) ?? '',
        };
      }
      return {'by': '', 'date': ''};
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Approval Status',
          style: GoogleFonts.publicSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blue[800],
          ),
        ),
        SizedBox(height: 12),
        ...approvalStatus
            .getApprovalLevelKeys(skipCentralCommittee: skipCentralCommittee)
            .where((level) => isApproved(level))
            .map((level) {
          final info = getApprovalInfo(level);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: EdgeInsets.only(right: 8, top: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Text(
                    '${level.replaceFirst('level', 'Level ')}:',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[100]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: Colors.green[800],
                          ),
                          children: [
                            TextSpan(
                              text: 'Approved by ',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: info['by']?.isNotEmpty == true
                                  ? info['by']
                                  : 'Unknown',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        info['date']?.isNotEmpty == true
                            ? 'on ${info['date']}'
                            : '',
                        style: GoogleFonts.publicSans(
                          fontSize: 11,
                          color: Colors.green[700],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        if (!approvalStatus
            .getApprovalLevelKeys(skipCentralCommittee: skipCentralCommittee)
            .any((level) => isApproved(level)))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'No approvals yet',
              style: GoogleFonts.publicSans(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
