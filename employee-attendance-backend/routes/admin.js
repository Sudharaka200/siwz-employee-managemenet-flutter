const express = require("express")
const router = express.Router()
const adminController = require("../controllers/adminController")
const { authenticateToken, requireRole } = require("../middleware/auth")

// All routes require authentication and admin/hr role
router.use(authenticateToken)
router.use(requireRole(["admin", "hr"]))

// Dashboard
router.get("/dashboard/stats", adminController.getDashboardStats)

// Employee management
router.get("/employees", adminController.getAllEmployees)
router.post("/employees", adminController.addEmployee)
router.put("/employees/:id", adminController.updateEmployee)
router.delete("/employees/:id", adminController.deleteEmployee)
router.get("/employees/:id", adminController.getEmployeeDetails)
router.put("/employees/:id/assign-shift", adminController.assignShiftToEmployee) // New route for assigning shifts

// Attendance management
router.get("/attendance", adminController.getAllAttendance)
router.put("/attendance/:id/status", adminController.updateAttendanceStatus)

module.exports = router
