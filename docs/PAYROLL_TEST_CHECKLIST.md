# SmartOffice Project — Module 11: Payroll Management Test Checklist

## 1. Overview
This checklist defines the manual and automated verification procedures for **Module 11: Payroll Management** of the SmartOffice Application. It covers security, concurrency, status workflow, calculation accuracy, attendance integration, and user interface compliance.

---

## 2. Test Matrix

### A. Database & Schema Integrity
- [ ] **A.1 Idempotent Schema Creation**: Running `sql/payroll_setup.sql` on a fresh or existing `employee_db` executes without syntax or constraint errors. *(Requires running MySQL 8 instance)*
- [ ] **A.2 Foreign Keys & Cascades**: Deleting or archiving test structures cleanly handles cascading component deletions without orphan rows. *(Requires running MySQL 8 instance)*
- [x] **A.3 Unique Constraints**:
  - `UNIQUE (salary_structure_id, component_name)` prevents duplicate component names within a salary structure.
  - `UNIQUE (employee_id, payroll_month, payroll_year)` prevents multiple payroll records for the same employee in the same period.
  - `UNIQUE (payroll_id)` in `payroll_payments` enforces one payment record per finalized payroll.
- [x] **A.4 Data Types & Precisions**: All monetary values are defined as `DECIMAL(12,2)`. Attendance day metrics are defined as `DECIMAL(5,1)`.

---

### B. Salary Structure Management
- [x] **B.1 Baseline Configuration**:
  - Positive basic salary required (`CHECK (basic_salary > 0)`).
  - Effective From date required; Effective To date optional (`CHECK (effective_to IS NULL OR effective_to >= effective_from)`).
- [x] **B.2 Historical Retention**:
  - Saving a revised salary structure creates a new record version rather than overwriting historical records.
  - The previous active structure is cleanly closed by setting `effective_to = effective_from - 1 day`.
- [x] **B.3 Frozen Period Protection**:
  - Attempting to revise or close a salary structure for a month that already has finalized (`PROCESSED` or `PAID`) payroll is blocked with a user-friendly error.
- [x] **B.4 Overlap Validation**:
  - Date intervals are validated to prevent conflicting overlapping effective periods for the same employee.
- [x] **B.5 Allowances & Deductions**:
  - Supports both `FIXED` amounts and `PERCENTAGE` rates (calculated on Basic Salary).
  - Every component includes mandatory type (`EARNING` or `DEDUCTION`), calculation type, amount/rate, and optional audit `description` (`VARCHAR(255)`).
  - Client-side and server-side limit of 30 components enforced.
  - Total deductions are validated not to exceed gross salary on structure submission.

---

### C. Attendance Integration & Loss of Pay (LOP)
- [x] **C.1 Weekly Offs & Working Calendar**:
  - Monthly working days exclude standard weekly offs (Sundays), configured via `payroll-rules.properties` (`weekly.off=SUNDAY`).
- [x] **C.2 Loss of Pay (LOP) Computation**:
  - Daily rate calculated as `baseSalary / totalWorkingDays` (rounded to 4 decimal places before day multiplication).
  - `unpaidDays = (workingDays - presentDays - paidLeaveDays)`.
  - Zero unpaid days results in `₹0.00` LOP.
  - Half-day absences (0.5 day increments) calculate accurately with `BigDecimal`.
- [x] **C.3 Configurable LOP Basis**:
  - Supports calculating LOP on `BASIC` salary or `GROSS` salary based on `lop.basis` in `payroll-rules.properties`.
- [x] **C.4 Attendance Discrepancy Auditing**:
  - Flags records where unmarked calendar days or approved leave discrepancies exist with a visual warning badge.

---

### D. Payroll Processing & Status Workflow
- [x] **D.1 Two-Phase Review-Before-Finalize Workflow**:
  - Batch generation (`action=generate_all`) creates `DRAFT` records for review.
  - Finalization is an explicit administrative action: single (`action=finalize_single`) or batch (`action=finalize_all`).
- [x] **D.2 Allowed Status Transitions**:
  - `DRAFT -> PROCESSED` (Finalization snapshot)
  - `PROCESSED -> PAID` (Payment settlement recorded)
  - `DRAFT -> CANCELLED` (Administrative cancellation with audit reason)
  - `PROCESSED -> CANCELLED` (Administrative cancellation with audit reason)
  - All other transitions blocked with error message.
- [x] **D.3 Terminal Status Immutability**:
  - `PAID` records are strictly terminal: cannot be cancelled, modified, or overwritten.
  - `CANCELLED` records cannot be transitioned directly (period can be re-generated into a new DRAFT).
- [x] **D.4 Snapshot Invariant**:
  - Once a payroll is `PROCESSED`, recalculation or structure changes do not alter its figures.
- [x] **D.5 Negative Net Salary Audit**:
  - When total deductions exceed gross salary, net salary is preserved as a negative figure rather than clamped to zero, ensuring audit visibility.
- [x] **D.6 Concurrency Protection**:
  - `PayrollDAO.save()` and `PayrollPaymentDAO.recordPayment()` utilize `SELECT ... FOR UPDATE` row locks to prevent race conditions during simultaneous batch runs.

---

### E. Payment Settlement
- [x] **E.1 Pre-Conditions**:
  - Payment can only be recorded for records in `PROCESSED` status.
  - Attempting to record payment on `DRAFT`, `PAID`, or `CANCELLED` records is rejected.
- [x] **E.2 Payment Amount Validation**:
  - `amount_paid` must equal `net_salary` exactly.
- [x] **E.3 Reference & Method**:
  - Method validated against whitelist: `Bank Transfer`, `Cheque`, `UPI`, `Cash`.
  - Reference number (UTR / Transaction ID / Cheque #) is mandatory.
  - UI displays accurate terminology ("Payment recorded" rather than claiming automatic bank dispatch).

---

### F. Security & Access Control
- [x] **F.1 Role Authorization**:
  - HR Administrators (`user.isHr()`): Full access to salary structures, batch processing, payment settlement, company reports, and CSV exports.
  - Non-HR Employees / Managers: Access restricted strictly to viewing their own finalized (`PROCESSED` or `PAID`) salary slips.
- [x] **F.2 ID Enumeration & 404 Masking**:
  - If a non-HR user attempts to view another employee's slip or any `DRAFT`/`CANCELLED` record, the system returns `HTTP 404 Not Found` (rather than 403 Forbidden) to prevent identifier scanning.
- [x] **F.3 CSRF Protection**:
  - Every state-changing form includes `<input type="hidden" name="csrfToken" value="...">` verified using constant-time comparison (`MessageDigest.isEqual`).
- [x] **F.4 XSS Prevention**:
  - All dynamic and database-sourced strings in JSP views are escaped via `HtmlUtil.esc(...)`.
- [x] **F.5 Secure Session Cookies**:
  - `<cookie-config><http-only>true</http-only></cookie-config>` configured in `web.xml`.
- [x] **F.6 Error Masking & Audit Logging**:
  - Exceptions log detailed stack traces server-side via `java.util.logging.Logger` with correlation IDs; user-facing pages display safe, non-sensitive messages without SQL text or salary amounts in logs.

---

### G. Reports, Exports & Presentation
- [x] **G.1 Currency & Localization**:
  - Indian Rupee symbol (`₹`) and `en-IN` decimal formatting (`String.format("%,.2f", ...)`) applied across all views.
- [x] **G.2 Net Salary in Words**:
  - Salary slip includes full Indian currency conversion in words (Lakhs, Crores, Thousands, Hundreds, Paise).
- [x] **G.3 Dynamic Department Filtering**:
  - History view dynamically loads active departments from the database.
- [x] **G.4 Department-Wise Summary**:
  - HR summary table aggregates headcount, gross earnings, total deductions, and net payout per department.
- [x] **G.5 CSV Export**:
  - Direct streaming CSV export (`/payroll/history?export=csv`) with escaped RFC 4180 commas/quotes.
- [x] **G.6 Print Ready Payslip**:
  - `@media print` CSS formats printable pay slip with header, metadata, itemized earnings/deductions, and signature blocks.
