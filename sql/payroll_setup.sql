-- ========================================================================
-- SmartOffice Project — Module 11: Payroll Management Database Setup Script
-- Database: employee_db (MySQL 8.0+)
-- Plain idempotent schema initialization script (compatible with any client).
-- ========================================================================

USE employee_db;

-- ------------------------------------------------------------------------
-- Table 1: salary_structures
-- Stores employee salary structures with effective date versioning.
-- Foreign key ensures referential integrity against employees.
-- ------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS salary_structures (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(20) NOT NULL,
    basic_salary DECIMAL(12,2) NOT NULL CHECK (basic_salary > 0),
    effective_from DATE NOT NULL,
    effective_to DATE NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_effective_dates CHECK (effective_to IS NULL OR effective_to >= effective_from),
    CONSTRAINT fk_ss_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE,
    INDEX idx_ss_emp_eff (employee_id, effective_from)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------
-- Table 2: salary_components
-- Stores configurable allowances and deductions linked to salary structures.
-- ------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS salary_components (
    id INT AUTO_INCREMENT PRIMARY KEY,
    salary_structure_id INT NOT NULL,
    component_name VARCHAR(100) NOT NULL,
    component_type VARCHAR(20) NOT NULL CHECK (component_type IN ('EARNING','DEDUCTION')),
    calculation_type VARCHAR(20) NOT NULL CHECK (calculation_type IN ('FIXED','PERCENTAGE')),
    amount DECIMAL(12,2) NOT NULL CHECK (amount >= 0),
    description VARCHAR(255) NULL,
    FOREIGN KEY (salary_structure_id) REFERENCES salary_structures(id) ON DELETE CASCADE,
    UNIQUE KEY uq_struct_comp (salary_structure_id, component_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------
-- Table 3: payroll
-- Stores monthly calculated payroll records per employee.
--
-- RATIONALE for processed_by / cancelled_by (VARCHAR(50) NULL without FK):
-- 1. Audits the authenticated system username (e.g. 'admin', 'hr1') who initiated
--    or cancelled the calculation run.
-- 2. System administrators and HR operators may authenticate via 'users' or
--    'managers' accounts rather than 'employees'.
-- 3. Decoupling the audit username from an employee FK ensures that administrative
--    employee deactivations or terminations never violate historic payroll audit logs.
-- ------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payroll (
    id INT AUTO_INCREMENT PRIMARY KEY,
    employee_id VARCHAR(20) NOT NULL,
    payroll_month TINYINT NOT NULL CHECK (payroll_month BETWEEN 1 AND 12),
    payroll_year SMALLINT NOT NULL,
    basic_salary DECIMAL(12,2) NOT NULL,
    gross_salary DECIMAL(12,2) NOT NULL,
    total_deductions DECIMAL(12,2) NOT NULL,
    net_salary DECIMAL(12,2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT','PROCESSED','PAID','CANCELLED')),
    processed_by VARCHAR(50) NULL,
    processed_at TIMESTAMP NULL,
    total_working_days INT NOT NULL DEFAULT 30,
    present_days DECIMAL(5,1) NOT NULL DEFAULT 0.0,
    paid_leave_days DECIMAL(5,1) NOT NULL DEFAULT 0.0,
    unpaid_days DECIMAL(5,1) NOT NULL DEFAULT 0.0,
    loss_of_pay DECIMAL(12,2) NOT NULL DEFAULT 0.00,
    remarks VARCHAR(500) NULL,
    cancelled_by VARCHAR(50) NULL,
    cancelled_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payroll_employee FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE RESTRICT,
    UNIQUE KEY uq_emp_period (employee_id, payroll_month, payroll_year),
    INDEX idx_payroll_period (payroll_year, payroll_month),
    INDEX idx_payroll_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------
-- Table 4: payroll_items
-- Immutable line-item snapshot of all earnings & deductions at calculation time.
-- ------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payroll_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payroll_id INT NOT NULL,
    component_name VARCHAR(100) NOT NULL,
    component_type VARCHAR(20) NOT NULL,
    amount DECIMAL(12,2) NOT NULL,
    FOREIGN KEY (payroll_id) REFERENCES payroll(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------
-- Table 5: payroll_payments
-- Audit settlement record for disbursed payroll.
-- ------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payroll_payments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    payroll_id INT NOT NULL UNIQUE,
    payment_date DATE NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    reference_number VARCHAR(100) NULL,
    amount_paid DECIMAL(12,2) NOT NULL CHECK (amount_paid > 0),
    notes VARCHAR(255) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (payroll_id) REFERENCES payroll(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
