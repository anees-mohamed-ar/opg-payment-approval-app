# OPG Payment Approval Flow & Logic Documentation

This document outlines the complete approval hierarchy, amount thresholds, department skip rules, and role mappings used in the OPG Payment Approval System.

---

## 1. Approval Hierarchy (Standard Levels)

In the database and backend, the approval chain consists of up to 9 logical positions mapped across 7 database level columns:

| Level Key | Role Title | Description / Authority |
| :--- | :--- | :--- |
| **`level1`** | **HOD or SBU Head** | Head of Department / Strategic Business Unit Head |
| **`level2_1`** | **Central Committee (1)** | Committee Member 1 (Site/Plant Review) |
| **`level2_2`** | **Central Committee (2)** | Committee Member 2 |
| **`level2_3`** | **Central Committee (3)** | Committee Member 3 |
| **`level3`** | **M(A/cs)** | Manager / Deputy Manager - Accounts |
| **`level4`** | **HO-Operations** | Head Office Operations |
| **`level5`** | **P(F&A)** | President / Head of Finance & Accounts |
| **`level6`** | **Head-Commercial** | Head of Commercial |
| **`level7`** | **CEO** | Chief Executive Officer |

---

## 2. Department Classification & Skip Rules

The approval path for any payment voucher is determined by its **Department** and **Voucher Amount**.

### Category A: Departments that Skip Central Committee (`Level 2`)
*Condition: Applies when Amount $\le$ ₹1,00,000*

**Eligible Departments:**
- `Accounts`
- `Finance`
- `HR&Admin`
- `Admin-Ho`
- `Legal`
- `CSR`
- `CoalPurchase`
- `IT-HO`
- `secretary`
- `epc`

> **Rule:** If the voucher belongs to one of these departments **AND amount $\le$ ₹1,00,000**, it completely skips `level2_1`, `level2_2`, and `level2_3`. The voucher goes directly from **Level 1 (HOD)** to **Level 3 (M(A/cs))**.

---

### Category B: Fleet Department (Special Skip Rule)
**Eligible Departments:**
- `Fleet` / `Feelt`

> **Rule:** Skips `level2_1` and `level2_2` and routes directly to **`level2_3` (Central Committee 3)** after Level 1 (HOD).

---

### Category C: Plant & Technical Departments (Sequential / No Skip)
**Eligible Departments:**
- `MMD`, `EMD`, `IMD`, `O&E`, `CHP/AHP`, `WTA/LAB`, `Operation`, `EHS`, `Admin Plant`, `Civil`, `Material`, `IT-Plant`, `BioEnergy`, `Solar`

> **Rule:** Must go through all 3 Central Committee stages (`level2_1` $\rightarrow$ `level2_2` $\rightarrow$ `level2_3`) before advancing to Level 3.

---

## 3. Amount Thresholds & Required Final Approver

The maximum level a voucher must reach before being pushed to Tally is governed by the total amount:

```
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  Tier 1: Amount ≤ ₹1,00,000 (Up to ₹1 Lakh)                                                │
│  • Skip Departments: Level 1 (HOD) → Level 3 (M(A/cs))                                      │
│  • Normal Departments: Level 1 → Level 2.1 → Level 2.2 → Level 2.3 → Level 3 (M(A/cs))       │
│  • Final Approver: M(A/cs)                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  Tier 2: ₹1,00,001 to ₹5,00,000 (₹1 Lakh to ₹5 Lakhs)                                      │
│  • Level 1 → (Level 2.1 → 2.2 → 2.3) → Level 3 → Level 4 (HO-Ops) → Level 5 (P(F&A))       │
│  • Final Approver: P(F&A)                                                                  │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  Tier 3: ₹5,00,001 to ₹10,00,000 (₹5 Lakhs to ₹10 Lakhs)                                   │
│  • Level 1 → (Level 2) → Level 3 → Level 4 → Level 5 → Level 6 (Head-Commercial)            │
│  • Final Approver: Head-Commercial                                                         │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────┐
│  Tier 4: Amount > ₹10,00,000 (Above ₹10 Lakhs)                                              │
│  • Level 1 → (Level 2) → Level 3 → Level 4 → Level 5 → Level 6 → Level 7 (CEO)              │
│  • Final Approver: CEO                                                                      │
└─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Summary Table of Flow by Amount & Department

| Amount Range | Department Type | Approval Sequence Path | Final Approver Role |
| :--- | :--- | :--- | :--- |
| **$\le$ ₹1,00,000** | Skip Depts *(Accounts, Finance, etc.)* | `L1` $\rightarrow$ `L3` | **M(A/cs)** |
| **$\le$ ₹1,00,000** | Fleet | `L1` $\rightarrow$ `L2.3` $\rightarrow$ `L3` | **M(A/cs)** |
| **$\le$ ₹1,00,000** | Standard Plant Depts | `L1` $\rightarrow$ `L2.1` $\rightarrow$ `L2.2` $\rightarrow$ `L2.3` $\rightarrow$ `L3` | **M(A/cs)** |
| **₹1,00,001 - ₹5,00,000** | All Departments | `L1` $\rightarrow$ `L2` *(if req)* $\rightarrow$ `L3` $\rightarrow$ `L4` $\rightarrow$ `L5` | **P(F&A)** |
| **₹5,00,001 - ₹10,00,000** | All Departments | `L1` $\rightarrow$ `L2` $\rightarrow$ `L3` $\rightarrow$ `L4` $\rightarrow$ `L5` $\rightarrow$ `L6` | **Head-Commercial** |
| **$>$ ₹10,00,000** | All Departments | `L1` $\rightarrow$ `L2` $\rightarrow$ `L3` $\rightarrow$ `L4` $\rightarrow$ `L5` $\rightarrow$ `L6` $\rightarrow$ `L7` | **CEO** |

---

## 5. Tally Push & Completion Lifecycle

1. **Intermediate Approval**:
   - Approver approves $\rightarrow$ Level string updated (e.g., `"approved by HOD on 27/8/2026 at 11:07 AM"`).
   - Voucher moves to the next role's inbox.

2. **Final Approval (`isCurrentUserFinalApprover == true`)**:
   - Final Approver approves $\rightarrow$ XML payload generated and posted to `http://192.168.1.166:8080/api/tally`.
   - Any higher remaining levels in the DB table are set to: `"skipped (pushed to tally by <ROLE>)"`.
   - **`sent_to_tally = 1`** is set in the database table `payment_approve`.
   - Voucher is immediately moved out of all Inboxes and marked as **`Tally Done`** across the system.

3. **Rejection**:
   - If any level rejects $\rightarrow$ Level string set to `"rejected by <ROLE> on <DATE> (Reason: <REMARKS>)"`.
   - Voucher stops progressing and is permanently moved to **`Rejected`** tab (Read-only).
