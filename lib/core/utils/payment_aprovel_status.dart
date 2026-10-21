import 'package:flutter/material.dart';

import '../models/payment_model/PaymentVoucher.dart';
import '../models/payment_model/Voucher.dart';

class PaymentApprovalStatus {
  final Map<int, String> approvalStatus = {
    1: "Level1: HOD or SBU Head  Level2.1: Central Committee  Level2.2: Central Committee  Level2.3: Central Committee  Level3: DM-Accounts",
    2: "Level1: HOD or SBU Head  Level2.1: Central Committee  Level2.2: Central Committee  Level2.3: Central Committee  Level3: DM-Accounts  Level4: HO-Operations  Level5: P(F&A)",
    3: "Level1: HOD or SBU Head  Level2.1: Central Committee  Level2.2: Central Committee  Level2.3: Central Committee  Level3: DM-Accounts  Level4: HO-Operations  Level5: P(F&A)  Level6: Head-Commercial",
    4: "Level1: HOD or SBU Head  Level2.1: Central Committee  Level2.2: Central Committee  Level2.3: Central Committee  Level3: DM-Accounts  Level4: HO-Operations  Level5: P(F&A)  Level6: Head-Commercial  Level7: CEO",
  };

  final Map<int, String> levelNames = {
    1: "HOD or SBU Head",
    2: "Central Committee (1)",
    3: "Central Committee (2)",
    4: "Central Committee (3)",
    5: "M(A/cs)",
    6: "HO-Operations",
    7: "P(F&A)",
    8: "Head-Commercial",
    9: "CEO",
  };

  // Departments that skip Level 2 (Central Committee)
  final List<String> departmentsThatSkipLevel2 = [
    "CoalPurchase",
    "HR&Admin",
    "Admin-Ho",
    "CSR",
    "Finance",
    "Accounts",
    "Legal",
    "IT-HO",
    "secretary",
    "epc",
  ];
  // Departments that require sequential approval (must go through Level 2)
  final List<String> departmentsThatRequireSequential = [
    "MMD",
    "EMD",
    "IMD",
    "O&E",
    "CHP/AHP",
    "WTA/LAB",
    "Operation",
    "EHS",
    "Admin Plant",
    "Civil",
    "Material",
    "IT-Plant",
    "BioEnergy",
    "Solar"
  ];
  // Departments that skip directly to Level 2.3 (Fleet/Feelt)
  final List<String> departmentsThatSkipToLevel23 = ['Fleet', 'Fleet'];

  // Helper to determine if department should skip Central Committee
  bool shouldSkipCentralCommittee(String? department, double amount) {
    if (department == null) return false;
    final normalized = department.trim().toLowerCase();
    final skipList =
        departmentsThatSkipLevel2.map((d) => d.trim().toLowerCase()).toList();
    final skipTo23List = departmentsThatSkipToLevel23
        .map((d) => d.trim().toLowerCase())
        .toList();
    if (skipTo23List.contains(normalized)) return false;
    if (skipList.contains(normalized) && amount <= 100000) return true;
    return false;
  }

  // Helper to determine if department should skip to Level 2.3 (Fleet/Feelt)
  bool shouldSkipToLevel23(String? department) {
    if (department == null) return false;
    return departmentsThatSkipToLevel23.contains(department);
  }

  // Helper to get all approval levels in order, with option to skip central committee
  List<String> getApprovalLevelKeys({bool skipCentralCommittee = false}) {
    if (skipCentralCommittee) {
      return [
        'level1',
        'level3',
        'level4',
        'level5',
        'level6',
        'level7',
      ];
    }
    return [
      'level1',
      'level2_1',
      'level2_2',
      'level2_3',
      'level3',
      'level4',
      'level5',
      'level6',
      'level7',
    ];
  }

  // Gets the approval hierarchy based on amount with level labels
  String getApprovalStatus(double amount) {
    if (amount <= 100000) {
      return approvalStatus[1]!;
    } else if (amount <= 500000) {
      return approvalStatus[2]!;
    } else if (amount <= 1000000) {
      return approvalStatus[3]!;
    } else {
      return approvalStatus[4]!;
    }
  }

  // Gets the required approval level based on amount and skipCentralCommittee
  int getRequiredApprovalLevel(double amount, {String? department}) {
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    if (amount <= 100000)
      return skipCentralCommittee ? 2 : 5; // Up to Level3: M(A/cs) [2 steps for skip: level1, level3]
    if (amount <= 500000)
      return skipCentralCommittee ? 4 : 7; // Up to Level5: P(F&A) [4 steps for skip: level1, level3, level4, level5]
    if (amount <= 1000000)
      return skipCentralCommittee ? 5 : 8; // Up to Level6: Head-Commercial [5 steps for skip: level1, level3, level4, level5, level6]
    return skipCentralCommittee ? 6 : 9; // Up to Level7: CEO [6 steps for skip: level1, level3, level4, level5, level6, level7]
  }

  // Helper to get the required role for a given level, considering skip logic
  String getRequiredRole(int requiredLevel,
      {bool skipCentralCommittee = false}) {
    if (skipCentralCommittee) {
      // For skipping departments, chain is [level1, level3, level4, level5, level6, level7]
      if (requiredLevel == 6) return 'CEO';
      if (requiredLevel == 5) return 'Head-Commercial';
      if (requiredLevel == 4) return 'P(F&A)';
      if (requiredLevel == 3) return 'HO-Operations';
      if (requiredLevel == 2) return 'M(A/cs)';
      if (requiredLevel == 1) return 'HOD or SBU Head';
    }
    // Default mapping for non-skipping departments
    return levelNames[requiredLevel] ?? 'Unknown';
  }

  // Updated getCurrentApprovalLevel to handle skipCentralCommittee and Fleet/Feelt special case
  int getCurrentApprovalLevel(dynamic voucher) {
    String? department = voucher.department;
    final amount = double.tryParse(voucher.amount?.toString() ?? '0') ?? 0;
    // Always normalize department
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final skipToLevel23 = shouldSkipToLevel23(normalized);

    bool isDone(String? val) {
      if (val == null || val.trim().isEmpty) return false;
      final lower = val.trim().toLowerCase();
      return lower.contains('approved') || lower.contains('skipped');
    }

    if (voucher is Voucher || voucher is PaymentVoucher) {
      if (skipCentralCommittee) {
        if (isDone(voucher.level7)) return 6;
        if (isDone(voucher.level6)) return 5;
        if (isDone(voucher.level5)) return 4;
        if (isDone(voucher.level4)) return 3;
        if (isDone(voucher.level3)) return 2;
        if (isDone(voucher.level1)) return 1;
      } else if (skipToLevel23) {
        if (isDone(voucher.level7)) return 7;
        if (isDone(voucher.level6)) return 6;
        if (isDone(voucher.level5)) return 5;
        if (isDone(voucher.level4)) return 4;
        if (isDone(voucher.level3)) return 3;
        if (isDone(voucher.level2_3)) return 2;
        if (isDone(voucher.level1)) return 1;
      } else {
        if (isDone(voucher.level7)) return 9;
        if (isDone(voucher.level6)) return 8;
        if (isDone(voucher.level5)) return 7;
        if (isDone(voucher.level4)) return 6;
        if (isDone(voucher.level3)) return 5;
        if (isDone(voucher.level2_3)) return 4;
        if (isDone(voucher.level2_2)) return 3;
        if (isDone(voucher.level2_1)) return 2;
        if (isDone(voucher.level1)) return 1;
      }
    }
    return 0;
  }

  // Checks if the voucher is fully approved
  bool isFullyApproved(dynamic voucher) {
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    String? department = voucher.department;
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final requiredLevel =
        getRequiredApprovalLevel(amount, department: department);
    final currentLevel = getCurrentApprovalLevel(voucher);
    return currentLevel >= requiredLevel;
  }

  // Gets the next approver in sequence with level label
  String getNextApprover(Voucher voucher) {
    String? department = voucher.department;
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final currentLevel = getCurrentApprovalLevel(voucher);
    final requiredLevel =
        getRequiredApprovalLevel(amount, department: department);

    if (currentLevel >= requiredLevel) return "Fully Approved";
    if (currentLevel >= levelNames.length) return "No more approvers";

    return "Pending: Level${currentLevel + 1}: ${levelNames[currentLevel + 1]}";
  }

  // Gets the current approval progress with proper styling and level labels
  Widget getCurrentApprovalProgressWidget(Voucher voucher) {
    String? department = voucher.department;
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final requiredLevel =
        getRequiredApprovalLevel(amount, department: department);
    final currentLevel = getCurrentApprovalLevel(voucher);
    final progress = <Widget>[];

    for (int i = 1; i <= requiredLevel; i++) {
      final isCompleted = i <= currentLevel;
      final isCurrent = i == currentLevel + 1;
      final isPending = i > currentLevel;

      progress.add(
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withOpacity(0.2)
                : isCurrent
                    ? Colors.blue.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isCompleted
                  ? Colors.green
                  : isCurrent
                      ? Colors.blue
                      : Colors.grey,
              width: 1,
            ),
          ),
          child: Text(
            "Level$i: ${levelNames[i]}",
            style: TextStyle(
              color: isCompleted
                  ? Colors.green
                  : isCurrent
                      ? Colors.blue
                      : Colors.grey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      );

      if (i < requiredLevel) {
        progress.add(SizedBox(width: 8));
      }
    }

    return Wrap(
      children: progress,
      spacing: 4,
      runSpacing: 4,
    );
  }

  // Gets the final approver with level label
  String getFinalApproverOnly(Voucher voucher) {
    String? department = voucher.department;
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final requiredLevel =
        getRequiredApprovalLevel(amount, department: department);
    return "Level$requiredLevel: ${levelNames[requiredLevel] ?? "Unknown Approver"}";
  }

  // Checks if current user is the final approver
  bool isCurrentUserFinalApprover(Voucher voucher, String currentUserRole) {
    String? department = voucher.department;
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final requiredLevel =
        getRequiredApprovalLevel(amount, department: department);
    final requiredRole = getRequiredRole(requiredLevel,
        skipCentralCommittee: skipCentralCommittee);
    return currentUserRole == requiredRole;
  }

  List<Widget> _buildProcessedApprovalLevels(PaymentVoucher voucher) {
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final requiredLevel = getRequiredApprovalLevel(amount);

    Map<String, String?> levels = {
      'L1': voucher.level1,
      'L2': voucher.level2,
      'L3': voucher.level3,
      'L4': voucher.level4,
      'L5': voucher.level5,
      'L6': voucher.level6,
      'L7': voucher.level7,
    };

    // Filter out levels that haven't been processed AND levels beyond the required approval level
    var processedLevels = levels.entries.where((entry) {
      final levelNum = int.parse(entry.key.substring(1));
      final value = entry.value?.trim() ?? '';
      return value.isNotEmpty && levelNum <= requiredLevel;
    }).toList();

    return processedLevels.map((entry) {
      final level = entry.key;
      final value = entry.value?.trim() ?? '';

      // Determine status
      final isApproved = !value.toLowerCase().contains('waiting') &&
          !value.toLowerCase().contains('rejected');
      final isRejected = value.toLowerCase().contains('rejected');

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Tooltip(
          message: value,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isRejected
                  ? Colors.red[50]
                  : isApproved
                      ? Colors.green[50]
                      : Colors.orange[50],
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isRejected
                    ? Colors.red[300]!
                    : isApproved
                        ? Colors.green[300]!
                        : Colors.orange[300]!,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontFamily: 'inter',
                    fontSize: 10,
                    color: isRejected
                        ? Colors.red[600]
                        : isApproved
                            ? Colors.green[600]
                            : Colors.orange[600],
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  isApproved
                      ? Icons.check_circle
                      : isRejected
                          ? Icons.cancel
                          : Icons.access_time,
                  size: 16,
                  color: isRejected
                      ? Colors.red
                      : isApproved
                          ? Colors.green
                          : Colors.orange,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  bool isVoucherApproved(PaymentVoucher voucher) {
    String? department = voucher.department;
    final amount = double.tryParse(voucher.amount ?? '0') ?? 0;
    final normalized = department?.trim().toLowerCase();
    final skipCentralCommittee = shouldSkipCentralCommittee(normalized, amount);
    final requiredLevel =
        getRequiredApprovalLevel(amount, department: department);
    final currentLevel = getCurrentApprovalLevel(voucher);
    return currentLevel >= requiredLevel;
  }

  // New method to get complete approval flow with level labels
  String getCompleteApprovalFlow(double amount) {
    if (amount <= 100000) {
      return "Level1: HOD or SBU Head → Level2.1: Central Committee → Level2.2: Central Committee → Level2.3: Central Committee → Level3: M(A/cs)";
    } else if (amount <= 500000) {
      return "Level1: HOD or SBU Head → Level2.1: Central Committee → Level2.2: Central Committee → Level2.3: Central Committee → Level3: M(A/cs) → Level4: HO-Operations → Level5: P(F&A)";
    } else if (amount <= 1000000) {
      return "Level1: HOD or SBU Head → Level2.1: Central Committee → Level2.2: Central Committee → Level2.3: Central Committee → Level3: M(A/cs) → Level4: HO-Operations → Level5: P(F&A) → Level6: Head-Commercial";
    } else {
      return "Level1: HOD or SBU Head → Level2.1: Central Committee → Level2.2: Central Committee → Level2.3: Central Committee → Level3: M(A/cs) → Level4: HO-Operations → Level5: P(F&A) → Level6: Head-Commercial → Level7: CEO";
    }
  }
}
