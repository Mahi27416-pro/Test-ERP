-- ============================================================
--  COLLEGE ERP — Complete SQL Schema + Seed Data
--  Compatible with: MySQL 8.0+ / MariaDB 10.5+
--  Run: mysql -u root -p < college-erp.sql
-- ============================================================

CREATE DATABASE IF NOT EXISTS college_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE college_erp;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS fees;
DROP TABLE IF EXISTS grades;
DROP TABLE IF EXISTS attendance;
DROP TABLE IF EXISTS timetable;
DROP TABLE IF EXISTS subjects;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS faculty;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS departments;
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
--  TABLE: departments
-- ============================================================
CREATE TABLE departments (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  code        VARCHAR(10)  NOT NULL UNIQUE,
  name        VARCHAR(100) NOT NULL,
  hod_name    VARCHAR(100),
  created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================
--  TABLE: users
-- ============================================================
CREATE TABLE users (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(100) NOT NULL,
  email        VARCHAR(150) NOT NULL UNIQUE,
  password     VARCHAR(255) NOT NULL,          -- store bcrypt hash
  role         ENUM('admin','faculty','student') NOT NULL,
  dept_code    VARCHAR(10),
  is_active    BOOLEAN DEFAULT TRUE,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (dept_code) REFERENCES departments(code) ON DELETE SET NULL
);

-- ============================================================
--  TABLE: students
-- ============================================================
CREATE TABLE students (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNIQUE,
  roll_no      VARCHAR(20) NOT NULL UNIQUE,
  name         VARCHAR(100) NOT NULL,
  email        VARCHAR(150) NOT NULL UNIQUE,
  phone        VARCHAR(15),
  dept_code    VARCHAR(10) NOT NULL,
  semester     TINYINT NOT NULL CHECK (semester BETWEEN 1 AND 8),
  dob          DATE,
  address      TEXT,
  fee_status   ENUM('paid','pending','overdue') DEFAULT 'pending',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)   REFERENCES users(id)        ON DELETE SET NULL,
  FOREIGN KEY (dept_code) REFERENCES departments(code) ON DELETE RESTRICT
);

-- ============================================================
--  TABLE: faculty
-- ============================================================
CREATE TABLE faculty (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  user_id      INT UNIQUE,
  faculty_id   VARCHAR(20) NOT NULL UNIQUE,
  name         VARCHAR(100) NOT NULL,
  email        VARCHAR(150) NOT NULL UNIQUE,
  phone        VARCHAR(15),
  dept_code    VARCHAR(10) NOT NULL,
  designation  VARCHAR(100) DEFAULT 'Assistant Professor',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id)   REFERENCES users(id)        ON DELETE SET NULL,
  FOREIGN KEY (dept_code) REFERENCES departments(code) ON DELETE RESTRICT
);

-- ============================================================
--  TABLE: subjects
-- ============================================================
CREATE TABLE subjects (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  code         VARCHAR(20) NOT NULL UNIQUE,
  name         VARCHAR(100) NOT NULL,
  dept_code    VARCHAR(10) NOT NULL,
  semester     TINYINT NOT NULL,
  credits      TINYINT DEFAULT 3,
  faculty_id   INT,
  FOREIGN KEY (dept_code)  REFERENCES departments(code) ON DELETE RESTRICT,
  FOREIGN KEY (faculty_id) REFERENCES faculty(id)       ON DELETE SET NULL
);

-- ============================================================
--  TABLE: timetable
-- ============================================================
CREATE TABLE timetable (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  dept_code    VARCHAR(10) NOT NULL,
  semester     TINYINT NOT NULL,
  day          ENUM('Mon','Tue','Wed','Thu','Fri','Sat') NOT NULL,
  time_slot    VARCHAR(20) NOT NULL,
  subject_code VARCHAR(20) NOT NULL,
  room         VARCHAR(20),
  faculty_id   INT,
  FOREIGN KEY (dept_code)    REFERENCES departments(code) ON DELETE CASCADE,
  FOREIGN KEY (subject_code) REFERENCES subjects(code)    ON DELETE CASCADE,
  FOREIGN KEY (faculty_id)   REFERENCES faculty(id)       ON DELETE SET NULL
);

-- ============================================================
--  TABLE: attendance
-- ============================================================
CREATE TABLE attendance (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  student_id   INT NOT NULL,
  subject_code VARCHAR(20) NOT NULL,
  date         DATE NOT NULL,
  status       ENUM('P','A','L') NOT NULL DEFAULT 'P',
  marked_by    INT,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_attendance (student_id, subject_code, date),
  FOREIGN KEY (student_id)   REFERENCES students(id) ON DELETE CASCADE,
  FOREIGN KEY (subject_code) REFERENCES subjects(code) ON DELETE CASCADE,
  FOREIGN KEY (marked_by)    REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================
--  TABLE: grades
-- ============================================================
CREATE TABLE grades (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  student_id   INT NOT NULL,
  subject_code VARCHAR(20) NOT NULL,
  semester     TINYINT NOT NULL,
  exam_type    ENUM('mid-sem','end-sem','internal') DEFAULT 'mid-sem',
  marks        DECIMAL(5,2) NOT NULL CHECK (marks >= 0 AND marks <= 100),
  max_marks    DECIMAL(5,2) NOT NULL DEFAULT 100,
  grade        CHAR(1) AS (
    CASE
      WHEN (marks / max_marks * 100) >= 85 THEN 'A'
      WHEN (marks / max_marks * 100) >= 70 THEN 'B'
      WHEN (marks / max_marks * 100) >= 55 THEN 'C'
      WHEN (marks / max_marks * 100) >= 40 THEN 'D'
      ELSE 'F'
    END
  ) STORED,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_grade (student_id, subject_code, semester, exam_type),
  FOREIGN KEY (student_id)   REFERENCES students(id)  ON DELETE CASCADE,
  FOREIGN KEY (subject_code) REFERENCES subjects(code) ON DELETE CASCADE
);

-- ============================================================
--  TABLE: fees
-- ============================================================
CREATE TABLE fees (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  student_id   INT NOT NULL,
  semester     TINYINT NOT NULL,
  description  VARCHAR(200) DEFAULT 'Tuition fee',
  amount       DECIMAL(10,2) NOT NULL,
  due_date     DATE NOT NULL,
  paid_date    DATE,
  status       ENUM('paid','pending','overdue') DEFAULT 'pending',
  receipt_no   VARCHAR(50) UNIQUE,
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);

-- ============================================================
--  SEED: departments
-- ============================================================
INSERT INTO departments (code, name, hod_name) VALUES
  ('CS',  'Computer Science & Engineering', 'Dr. Ramesh Patel'),
  ('EC',  'Electronics & Communication',    'Dr. Sunita Rao'),
  ('ME',  'Mechanical Engineering',         'Dr. Anil Sharma'),
  ('CE',  'Civil Engineering',              'Dr. Kavitha Nair'),
  ('MBA', 'Master of Business Administration', 'Prof. Vijay Kumar');

-- ============================================================
--  SEED: users  (passwords are placeholder hashes — regenerate with bcrypt)
-- ============================================================
INSERT INTO users (name, email, password, role, dept_code) VALUES
  ('Anil Kumar',      'admin@college.edu',    '$2a$10$placeholder_hash_admin',   'admin',   NULL),
  ('Dr. Ramesh Patel','ramesh@college.edu',   '$2a$10$placeholder_hash_fac1',    'faculty', 'CS'),
  ('Prof. Sunita Rao','sunita@college.edu',   '$2a$10$placeholder_hash_fac2',    'faculty', 'CS'),
  ('Dr. Anil Sharma', 'anil@college.edu',     '$2a$10$placeholder_hash_fac3',    'faculty', 'EC'),
  ('Prof. Meena Joshi','meena@college.edu',   '$2a$10$placeholder_hash_fac4',    'faculty', 'ME'),
  ('Dr. Vijay Kumar', 'vijay@college.edu',    '$2a$10$placeholder_hash_fac5',    'faculty', 'MBA'),
  ('Ananya Patel',    'ananya@college.edu',   '$2a$10$placeholder_hash_stu1',    'student', 'CS'),
  ('Rahul Mehta',     'rahul@college.edu',    '$2a$10$placeholder_hash_stu2',    'student', 'CS'),
  ('Divya Sharma',    'divya@college.edu',    '$2a$10$placeholder_hash_stu3',    'student', 'CS'),
  ('Karan Shah',      'karan@college.edu',    '$2a$10$placeholder_hash_stu4',    'student', 'CS'),
  ('Pooja Rao',       'pooja@college.edu',    '$2a$10$placeholder_hash_stu5',    'student', 'CS'),
  ('Rohan Verma',     'rohan@college.edu',    '$2a$10$placeholder_hash_stu6',    'student', 'EC'),
  ('Priya Shah',      'priya@college.edu',    '$2a$10$placeholder_hash_stu7',    'student', 'EC'),
  ('Nisha Nair',      'nisha@college.edu',    '$2a$10$placeholder_hash_stu8',    'student', 'EC'),
  ('Amit Gupta',      'amit@college.edu',     '$2a$10$placeholder_hash_stu9',    'student', 'EC'),
  ('Arjun Nair',      'arjun@college.edu',    '$2a$10$placeholder_hash_stu10',   'student', 'ME'),
  ('Sunita Joshi',    'sunitaj@college.edu',  '$2a$10$placeholder_hash_stu11',   'student', 'ME'),
  ('Deepak Kumar',    'deepak@college.edu',   '$2a$10$placeholder_hash_stu12',   'student', 'ME'),
  ('Sneha Joshi',     'sneha@college.edu',    '$2a$10$placeholder_hash_stu13',   'student', 'MBA'),
  ('Meera Iyer',      'meera@college.edu',    '$2a$10$placeholder_hash_stu14',   'student', 'MBA'),
  ('Vijay Patel',     'vijayp@college.edu',   '$2a$10$placeholder_hash_stu15',   'student', 'MBA');

-- ============================================================
--  SEED: faculty
-- ============================================================
INSERT INTO faculty (user_id, faculty_id, name, email, dept_code, designation) VALUES
  (2,  'FAC-CS-001', 'Dr. Ramesh Patel',  'ramesh@college.edu', 'CS',  'Professor'),
  (3,  'FAC-CS-002', 'Prof. Sunita Rao',  'sunita@college.edu', 'CS',  'Associate Professor'),
  (4,  'FAC-EC-001', 'Dr. Anil Sharma',   'anil@college.edu',   'EC',  'Professor'),
  (5,  'FAC-ME-001', 'Prof. Meena Joshi', 'meena@college.edu',  'ME',  'Assistant Professor'),
  (6,  'FAC-MBA-001','Dr. Vijay Kumar',   'vijay@college.edu',  'MBA', 'Professor');

-- ============================================================
--  SEED: students
-- ============================================================
INSERT INTO students (user_id, roll_no, name, email, phone, dept_code, semester, fee_status) VALUES
  (7,  'STU-0041', 'Ananya Patel',  'ananya@college.edu',  '9876543210', 'CS',  4, 'paid'),
  (8,  'STU-0042', 'Rahul Mehta',   'rahul@college.edu',   '9876543211', 'CS',  4, 'paid'),
  (9,  'STU-0043', 'Divya Sharma',  'divya@college.edu',   '9876543212', 'CS',  2, 'pending'),
  (10, 'STU-0044', 'Karan Shah',    'karan@college.edu',   '9876543213', 'CS',  2, 'paid'),
  (11, 'STU-0045', 'Pooja Rao',     'pooja@college.edu',   '9876543214', 'CS',  4, 'paid'),
  (12, 'STU-0061', 'Rohan Verma',   'rohan@college.edu',   '9876543215', 'EC',  4, 'paid'),
  (13, 'STU-0062', 'Priya Shah',    'priya@college.edu',   '9876543216', 'EC',  2, 'pending'),
  (14, 'STU-0063', 'Nisha Nair',    'nisha@college.edu',   '9876543217', 'EC',  2, 'paid'),
  (15, 'STU-0064', 'Amit Gupta',    'amit@college.edu',    '9876543218', 'EC',  4, 'paid'),
  (16, 'STU-0081', 'Arjun Nair',    'arjun@college.edu',   '9876543219', 'ME',  4, 'overdue'),
  (17, 'STU-0082', 'Sunita Joshi',  'sunitaj@college.edu', '9876543220', 'ME',  2, 'paid'),
  (18, 'STU-0083', 'Deepak Kumar',  'deepak@college.edu',  '9876543221', 'ME',  2, 'overdue'),
  (19, 'STU-0101', 'Sneha Joshi',   'sneha@college.edu',   '9876543222', 'MBA', 2, 'paid'),
  (20, 'STU-0102', 'Meera Iyer',    'meera@college.edu',   '9876543223', 'MBA', 2, 'paid'),
  (21, 'STU-0103', 'Vijay Patel',   'vijayp@college.edu',  '9876543224', 'MBA', 4, 'pending');

-- ============================================================
--  SEED: subjects
-- ============================================================
INSERT INTO subjects (code, name, dept_code, semester, credits, faculty_id) VALUES
  ('CS401', 'Database Management Systems', 'CS',  4, 4, 1),
  ('CS402', 'Operating Systems',           'CS',  4, 4, 1),
  ('CS403', 'Computer Networks',           'CS',  4, 3, 2),
  ('CS404', 'Software Engineering',        'CS',  4, 3, 2),
  ('MA401', 'Engineering Mathematics IV',  'CS',  4, 4, NULL),
  ('CS201', 'Data Structures',             'CS',  2, 4, 1),
  ('CS202', 'Digital Electronics',         'CS',  2, 3, 2),
  ('EC401', 'Signals & Systems',           'EC',  4, 4, 3),
  ('EC402', 'Microprocessors',             'EC',  4, 3, 3),
  ('ME401', 'Thermodynamics',              'ME',  4, 4, 4),
  ('ME402', 'Fluid Mechanics',             'ME',  4, 3, 4),
  ('MBA201','Management Principles',       'MBA', 2, 4, 5),
  ('MBA202','Human Resource Management',   'MBA', 2, 3, 5);

-- ============================================================
--  SEED: timetable (CS Sem 4)
-- ============================================================
INSERT INTO timetable (dept_code, semester, day, time_slot, subject_code, room, faculty_id) VALUES
  ('CS', 4, 'Mon', '09:00-10:00', 'CS401', 'Lab 3',  1),
  ('CS', 4, 'Mon', '11:00-12:00', 'CS402', 'R-201',  1),
  ('CS', 4, 'Tue', '09:00-10:00', 'MA401', 'R-105',  NULL),
  ('CS', 4, 'Tue', '14:00-15:00', 'CS403', 'R-202',  2),
  ('CS', 4, 'Wed', '10:00-11:00', 'CS404', 'R-201',  2),
  ('CS', 4, 'Wed', '15:00-16:00', 'MA401', 'R-105',  NULL),
  ('CS', 4, 'Thu', '09:00-10:00', 'CS401', 'Lab 3',  1),
  ('CS', 4, 'Thu', '11:00-12:00', 'CS404', 'R-202',  2),
  ('CS', 4, 'Fri', '10:00-11:00', 'MA401', 'R-105',  NULL),
  ('CS', 4, 'Fri', '14:00-15:00', 'CS403', 'R-202',  2);

-- ============================================================
--  SEED: attendance (sample — last 5 days)
-- ============================================================
INSERT INTO attendance (student_id, subject_code, date, status, marked_by) VALUES
  -- Ananya Patel (id=1) — CS401
  (1, 'CS401', CURDATE() - INTERVAL 4 DAY, 'P', 1),
  (1, 'CS401', CURDATE() - INTERVAL 3 DAY, 'P', 1),
  (1, 'CS401', CURDATE() - INTERVAL 2 DAY, 'P', 1),
  (1, 'CS401', CURDATE() - INTERVAL 1 DAY, 'P', 1),
  (1, 'CS401', CURDATE(),                  'P', 1),
  -- Rahul Mehta (id=2)
  (2, 'CS401', CURDATE() - INTERVAL 4 DAY, 'P', 1),
  (2, 'CS401', CURDATE() - INTERVAL 3 DAY, 'A', 1),
  (2, 'CS401', CURDATE() - INTERVAL 2 DAY, 'P', 1),
  (2, 'CS401', CURDATE() - INTERVAL 1 DAY, 'P', 1),
  (2, 'CS401', CURDATE(),                  'P', 1),
  -- Divya Sharma (id=3)
  (3, 'CS401', CURDATE() - INTERVAL 4 DAY, 'A', 1),
  (3, 'CS401', CURDATE() - INTERVAL 3 DAY, 'A', 1),
  (3, 'CS401', CURDATE() - INTERVAL 2 DAY, 'P', 1),
  (3, 'CS401', CURDATE() - INTERVAL 1 DAY, 'L', 1),
  (3, 'CS401', CURDATE(),                  'A', 1),
  -- Priya Shah (id=7) EC
  (7, 'EC401', CURDATE() - INTERVAL 4 DAY, 'A', 1),
  (7, 'EC401', CURDATE() - INTERVAL 3 DAY, 'A', 1),
  (7, 'EC401', CURDATE() - INTERVAL 2 DAY, 'A', 1),
  (7, 'EC401', CURDATE() - INTERVAL 1 DAY, 'P', 1),
  (7, 'EC401', CURDATE(),                  'A', 1);

-- ============================================================
--  SEED: grades (mid-sem)
-- ============================================================
INSERT INTO grades (student_id, subject_code, semester, exam_type, marks, max_marks) VALUES
  -- Ananya Patel
  (1, 'CS401', 4, 'mid-sem', 92, 100),
  (1, 'CS402', 4, 'mid-sem', 89, 100),
  (1, 'MA401', 4, 'mid-sem', 95, 100),
  (1, 'CS404', 4, 'mid-sem', 90, 100),
  -- Rahul Mehta
  (2, 'CS401', 4, 'mid-sem', 78, 100),
  (2, 'CS402', 4, 'mid-sem', 82, 100),
  (2, 'MA401', 4, 'mid-sem', 74, 100),
  (2, 'CS404', 4, 'mid-sem', 80, 100),
  -- Divya Sharma
  (3, 'CS201', 2, 'mid-sem', 65, 100),
  (3, 'CS202', 2, 'mid-sem', 58, 100),
  -- Rohan Verma
  (6, 'EC401', 4, 'mid-sem', 72, 100),
  (6, 'EC402', 4, 'mid-sem', 68, 100),
  -- Priya Shah
  (7, 'EC401', 2, 'mid-sem', 55, 100),
  (7, 'EC402', 2, 'mid-sem', 48, 100),
  -- Arjun Nair
  (10,'ME401', 4, 'mid-sem', 69, 100),
  (10,'ME402', 4, 'mid-sem', 74, 100),
  -- Sunita Joshi
  (11,'ME401', 2, 'mid-sem', 90, 100),
  (11,'ME402', 2, 'mid-sem', 86, 100),
  -- Sneha Joshi
  (13,'MBA201',2, 'mid-sem', 94, 100),
  (13,'MBA202',2, 'mid-sem', 88, 100),
  -- Meera Iyer
  (14,'MBA201',2, 'mid-sem', 82, 100),
  (14,'MBA202',2, 'mid-sem', 85, 100);

-- ============================================================
--  SEED: fees
-- ============================================================
INSERT INTO fees (student_id, semester, description, amount, due_date, paid_date, status, receipt_no) VALUES
  (1,  2, 'Tuition fee', 45000, '2026-02-01', '2026-01-28', 'paid',    'RCP-20260128-001'),
  (2,  2, 'Tuition fee', 45000, '2026-02-01', '2026-01-30', 'paid',    'RCP-20260130-002'),
  (3,  2, 'Tuition fee', 45000, '2026-02-01', NULL,         'pending', NULL),
  (4,  2, 'Tuition fee', 45000, '2026-02-01', '2026-02-01', 'paid',    'RCP-20260201-003'),
  (5,  2, 'Tuition fee', 45000, '2026-02-01', '2026-01-25', 'paid',    'RCP-20260125-004'),
  (6,  2, 'Tuition fee', 45000, '2026-02-01', '2026-01-20', 'paid',    'RCP-20260120-005'),
  (7,  2, 'Tuition fee', 45000, '2026-02-01', NULL,         'pending', NULL),
  (8,  2, 'Tuition fee', 45000, '2026-02-01', '2026-02-05', 'paid',    'RCP-20260205-006'),
  (9,  2, 'Tuition fee', 45000, '2026-02-01', '2026-01-29', 'paid',    'RCP-20260129-007'),
  (10, 2, 'Tuition fee', 42000, '2026-01-15', NULL,         'overdue', NULL),
  (11, 2, 'Tuition fee', 42000, '2026-02-01', '2026-01-31', 'paid',    'RCP-20260131-008'),
  (12, 2, 'Tuition fee', 42000, '2026-01-15', NULL,         'overdue', NULL),
  (13, 2, 'Tuition fee', 60000, '2026-02-01', '2026-01-28', 'paid',    'RCP-20260128-009'),
  (14, 2, 'Tuition fee', 60000, '2026-02-01', '2026-01-30', 'paid',    'RCP-20260130-010'),
  (15, 2, 'Tuition fee', 60000, '2026-03-01', NULL,         'pending', NULL);

-- ============================================================
--  USEFUL VIEWS
-- ============================================================

-- Student attendance percentage per subject
CREATE OR REPLACE VIEW vw_attendance_summary AS
SELECT
  s.roll_no,
  s.name             AS student_name,
  s.dept_code,
  a.subject_code,
  COUNT(*)           AS total_classes,
  SUM(a.status = 'P') AS present,
  SUM(a.status = 'A') AS absent,
  SUM(a.status = 'L') AS on_leave,
  ROUND(SUM(a.status = 'P') / COUNT(*) * 100, 1) AS attendance_pct
FROM attendance a
JOIN students s ON s.id = a.student_id
GROUP BY s.id, a.subject_code;

-- Student grade summary per semester
CREATE OR REPLACE VIEW vw_grade_summary AS
SELECT
  s.roll_no,
  s.name             AS student_name,
  s.dept_code,
  g.semester,
  g.exam_type,
  g.subject_code,
  g.marks,
  g.max_marks,
  g.grade,
  ROUND(g.marks / g.max_marks * 100, 1) AS percentage
FROM grades g
JOIN students s ON s.id = g.student_id;

-- Department-wise attendance overview
CREATE OR REPLACE VIEW vw_dept_attendance AS
SELECT
  s.dept_code,
  COUNT(DISTINCT s.id)                             AS total_students,
  ROUND(AVG(a.status = 'P') * 100, 1)             AS avg_attendance_pct
FROM attendance a
JOIN students s ON s.id = a.student_id
WHERE a.date = CURDATE()
GROUP BY s.dept_code;

-- Fee collection summary
CREATE OR REPLACE VIEW vw_fee_summary AS
SELECT
  SUM(amount)                                          AS total_fees,
  SUM(CASE WHEN status = 'paid'    THEN amount ELSE 0 END) AS collected,
  SUM(CASE WHEN status = 'pending' THEN amount ELSE 0 END) AS pending,
  SUM(CASE WHEN status = 'overdue' THEN amount ELSE 0 END) AS overdue,
  COUNT(CASE WHEN status = 'paid'    THEN 1 END)           AS paid_count,
  COUNT(CASE WHEN status = 'pending' THEN 1 END)           AS pending_count,
  COUNT(CASE WHEN status = 'overdue' THEN 1 END)           AS overdue_count
FROM fees;

-- ============================================================
--  USEFUL QUERIES (reference)
-- ============================================================

-- Get all students with attendance % today:
-- SELECT * FROM vw_attendance_summary WHERE subject_code = 'CS401';

-- Get grade sheet for a department:
-- SELECT * FROM vw_grade_summary WHERE dept_code = 'CS' AND semester = 4 AND exam_type = 'mid-sem';

-- Get overdue fee students:
-- SELECT s.name, s.roll_no, s.dept_code, f.amount, f.due_date
-- FROM fees f JOIN students s ON s.id = f.student_id
-- WHERE f.status = 'overdue';

-- Get timetable for CS Sem 4:
-- SELECT t.day, t.time_slot, sub.name AS subject, t.room, f.name AS faculty
-- FROM timetable t
-- JOIN subjects sub ON sub.code = t.subject_code
-- LEFT JOIN faculty f ON f.id = t.faculty_id
-- WHERE t.dept_code = 'CS' AND t.semester = 4
-- ORDER BY FIELD(t.day,'Mon','Tue','Wed','Thu','Fri'), t.time_slot;
