-- reports_setup.sql
-- Database integration script for Employee Management System Reports (Day 1 & Day 2)
-- Database: employee_db

USE employee_db;

-- 1. Seed sample leave_requests
INSERT INTO leave_requests (id, employee_id, leave_type, from_date, to_date, reason, status, decided_by, decided_at, decision_reason)
VALUES
(1, 'EMP101', 'CASUAL', '2026-10-16', '2026-10-16', 'Personal family event', 'APPROVED', 'admin', '2026-10-15 10:00:00', 'Approved by HR'),
(2, 'EMP102', 'SICK', '2026-10-17', '2026-10-18', 'Viral fever and doctor consultation', 'APPROVED', 'admin', '2026-10-16 11:30:00', 'Approved on medical grounds'),
(3, 'EMP103', 'VACATION', '2026-10-22', '2026-10-24', 'Annual family vacation trip', 'PENDING', NULL, NULL, NULL),
(4, 'EMP104', 'CASUAL', '2026-10-20', '2026-10-20', 'Urgent home maintenance work', 'REJECTED', 'admin', '2026-10-19 14:00:00', 'Critical project release milestone on that day'),
(5, 'EMP107', 'SICK', '2026-10-21', '2026-10-22', 'Dental surgery recovery', 'PENDING', NULL, NULL, NULL)
ON DUPLICATE KEY UPDATE reason=VALUES(reason);

-- 2. Seed sample attendance records
INSERT INTO attendance (id, employee_id, attendance_date, check_in_time, check_out_time, status, leave_type, reason, worked_minutes, auto_checkout)
VALUES
(101, 'EMP101', '2026-10-16', NULL, NULL, 'LEAVE', 'CASUAL', 'Approved casual leave', 0, 0),
(102, 'EMP102', '2026-10-16', '09:05:00', '18:15:00', 'PRESENT', NULL, NULL, 520, 0),
(103, 'EMP103', '2026-10-16', '09:12:00', '18:00:00', 'PRESENT', NULL, NULL, 508, 0),
(104, 'EMP104', '2026-10-16', '09:45:00', '13:30:00', 'HALF_DAY', NULL, NULL, 225, 0),
(105, 'EMP105', '2026-10-16', '08:55:00', '17:30:00', 'PRESENT', NULL, NULL, 515, 0),
(106, 'EMP106', '2026-10-16', NULL, NULL, 'ABSENT', NULL, 'Unplanned absence', 0, 0),
(107, 'EMP101', '2026-10-17', '09:02:00', '18:10:00', 'PRESENT', NULL, NULL, 528, 0),
(108, 'EMP103', '2026-10-17', '09:15:00', '18:05:00', 'PRESENT', NULL, NULL, 510, 0),
(109, 'EMP104', '2026-10-17', '09:00:00', '17:45:00', 'PRESENT', NULL, NULL, 525, 0),
(110, 'EMP107', '2026-10-17', '10:05:00', '18:30:00', 'PRESENT', NULL, NULL, 485, 0),
(111, 'EMP108', '2026-10-17', NULL, NULL, 'ABSENT', NULL, 'Unplanned absence', 0, 0),
(112, 'EMP101', '2026-10-20', '09:00:00', '18:00:00', 'PRESENT', NULL, NULL, 540, 0),
(113, 'EMP102', '2026-10-20', '09:10:00', '18:15:00', 'PRESENT', NULL, NULL, 525, 0),
(114, 'EMP103', '2026-10-20', '09:20:00', '18:00:00', 'PRESENT', NULL, NULL, 500, 0),
(115, 'EMP105', '2026-10-20', '09:30:00', '13:45:00', 'HALF_DAY', NULL, NULL, 235, 0),
(116, 'EMP107', '2026-10-20', NULL, NULL, 'LEAVE', 'SICK', 'Sick leave application', 0, 0)
ON DUPLICATE KEY UPDATE status=VALUES(status);

-- 3. Add sample tasks for IN_PROGRESS, ON_HOLD, CANCELLED to cover all task report statuses
UPDATE tasks SET status='IN_PROGRESS' WHERE id IN (1, 2);
UPDATE tasks SET status='ON_HOLD' WHERE id IN (4);
UPDATE tasks SET status='CANCELLED' WHERE id IN (6);
