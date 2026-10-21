import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/config_new.dart';
import '../../core/models/payment_model/Voucher.dart';
import '../../core/utils/payment_aprovel_status.dart';
import '../../routes/app_routes.dart';
import 'po_approval_screen.dart';

class POApprovalController extends GetxController {
  final RxMap<int, bool> selectedItems = <int, bool>{}.obs;
  final TextEditingController searchController = TextEditingController();
  final RxList<Voucher> filteredData = <Voucher>[].obs;
  final ScrollController scrollController = ScrollController();
  final RxInt currentPage = 1.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreData = true.obs;
  final RxBool isInitialLoad = true.obs;
  final RxBool isRefreshing = false.obs;
  final RxString userRole = ''.obs;
  final RxString userDepartment = ''.obs;
  Timer? _searchDebounce;
  List<Voucher> vouchers = [];
  static const int connectionTimeoutSeconds = 60;
  static final String _backendUrl = Config_new.tallyApiUrl;
  final now = DateTime.now();

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    searchController.addListener(_onSearchChanged);
    loadUserRole();
  }

  @override
  void onClose() {
    scrollController.dispose();
    searchController.dispose();
    _searchDebounce?.cancel();
    super.onClose();
  }

  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    userRole.value = prefs.getString('userRole') ?? '';
    userDepartment.value = prefs.getString('userDepartment') ?? '';
    if (userRole.isNotEmpty) {
      await fetchInitialData();
    }
  }

  void _scrollListener() {
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      if (!isLoadingMore.value && hasMoreData.value) {
        loadMoreData();
      }
    }
  }

  Future<void> fetchInitialData() async {
    try {
      isInitialLoad.value = true;
      currentPage.value = 1;
      hasMoreData.value = true;
      final data = await fetchVoucherData(1);
      filteredData.assignAll(data);
      isInitialLoad.value = false;
    } catch (e) {
      Get.snackbar('Error', 'Failed to load initial data',
          backgroundColor: Colors.red);
    }
  }

  Future<void> loadMoreData() async {
    if (isLoadingMore.value || !hasMoreData.value) return;

    isLoadingMore.value = true;

    try {
      final newPage = currentPage.value + 1;
      final newData = await fetchVoucherData(newPage);

      if (newData.isEmpty) {
        hasMoreData.value = false;
      } else {
        filteredData.addAll(newData);
        currentPage.value = newPage;
      }
    } catch (e) {
      debugPrint('Error loading more data: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (searchController.text.isEmpty) {
        await resetToInitialData();
      } else {
        await performSearch();
      }
    });
  }

  Future<void> resetToInitialData() async {
    isLoadingMore.value = true;
    currentPage.value = 1;
    hasMoreData.value = true;

    try {
      final newData = await fetchVoucherData(1);
      filteredData.assignAll(newData);
      isInitialLoad.value = false;
    } catch (e) {
      debugPrint('Error resetting data: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> performSearch() async {
    final searchTerm = searchController.text.toLowerCase();
    if (searchTerm.isEmpty) {
      await resetToInitialData();
      return;
    }

    isLoadingMore.value = true;

    try {
      final firstPageData = await fetchVoucherData(1);
      filteredData.assignAll(firstPageData.where((voucher) {
        return voucher.voucherNumber?.toLowerCase().contains(searchTerm) ==
                true ||
            voucher.ledgerName?.toLowerCase().contains(searchTerm) == true ||
            voucher.amount?.toString().contains(searchTerm) == true ||
            voucher.date?.toLowerCase().contains(searchTerm) == true;
      }).toList());

      currentPage.value = 1;
      hasMoreData.value = false;
      isInitialLoad.value = false;
    } catch (e) {
      debugPrint('Error searching: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> refreshData() async {
    if (isRefreshing.value) return;

    isRefreshing.value = true;
    currentPage.value = 1;
    hasMoreData.value = true;

    try {
      await loadUserRole();
      final newData = await fetchVoucherData(1);
      filteredData.assignAll(newData);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      isRefreshing.value = false;
    }
  }

  bool get isAllSelected {
    if (filteredData.isEmpty) return false;
    return filteredData.asMap().entries.every((e) {
      final isRejected = [
        e.value.level1,
        e.value.level2,
        e.value.level3,
        e.value.level4,
        e.value.level5,
        e.value.level6,
        e.value.level7,
      ].any((level) => level?.toLowerCase().contains('rejected') ?? false);
      if (isRejected) return true; // Skip checking rejected items
      return selectedItems[e.key] ?? false;
    });
  }

  void toggleSelectAll() {
    final selectAll = !isAllSelected;
    for (int i = 0; i < filteredData.length; i++) {
      final isRejected = [
        filteredData[i].level1,
        filteredData[i].level2,
        filteredData[i].level3,
        filteredData[i].level4,
        filteredData[i].level5,
        filteredData[i].level6,
        filteredData[i].level7,
      ].any((level) => level?.toLowerCase().contains('rejected') ?? false);
      if (!isRejected) {
        selectedItems[i] = selectAll;
      }
    }
  }

  void toggleItemSelection(int index) {
    final currentValue = selectedItems[index] ?? false;
    selectedItems[index] = !currentValue;
  }

  Future<void> approveVoucher(Voucher voucher, bool isApproved, {String? remarks}) async {
    // Validate voucher ID
    if (voucher.voucherId == null || voucher.voucherId!.isEmpty) {
      Get.snackbar(
        'Error',
        'Invalid voucher ID',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    final voucherDate = voucher.payDate ?? voucher.date;

    // Validate and format voucher date for Tally
    String? tallyFormattedDate;
    try {
      if (voucherDate == null || voucherDate.isEmpty) {
        throw Exception('Voucher date is missing');
      }
      tallyFormattedDate = _formatDateForTally(voucherDate);
    } catch (e) {
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    print(
        'approveVoucher called with voucher: ${voucher.voucherId}, isApproved: $isApproved');
    if (userRole.isEmpty) {
      print('User role is empty, returning');
      Get.snackbar(
        'Error',
        'User role not found',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
      return;
    }

    try {
      print('Current user role: ${userRole.value}');
      final levelKey = getCurrentLevelForUser(getEffectiveUserRole());
      print('Determined level key: $levelKey');

      final approvalStatus = PaymentApprovalStatus();
      final isFinalApprover = approvalStatus.isCurrentUserFinalApprover(
          voucher, userRole.value);
      final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
      final skipCentralCommittee = approvalStatus.shouldSkipCentralCommittee(
          voucher.department, amount);
      final requiredLevel = approvalStatus.getRequiredApprovalLevel(amount,
          department: voucher.department);
      final approvalLevelKeys = approvalStatus.getApprovalLevelKeys(
          skipCentralCommittee: skipCentralCommittee);

      // If user is approving and is the final approver, test/push to Tally FIRST
      if (isApproved && isFinalApprover) {
        try {
          await sendToTallyViaBackend(
            voucher.voucherId!,
            tallyFormattedDate,
            voucher.voucherNumber ?? 'VOUCHER-${voucher.voucherId}',
          );
        } catch (tallyError) {
          debugPrint("Tally unreachable/offline error in approveVoucher: $tallyError");
          Get.snackbar(
            'Tally Offline / Unreachable',
            'Tally is not opened or active. Please ensure Tally ERP is open and try approving again.',
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            icon: const Icon(Icons.cloud_off, color: Colors.white),
            duration: const Duration(seconds: 5),
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
      }

      final now = DateTime.now();
      final formattedDate =
          '${now.day}/${now.month}/${now.year} at ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';

      final reasonText = (remarks != null && remarks.trim().isNotEmpty) ? ' (Reason: ${remarks.trim()})' : '';
      final Map<String, dynamic> requestBody = {
        'voucherId': voucher.voucherId,
        levelKey: isApproved
            ? 'approved by ${getRoleTitle(userRole.value)} on $formattedDate'
            : 'rejected by ${getRoleTitle(userRole.value)} on $formattedDate$reasonText',
      };

      // If final approval, set sent_to_tally = 1 & skip remaining
      if (isApproved && isFinalApprover) {
        requestBody['sent_to_tally'] = 1;
        final currentUserRole = userRole.value;
        final skipMessage = 'skipped (pushed to tally by $currentUserRole)';
        for (int i = requiredLevel; i < approvalLevelKeys.length; i++) {
          requestBody[approvalLevelKeys[i]] = skipMessage;
        }
      }

      print('Request body: $requestBody');

      final url =
          '${Config_new.baseUrl}/opg/vouchers/payment_approve/${voucher.voucherId}';
      print('Making PUT request to: $url');

      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Success - removing voucher from filteredData');
        filteredData.removeWhere((v) => v.voucherId == voucher.voucherId);
        print('Clearing selected items');
        selectedItems.clear();
        print('Refreshing data');
        refreshData();

        // After successful HOD approval, set the next waiting status based on department
        if (getCurrentLevelForUser(getEffectiveUserRole()) == 'level1' &&
            isApproved) {
          // Debug print the full voucher object to trace department field
          try {
            print('DEBUG: voucher object: ' + json.encode(voucher));
          } catch (e) {
            print(
                'DEBUG: voucher object could not be encoded: ' + e.toString());
          }
          final skipLevel2Departments = [
            'CoalPurchase',
            'HR&Admin',
            'Admin-Ho',
            'CSR',
            'Finance',
            'Accounts',
            'Legal',
            'IT-HO',
            'secretary',
            'epc'
          ];
          final fleetDepartments = ['Feelt', 'Fleet'];
          final department = voucher.department?.toString() ?? '';
          String? nextLevelKey;
          final url =
              '${Config_new.baseUrl}/opg/vouchers/payment_approve/${voucher.voucherId}';
          // Normalize department for robust matching
          String normalizedDepartment =
              department.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final normalizedSkipLevel2Departments = skipLevel2Departments
              .map((d) => d.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
              .toList();
          final normalizedFleetDepartments = fleetDepartments
              .map((d) => d.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
              .toList();

          print('DEBUG: department raw: "$department"');
          print('DEBUG: normalizedDepartment: "$normalizedDepartment"');
          print(
              'DEBUG: normalizedSkipLevel2Departments: $normalizedSkipLevel2Departments');
          print(
              'DEBUG: normalizedFleetDepartments: $normalizedFleetDepartments');

          if (normalizedSkipLevel2Departments.contains(normalizedDepartment)) {
            print(
                'DEBUG: Department matched skipLevel2Departments, skipping all Level 2 approvals');
            nextLevelKey = 'level3';
            // Set all Level 2 fields to 'skipped' for skip-level-2 departments
            final clearLevel2Request = {
              'voucherId': voucher.voucherId,
              'level2_1': 'skipped',
              'level2_2': 'skipped',
              'level2_3': 'skipped'
            };
            final clearLevel2Response = await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(clearLevel2Request),
            );
            print('DEBUG: clearLevel2Request: $clearLevel2Request');
            print(
                'DEBUG: clearLevel2Response: ${clearLevel2Response.statusCode} ${clearLevel2Response.body}');
            print(
                'DEBUG: Setting nextLevelKey to level3 (m(a/cs)) for skip-level-2 department');
          } else if (normalizedFleetDepartments
              .contains(normalizedDepartment)) {
            print(
                'DEBUG: Department matched fleetDepartments, skipping Level 2.1 and 2.2');
            nextLevelKey = 'level2_3';
            // Set only Level 2.1 and 2.2 to 'skipped' for Fleet/Feelt
            final clearLevel2Request = {
              'voucherId': voucher.voucherId,
              'level2_1': 'skipped',
              'level2_2': 'skipped'
            };
            final clearLevel2Response = await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(clearLevel2Request),
            );
            print('DEBUG: clearLevel2Request: $clearLevel2Request');
            print(
                'DEBUG: clearLevel2Response: ${clearLevel2Response.statusCode} ${clearLevel2Response.body}');
            print(
                'DEBUG: Setting nextLevelKey to level2_3 for Fleet/Feelt department');
          } else {
            print(
                'DEBUG: Department did not match any skip logic, proceeding to Level 2.1');
            nextLevelKey = 'level2_1';
          }

          // Only set the next level to 'waiting for approval' for the correct nextLevelKey
          print(
              'DEBUG: nextLevelKey to be set to waiting for approval: $nextLevelKey');
          final Map<String, dynamic> nextStepRequest = {
            'voucherId': voucher.voucherId,
            nextLevelKey: 'waiting for approval'
          };
          final nextStepResponse = await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(nextStepRequest),
          );
          print('Next step update sent: $nextStepRequest');
          print(
              'Next step update response: ${nextStepResponse.statusCode} ${nextStepResponse.body}');
          // Optionally, fetch and print the updated voucher state here if needed
          await refreshData();
        }

        if (isApproved && isFinalApprover) {
          Get.snackbar(
            'Success!',
            'Voucher approved and sent to Tally successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          );
        } else {
          Get.snackbar(
            'Success!',
            isApproved
                ? 'Voucher approved successfully'
                : 'Voucher rejected successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
          );
        }

        Get.offAllNamed(AppRoutes.home);
      } else {
        final errorMessage = responseData['message'] ??
            responseData['error'] ??
            'Operation failed';
        print('Error response: $errorMessage');
        Get.snackbar(
          'Error',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          icon: Icon(Icons.error_outline, color: Colors.white),
        );
      }
    } catch (e) {
      print('Exception caught: $e');
      Get.snackbar(
        'Network Error',
        'Error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: Icon(Icons.error_outline, color: Colors.white),
      );
    }
  }

  Future<ApprovalResult> approveVoucherWithResult(
      Voucher voucher, bool isApproved, {String? remarks}) async {
    if (voucher.voucherId == null || voucher.voucherId!.isEmpty) {
      return ApprovalResult(
        voucherNumber: voucher.voucherNumber ?? 'Unknown',
        status: ApprovalStatus.unknown,
        voucherDate: voucher.date,
        voucherAmount: double.tryParse(voucher.amount ?? ''),
      );
    }
    final voucherDate = voucher.payDate ?? voucher.date;
    String? tallyFormattedDate;
    try {
      if (voucherDate == null || voucherDate.isEmpty) {
        throw Exception('Voucher date is missing');
      }
      tallyFormattedDate = _formatDateForTally(voucherDate);
    } catch (e) {
      return ApprovalResult(
        voucherNumber: voucher.voucherNumber ?? 'Unknown',
        status: ApprovalStatus.unknown,
        voucherDate: voucher.date,
        voucherAmount: double.tryParse(voucher.amount ?? ''),
      );
    }
    if (userRole.isEmpty) {
      return ApprovalResult(
        voucherNumber: voucher.voucherNumber ?? 'Unknown',
        status: ApprovalStatus.unknown,
        voucherDate: voucher.date,
        voucherAmount: double.tryParse(voucher.amount ?? ''),
      );
    }
    try {
      final levelKey = getCurrentLevelForUser(getEffectiveUserRole());
      final now = DateTime.now();
      final formattedDate =
          '${now.day}/${now.month}/${now.year} at ${now.hour % 12 == 0 ? 12 : now.hour % 12}:${now.minute.toString().padLeft(2, '0')} ${now.hour < 12 ? 'AM' : 'PM'}';
      final reasonText = (remarks != null && remarks.trim().isNotEmpty) ? ' (Reason: ${remarks.trim()})' : '';

      final approvalStatus = PaymentApprovalStatus();
      final isFinalApprover = approvalStatus.isCurrentUserFinalApprover(
          voucher, userRole.value);
      final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
      final skipCentralCommittee = approvalStatus.shouldSkipCentralCommittee(
          voucher.department, amount);
      final requiredLevel = approvalStatus.getRequiredApprovalLevel(amount,
          department: voucher.department);
      final approvalLevelKeys = approvalStatus.getApprovalLevelKeys(
          skipCentralCommittee: skipCentralCommittee);

      // If user is approving and is the final approver, test/push to Tally FIRST
      if (isApproved && isFinalApprover) {
        try {
          await sendToTallyViaBackend(
            voucher.voucherId!,
            tallyFormattedDate,
            voucher.voucherNumber ?? 'VOUCHER-${voucher.voucherId}',
          );
        } catch (tallyError) {
          debugPrint("Tally unreachable/offline error: $tallyError");
          Get.snackbar(
            'Tally Offline / Unreachable',
            'Tally is not opened or active. Please ensure Tally ERP is open and try approving again.',
            backgroundColor: Colors.red.shade700,
            colorText: Colors.white,
            icon: const Icon(Icons.cloud_off, color: Colors.white),
            duration: const Duration(seconds: 5),
            snackPosition: SnackPosition.BOTTOM,
          );
          return ApprovalResult(
            voucherNumber: voucher.voucherNumber ?? 'Unknown',
            status: ApprovalStatus.unknown,
            voucherDate: voucher.date,
            voucherAmount: amount,
          );
        }
      }

      final Map<String, dynamic> requestBody = {
        'voucherId': voucher.voucherId,
        levelKey: isApproved
            ? 'approved by ${getRoleTitle(userRole.value)} on $formattedDate'
            : 'rejected by ${getRoleTitle(userRole.value)} on $formattedDate$reasonText',
      };

      // If final approval was pushed to Tally, set sent_to_tally = 1 & skip remaining in same/subsequent request
      if (isApproved && isFinalApprover) {
        requestBody['sent_to_tally'] = 1;
        final currentUserRole = userRole.value;
        final skipMessage = 'skipped (pushed to tally by $currentUserRole)';
        for (int i = requiredLevel; i < approvalLevelKeys.length; i++) {
          requestBody[approvalLevelKeys[i]] = skipMessage;
        }
      }

      final url =
          '${Config_new.baseUrl}/opg/vouchers/payment_approve/${voucher.voucherId}';
      final response = await http.put(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      final responseData = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        filteredData.removeWhere((v) => v.voucherId == voucher.voucherId);
        selectedItems.clear();
        refreshData();
        // Fetch the updated voucher from the backend, retrying until the approval is reflected
        final approvalText = isApproved ? 'approved' : 'rejected';
        final updatedVoucher = await fetchVoucherById(
          voucher.voucherId!,
          expectedLevelKey: levelKey,
          expectedApprovalText: approvalText,
        );
        final usedVoucher = updatedVoucher ?? voucher;
        if (getCurrentLevelForUser(getEffectiveUserRole()) == 'level1' &&
            isApproved &&
            !isFinalApprover) {
          final skipLevel2Departments = [
            'CoalPurchase',
            'HR&Admin',
            'Admin-Ho',
            'CSR',
            'Finance',
            'Accounts',
            'Legal',
            'IT-HO',
            'secretary',
            'epc'
          ];
          final fleetDepartments = ['Feelt', 'Fleet'];
          final department = usedVoucher.department?.toString() ?? '';
          String? nextLevelKey;
          final url =
              '${Config_new.baseUrl}/opg/vouchers/payment_approve/${usedVoucher.voucherId}';
          String normalizedDepartment =
              department.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
          final normalizedSkipLevel2Departments = skipLevel2Departments
              .map((d) => d.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
              .toList();
          final normalizedFleetDepartments = fleetDepartments
              .map((d) => d.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''))
              .toList();
          if (normalizedSkipLevel2Departments.contains(normalizedDepartment)) {
            nextLevelKey = 'level3';
            final clearLevel2Request = {
              'voucherId': usedVoucher.voucherId,
              'level2_1': 'skipped',
              'level2_2': 'skipped',
              'level2_3': 'skipped'
            };
            await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(clearLevel2Request),
            );
          } else if (normalizedFleetDepartments
              .contains(normalizedDepartment)) {
            nextLevelKey = 'level2_3';
            final clearLevel2Request = {
              'voucherId': usedVoucher.voucherId,
              'level2_1': 'skipped',
              'level2_2': 'skipped'
            };
            await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(clearLevel2Request),
            );
          } else {
            nextLevelKey = 'level2_1';
          }
          final Map<String, dynamic> nextStepRequest = {
            'voucherId': usedVoucher.voucherId,
            nextLevelKey: 'waiting for approval'
          };
          await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(nextStepRequest),
          );
          await refreshData();
        }

        if (isApproved && isFinalApprover) {
          return ApprovalResult(
            voucherNumber: usedVoucher.voucherNumber ?? 'Unknown',
            status: ApprovalStatus.pushedToTally,
            voucherDate: usedVoucher.date,
            voucherAmount: double.tryParse(usedVoucher.amount ?? ''),
          );
        } else if (isApproved) {
          return ApprovalResult(
            voucherNumber: usedVoucher.voucherNumber ?? 'Unknown',
            status: ApprovalStatus.approved,
            voucherDate: usedVoucher.date,
            voucherAmount: double.tryParse(usedVoucher.amount ?? ''),
          );
        } else {
          return ApprovalResult(
            voucherNumber: usedVoucher.voucherNumber ?? 'Unknown',
            status: ApprovalStatus.rejected,
            voucherDate: usedVoucher.date,
            voucherAmount: double.tryParse(usedVoucher.amount ?? ''),
          );
        }
      } else {
        return ApprovalResult(
          voucherNumber: voucher.voucherNumber ?? 'Unknown',
          status: ApprovalStatus.unknown,
          voucherDate: voucher.date,
          voucherAmount: double.tryParse(voucher.amount ?? ''),
        );
      }
    } catch (e) {
      return ApprovalResult(
        voucherNumber: voucher.voucherNumber ?? 'Unknown',
        status: ApprovalStatus.unknown,
        voucherDate: voucher.date,
        voucherAmount: double.tryParse(voucher.amount ?? ''),
      );
    }
  }

  Future<void> sendToTallyViaBackend(
      String voucherId, String voucherDate, String voucherNumber) async {
    try {
      // Generate a default voucher number if none exists
      final vchKey =
          voucherNumber.isEmpty ? 'VOUCHER-$voucherId' : voucherNumber;

      // Prepare XML request
      final formattedDate = _formatDateForTally(voucherDate);
      final xmlRequest =
          _buildTallyXmlRequest(voucherId, formattedDate, vchKey);

      debugPrint("Sending to backend:\n$xmlRequest");

      // Make the HTTP request to our Node.js backend
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {
              "Content-Type": "application/xml",
              "Accept": "application/xml",
            },
            body: xmlRequest,
          )
          .timeout(
            const Duration(seconds: connectionTimeoutSeconds),
          );

      _handleTallyResponse(response);
    } catch (e) {
      debugPrint("sendToTallyViaBackend error: $e");
      rethrow;
    }
  }

  String _buildTallyXmlRequest(
      String voucherId, String formattedDate, String vchKey) {
    return '''<ENVELOPE>
  <HEADER>
    <VERSION>1</VERSION>
    <TALLYREQUEST>Import</TALLYREQUEST>
    <TYPE>Data</TYPE>
    <ID>Vouchers</ID>
  </HEADER>
  <BODY>
    <DESC></DESC>
    <DATA>
      <TALLYMESSAGE>
        <VOUCHER DATE="$formattedDate" ACTION="Alter" TAGNAME="MasterID" TAGVALUE="$voucherId" VCHKEY="vchKey">
          <ISOPTIONAL>No</ISOPTIONAL>
        </VOUCHER>
      </TALLYMESSAGE>
    </DATA>
  </BODY>
</ENVELOPE>''';
  }

  void _handleTallyResponse(http.Response response) {
    debugPrint("Backend Response: ${response.statusCode}\n${response.body}");

    if (response.statusCode == 200) {
      if (response.body.contains('CREATED') ||
          response.body.contains('ALTERED') ||
          !response.body.contains('ERROR')) {
        _showSuccessSnackbar('Tally update successful');
      } else {
        throw Exception('Tally error: ${_parseTallyError(response.body)}');
      }
    } else {
      throw HttpException(
        'HTTP error ${response.statusCode}',
        uri: Uri.parse(_backendUrl),
      );
    }
  }

  String _parseTallyError(String responseBody) {
    try {
      final start = responseBody.indexOf('<LINEERROR>') + '<LINEERROR>'.length;
      final end = responseBody.indexOf('</LINEERROR>');
      if (start >= 0 && end > start) {
        return responseBody.substring(start, end);
      }
      return responseBody;
    } catch (e) {
      return responseBody;
    }
  }

  void _handleError(dynamic e) {
    String errorMessage;

    if (e is SocketException) {
      errorMessage = 'Network Error: Please check your internet connection';
    } else if (e is TimeoutException) {
      errorMessage = 'Connection Timeout: Server is not responding';
    } else if (e is http.ClientException) {
      errorMessage = 'Failed to connect to the server';
    } else {
      errorMessage = 'Error: ${e.toString()}';
    }

    _showErrorSnackbar(errorMessage);
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red[400],
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green[400],
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  String _formatDateForTally(String inputDate) {
    try {
      DateTime date;
      debugPrint('Formatting date for Tally: $inputDate');
      // Try ISO 8601 (with T and Z)
      if (RegExp(r'^\d{4}-\d{2}-\d{2}T').hasMatch(inputDate)) {
        date = DateTime.parse(inputDate);
      } else if (inputDate.contains('-')) {
        final parts = inputDate.split('-');
        if (parts[0].length == 4) {
          date = DateTime.parse(inputDate);
        } else {
          date = DateFormat('dd-MM-yyyy').parse(inputDate);
        }
      } else if (inputDate.contains('/')) {
        date = DateFormat('dd/MM/yyyy').parse(inputDate);
      } else {
        try {
          date = DateTime.parse(inputDate);
        } catch (_) {
          try {
            date = DateFormat('d MMMM yyyy').parse(inputDate);
          } catch (e2) {
            debugPrint('Error formatting date (d MMMM yyyy fallback): $e2');
            throw e2;
          }
        }
      }
      return DateFormat('dd-MMM-yyyy').format(date);
    } catch (e) {
      debugPrint('Error formatting date for Tally: $e | input: $inputDate');
      return inputDate;
    }
  }

  String formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final parts = dateString.split(' at ');
      if (parts.isNotEmpty) {
        return parts[0];
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  String getRoleTitle(String userRole) {
    print('getRoleTitle called with: $userRole');
    switch (userRole.toLowerCase()) {
      case 'hod or sbu head':
        return 'HOD or SBU Head';
      case 'central committee':
        return 'Central Committee';
      case 'm(a/cs)':
        return 'M(A/cs)';
      case 'ho-operations':
        return 'HO-Operations';
      case 'p(f&a)':
        return 'P(F&A)';
      case 'head-commercial':
        return 'Head-Commercial';
      case 'ceo':
        return 'CEO';
      default:
        print('Unknown role: $userRole');
        return userRole;
    }
  }

  String getCurrentLevelForUser(String userRole) {
    print('getCurrentLevelForUser called with: $userRole');
    switch (userRole.toLowerCase()) {
      case 'hod or sbu head':
        return 'level1';
      case 'central committee 1':
      case 'centralcommittee1':
        return 'level2_1';
      case 'central committee 2':
      case 'centralcommittee2':
        return 'level2_2';
      case 'central committee 3':
      case 'centralcommittee3':
        return 'level2_3';
      case 'm(a/cs)':
      case 'macs':
        return 'level3';
      case 'ho-operations':
      case 'hooperations':
        return 'level4';
      case 'p(f&a)':
      case 'pfa':
        return 'level5';
      case 'head-commercial':
      case 'headcommercial':
        return 'level6';
      case 'ceo':
        return 'level7';
      default:
        print('Unknown role, defaulting to level1');
        return 'level1';
    }
  }

  bool shouldSkipCentralCommittee() {
    const restrictedDepartments = [
      'CoalPurchase',
      'HR&Admin',
      'Admin-Ho',
      'CSR',
      'Finance',
      'Accounts',
      'Legal',
      'IT-HO',
      'secretary',
      'epc',
    ];
    return restrictedDepartments.contains(userDepartment.value);
  }

  String getRejectedBy(Voucher voucher) {
    print('getRejectedBy called for voucher: ${voucher.voucherId}');
    if (voucher.level1?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level1');
      return 'HOD or SBU Head (Level 1)';
    }
    if (voucher.level2_1?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level2_1');
      return 'Central Committee (Level 2.1)';
    }
    if (voucher.level2_2?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level2_2');
      return 'Central Committee (Level 2.2)';
    }
    if (voucher.level2_3?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level2_3');
      return 'Central Committee (Level 2.3)';
    }
    if (voucher.level3?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level3');
      return 'M(A/cs) (Level 3)';
    }
    if (voucher.level4?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level4');
      return 'HO-Operations (Level 4)';
    }
    if (voucher.level5?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level5');
      return 'P(F&A) (Level 5)';
    }
    if (voucher.level6?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level6');
      return 'Head-Commercial (Level 6)';
    }
    if (voucher.level7?.toLowerCase().contains('rejected') ?? false) {
      print('Rejected at level7');
      return 'CEO (Level 7)';
    }
    print('No rejection found or unknown rejection level');
    return 'Unknown';
  }

  double parseAmount(dynamic amount) {
    if (amount == null) return 0.0;
    if (amount is int) return amount.toDouble();
    if (amount is double) return amount;
    if (amount is String) return double.tryParse(amount) ?? 0.0;
    return 0.0;
  }

  Future<List<Voucher>> fetchVoucherData(int page) async {
    try {
      final response = await http.get(
        Uri.parse('${Config_new.baseUrl}/opg/vouchers/get-payment?page=$page'),
        headers: {'Content-Type': 'application/json'},
      );

      // Debug print the raw API response to check for department field
      print('DEBUG: Raw API response for vouchers: ' + response.body);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> data = decoded is Map
            ? decoded['data'] as List? ?? []
            : decoded is List
                ? decoded
                : [];

        final rawVouchers = data
            .map((item) {
              try {
                return Voucher.fromJson(item as Map<String, dynamic>);
              } catch (e) {
                return Voucher();
              }
            })
            .where((v) => v.voucherNumber != null)
            .toList();

        return filterVouchersByRole(rawVouchers);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  List<Voucher> filterVouchersByRole(List<Voucher> rawVouchers) {
    String normalizedUserRole = getEffectiveUserRole();
    if (userRole.isEmpty) {
      return [];
    }
    final approvalStatus = PaymentApprovalStatus();
    return rawVouchers.where((voucher) {
      // 1. If rejected, only show to the user who rejected
      final isRejected = [
        voucher.level1,
        voucher.level2_1,
        voucher.level2_2,
        voucher.level2_3,
        voucher.level3,
        voucher.level4,
        voucher.level5,
        voucher.level6,
        voucher.level7,
      ].any((level) => (level?.toLowerCase() ?? '').contains('rejected'));
      if (isRejected) {
        final rejectedBy = getRejectedBy(voucher).toLowerCase();
        return rejectedBy.contains(normalizedUserRole);
      }
      // 2. If already approved by this user, hide
      final hasCurrentUserApproved = [
        voucher.level1,
        voucher.level2_1,
        voucher.level2_2,
        voucher.level2_3,
        voucher.level3,
        voucher.level4,
        voucher.level5,
        voucher.level6,
        voucher.level7,
      ].any((level) {
        if (level == null) return false;
        final levelLower = level.toLowerCase();
        return levelLower.contains('approved') &&
            levelLower.contains(normalizedUserRole);
      });
      if (hasCurrentUserApproved) {
        return false;
      }
      // 3. Determine department-based approval chain
      final department = voucher.department?.toString() ?? '';
      final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
      final skipLevel2 =
          approvalStatus.shouldSkipCentralCommittee(department, amount);
      final skipToLevel23 = approvalStatus.shouldSkipToLevel23(department);
      final requiredLevel = approvalStatus.getRequiredApprovalLevel(amount,
          department: department);
      // 4. Build the ordered approval chain for this voucher
      List<String> approvalChain;
      if (skipLevel2) {
        approvalChain = [
          'level1',
          'level3',
          'level4',
          'level5',
          'level6',
          'level7'
        ];
      } else if (skipToLevel23) {
        approvalChain = [
          'level1',
          'level2_3',
          'level3',
          'level4',
          'level5',
          'level6',
          'level7'
        ];
      } else {
        approvalChain = [
          'level1',
          'level2_1',
          'level2_2',
          'level2_3',
          'level3',
          'level4',
          'level5',
          'level6',
          'level7'
        ];
      }
      approvalChain = approvalChain.take(requiredLevel).toList();
      // 5. Find the current pending approval level
      int currentPendingIndex = approvalChain.indexWhere((levelKey) {
        final value = voucherFieldValue(voucher, levelKey);
        return value.isEmpty || value.toLowerCase().contains('waiting');
      });
      if (currentPendingIndex == -1) {
        // All approvals done - check if voucher is fully approved
        final currentLevel = approvalStatus.getCurrentApprovalLevel(voucher);
        if (currentLevel >= requiredLevel) {
          return false; // Voucher is fully approved, don't show to anyone
        }
        // If we reach here, there might be an issue with the approval chain
        return false;
      }
      final currentPendingLevel = approvalChain[currentPendingIndex];
      // 6. Map user role to approval level
      final roleToLevel = {
        'hodorsbuhead': 'level1',
        'hod': 'level1',
        'sbuhead': 'level1',
        'centralcommittee1': 'level2_1',
        'centralcommittee2': 'level2_2',
        'centralcommittee3': 'level2_3',
        'ma/cs': 'level3',
        'macs': 'level3',
        'hooperations': 'level4',
        'pfa': 'level5',
        'headcommercial': 'level6',
        'ceo': 'level7',
      };
      final userLevelKey = roleToLevel[normalizedUserRole];
      if (userLevelKey == null) return false;
      // 7. Only show if this user's level is the current pending one
      return userLevelKey == currentPendingLevel;
    }).toList();
  }

  // Helper to get the value of a voucher approval field by key
  String voucherFieldValue(Voucher voucher, String field) {
    switch (field) {
      case 'level1':
        return voucher.level1 ?? '';
      case 'level2_1':
        return voucher.level2_1 ?? '';
      case 'level2_2':
        return voucher.level2_2 ?? '';
      case 'level2_3':
        return voucher.level2_3 ?? '';
      case 'level3':
        return voucher.level3 ?? '';
      case 'level4':
        return voucher.level4 ?? '';
      case 'level5':
        return voucher.level5 ?? '';
      case 'level6':
        return voucher.level6 ?? '';
      case 'level7':
        return voucher.level7 ?? '';
      default:
        return '';
    }
  }

  // Helper to get the effective user role, normalized and mapped by department for central committee
  String getEffectiveUserRole() {
    String normalizedUserRole =
        userRole.value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final normalizedUserDepartment =
        userDepartment.value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (normalizedUserRole.startsWith('centralcommittee')) {
      if (normalizedUserDepartment.contains('2')) {
        normalizedUserRole = 'centralcommittee2';
      } else if (normalizedUserDepartment.contains('3')) {
        normalizedUserRole = 'centralcommittee3';
      } else if (normalizedUserDepartment.contains('1')) {
        normalizedUserRole = 'centralcommittee1';
      }
    }
    return normalizedUserRole;
  }

  // Add this helper method to fetch the updated voucher by ID
  Future<Voucher?> fetchVoucherById(String voucherId,
      {String? expectedLevelKey, String? expectedApprovalText}) async {
    for (int attempt = 0; attempt < 10; attempt++) {
      try {
        final url =
            '${Config_new.baseUrl}/opg/vouchers/payment-approve/voucher/$voucherId';
        final response = await http.get(Uri.parse(url));
        print(
            '[DEBUG] Raw response for voucherId $voucherId: ${response.body}');
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic> && data['data'] != null) {
            final voucher = Voucher.fromJson(data['data']);
            // Debug print the approval levels for investigation
            print('[Fetch Attempt ${attempt + 1}] Voucher approval levels:');
            print('level1: 	${voucher.level1}');
            print('level2_1: 	${voucher.level2_1}');
            print('level2_2: 	${voucher.level2_2}');
            print('level2_3: 	${voucher.level2_3}');
            print('level3: 	${voucher.level3}');
            print('level4: 	${voucher.level4}');
            print('level5: 	${voucher.level5}');
            print('level6: 	${voucher.level6}');
            print('level7: 	${voucher.level7}');
            if (expectedLevelKey != null && expectedApprovalText != null) {
              final levelValue =
                  voucher.toJson()[expectedLevelKey]?.toString() ?? '';
              print(
                  '[Fetch Attempt ${attempt + 1}] Level $expectedLevelKey value: $levelValue');
              if (levelValue.contains(expectedApprovalText)) {
                print(
                    '[Fetch Attempt ${attempt + 1}] Approval reflected in backend.');
                return voucher;
              }
            } else {
              return voucher;
            }
          }
        }
      } catch (e) {
        print('[Fetch Attempt ${attempt + 1}] Error: $e');
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
    print('[Fetch] Approval not reflected after retries.');
    return null;
  }
}
