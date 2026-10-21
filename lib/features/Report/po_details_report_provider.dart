import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/config/config_new.dart';
import '../../core/models/payment_model/PaymentVoucher.dart';

class PaymentVoucherController extends GetxController {
  var paymentVouchers = <PaymentVoucher>[].obs;
  var filteredVouchers = <PaymentVoucher>[].obs;
  var isLoading = false.obs;
  var isMoreLoading = false.obs;
  var errorMessage = ''.obs;
  var searchQuery = ''.obs;
  var currentPage = 1.obs;
  var hasMore = true.obs;
  var selectedStatus = 'All'.obs; // Add this line for status filtering
  var startDate = Rxn<DateTime>();
  var endDate = Rxn<DateTime>();
  var selectedMonth = Rxn<DateTime>(); // Represents year & month
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    fetchPaymentVouchers();
  }

  void setDateRange(DateTime? start, DateTime? end) {
    selectedMonth.value = null; // Clear month filter if setting custom range
    startDate.value = start;
    endDate.value = end;
    filterVouchers();
  }

  void setMonth(DateTime? monthDate) {
    if (monthDate != null) {
      selectedMonth.value = DateTime(monthDate.year, monthDate.month);
      startDate.value = DateTime(monthDate.year, monthDate.month, 1);
      endDate.value = DateTime(monthDate.year, monthDate.month + 1, 0, 23, 59, 59);
    } else {
      selectedMonth.value = null;
      startDate.value = null;
      endDate.value = null;
    }
    filterVouchers();
  }

  void clearDateFilter() {
    selectedMonth.value = null;
    startDate.value = null;
    endDate.value = null;
    filterVouchers();
  }

  DateTime? parseVoucherDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final cleaned = dateStr.trim();
    try {
      // 1. Direct YYYY-MM-DD format (e.g., "2026-08-27" or "2026-08-27 14:30:00" or ISO "2026-08-27T...")
      final ymdMatch = RegExp(r'^(\d{4})[-/.](\d{1,2})[-/.](\d{1,2})').firstMatch(cleaned);
      if (ymdMatch != null) {
        final year = int.parse(ymdMatch.group(1)!);
        final month = int.parse(ymdMatch.group(2)!);
        final day = int.parse(ymdMatch.group(3)!);
        return DateTime(year, month, day);
      }

      // 2. Direct DD-MM-YYYY format (e.g., "27-08-2026" or "27/08/2026")
      final dmyMatch = RegExp(r'^(\d{1,2})[-/.](\d{1,2})[-/.](\d{4})').firstMatch(cleaned);
      if (dmyMatch != null) {
        final day = int.parse(dmyMatch.group(1)!);
        final month = int.parse(dmyMatch.group(2)!);
        final year = int.parse(dmyMatch.group(3)!);
        return DateTime(year, month, day);
      }

      // 3. DD-MMM-YYYY format (e.g., "27-Aug-2026")
      if (cleaned.contains('-') || cleaned.contains(' ') || cleaned.contains('/')) {
        try {
          return DateFormat('dd-MMM-yyyy').parse(cleaned);
        } catch (_) {
          try {
            return DateFormat('d MMMM yyyy').parse(cleaned);
          } catch (_) {
            try {
              return DateFormat('MMM d, yyyy').parse(cleaned);
            } catch (_) {}
          }
        }
      }

      // 4. Fallback DateTime.tryParse
      return DateTime.tryParse(cleaned);
    } catch (_) {
      return null;
    }
  }

  // Add this method to match what your UI expects
  Future<void> refreshVouchers() async {
    currentPage.value = 1;
    await fetchPaymentVouchers(search: searchQuery.value, page: 1);
  }

  // Rest of your existing controller methods...
  Future<void> fetchPaymentVouchers({String search = '', int page = 1}) async {
    try {
      if (page == 1) {
        isLoading(true);
      } else {
        isMoreLoading(true);
      }
      errorMessage('');

      final response = await http
          .get(
            Uri.parse(
                '${Config_new.baseUrl}/opg/vouchers/get-payment?page=$page&search=$search'),
          )
          .timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('data')) {
          final data = jsonData['data'] as List;
          final newVouchers =
              data.map((item) => PaymentVoucher.fromJson(item)).toList();

          if (page == 1) {
            paymentVouchers.value = newVouchers;
          } else {
            paymentVouchers.addAll(newVouchers);
          }

          hasMore.value = newVouchers.isNotEmpty;
          filterVouchers();
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to load: ${response.statusCode}');
      }
    } catch (e) {
      errorMessage('Failed to load payment vouchers: $e');
      hasMore.value = false;
    } finally {
      isLoading(false);
      isMoreLoading(false);
    }
  }

  bool isVoucherApproved(PaymentVoucher voucher) {
    // A voucher is considered approved if at least one level is approved
    // and none of the levels are "waiting" or null/empty
    return [
      voucher.level1,
      voucher.level2,
      voucher.level3,
      voucher.level4,
      voucher.level5,
      voucher.level6,
      voucher.level7,
    ].any((level) =>
        level != null &&
        level.trim().isNotEmpty &&
        !level.trim().toLowerCase().contains('waiting'));
  }

  void searchVouchers(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      searchQuery.value = query;
      currentPage.value = 1;
      fetchPaymentVouchers(search: query, page: 1);
    });
  }

  void filterVouchers() {
    List<PaymentVoucher> filteredList;

    if (searchQuery.value.isEmpty) {
      filteredList = List.from(paymentVouchers);
    } else {
      final searchLower = searchQuery.value.toLowerCase();
      filteredList = paymentVouchers.where((voucher) {
        return (voucher.voucherNumber?.toLowerCase()?.contains(searchLower) ??
                false) ||
            (voucher.ledgerName?.toLowerCase()?.contains(searchLower) ??
                false) ||
            (voucher.date?.toLowerCase()?.contains(searchLower) ?? false) ||
            (voucher.amount?.toString().contains(searchQuery.value) ?? false) ||
            (voucher.level1?.toLowerCase().contains(searchLower) ?? false) ||
            (voucher.level2?.toLowerCase().contains(searchLower) ?? false) ||
            (voucher.level3?.toLowerCase().contains(searchLower) ?? false) ||
            (voucher.level4?.toLowerCase().contains(searchLower) ?? false) ||
            (voucher.level5?.toLowerCase().contains(searchLower) ?? false) ||
            (voucher.level6?.toLowerCase().contains(searchLower) ?? false) ||
            (voucher.level7?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    }

    // Apply date range / month filter if active
    if (selectedMonth.value != null) {
      final targetMonth = selectedMonth.value!.month;
      final targetYear = selectedMonth.value!.year;
      filteredList = filteredList.where((voucher) {
        final voucherDate = parseVoucherDate(voucher.date);
        if (voucherDate == null) {
          debugPrint('Could not parse date for voucher ${voucher.voucherNumber}: "${voucher.date}"');
          return false;
        }
        // Match both year and month if year is within realistic range, or match month if year is ambiguous
        return voucherDate.month == targetMonth && voucherDate.year == targetYear;
      }).toList();
    } else if (startDate.value != null || endDate.value != null) {
      filteredList = filteredList.where((voucher) {
        final voucherDate = parseVoucherDate(voucher.date);
        if (voucherDate == null) return false;

        if (startDate.value != null && endDate.value != null) {
          final startDay = DateTime(startDate.value!.year, startDate.value!.month, startDate.value!.day);
          final endDay = DateTime(endDate.value!.year, endDate.value!.month, endDate.value!.day, 23, 59, 59);
          return (voucherDate.isAfter(startDay) || voucherDate.isAtSameMomentAs(startDay)) &&
              (voucherDate.isBefore(endDay) || voucherDate.isAtSameMomentAs(endDay));
        } else if (startDate.value != null) {
          final startDay = DateTime(startDate.value!.year, startDate.value!.month, startDate.value!.day);
          return voucherDate.isAfter(startDay) || voucherDate.isAtSameMomentAs(startDay);
        } else if (endDate.value != null) {
          final endDay = DateTime(endDate.value!.year, endDate.value!.month, endDate.value!.day, 23, 59, 59);
          return voucherDate.isBefore(endDay) || voucherDate.isAtSameMomentAs(endDay);
        }
        return true;
      }).toList();
    }

    // Sort approved vouchers first
    filteredList.sort((a, b) {
      final aApproved = isVoucherApproved(a);
      final bApproved = isVoucherApproved(b);

      if (aApproved && !bApproved) {
        return -1; // a comes first
      } else if (!aApproved && bApproved) {
        return 1; // b comes first
      } else {
        return 0; // maintain original order
      }
    });

    filteredVouchers.value = filteredList;
  }

  void loadMoreVouchers() {
    if (!isLoading.value && !isMoreLoading.value && hasMore.value) {
      currentPage.value++;
      fetchPaymentVouchers(search: searchQuery.value, page: currentPage.value);
    }
  }
}
