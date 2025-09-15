const express = require("express")
const router = express.Router()
const Attendance = require("../models/Attendance")
const User = require("../models/User")
const Leave = require("../models/Leave")
const { authenticateToken, requireRole } = require("../middleware/auth")
const moment = require("moment")

// All routes require authentication and admin/hr role
router.use(authenticateToken)
router.use(requireRole(["admin", "hr"]))

// Generate Attendance Report
router.get("/attendance", async (req, res) => {
  try {
    const { startDate, endDate, department, employeeId, format = "json" } = req.query

    const query = {}

    if (startDate && endDate) {
      query.date = { $gte: startDate, $lte: endDate }
    } else {
      // Default to current month
      const startOfMonth = moment().startOf("month").format("YYYY-MM-DD")
      const endOfMonth = moment().endOf("month").format("YYYY-MM-DD")
      query.date = { $gte: startOfMonth, $lte: endOfMonth }
    }

    if (employeeId) {
      query.employeeId = employeeId
    }

    // If department filter is applied
    if (department) {
      const employeesInDept = await User.find({ department, isActive: true }).select("employeeId")
      const employeeIds = employeesInDept.map((emp) => emp.employeeId)
      query.employeeId = { $in: employeeIds }
    }

    const attendanceRecords = await Attendance.find(query).sort({ date: -1 })

    // Calculate summary statistics
    const summary = {
      totalRecords: attendanceRecords.length,
      presentDays: attendanceRecords.filter((r) => r.status === "present").length,
      lateDays: attendanceRecords.filter((r) => r.status === "late").length,
      absentDays: attendanceRecords.filter((r) => r.status === "absent").length,
      totalWorkingHours: attendanceRecords.reduce((sum, r) => sum + (r.workingHours || 0), 0),
      totalOvertime: attendanceRecords.reduce((sum, r) => sum + (r.overtime || 0), 0),
    }

    if (format === "csv") {
      // Generate CSV format
      const csvHeader = "Employee ID,Employee Name,Date,Clock In,Clock Out,Working Hours,Overtime,Status\n"
      const csvData = attendanceRecords
        .map(
          (record) =>
            `${record.employeeId},${record.employeeName},${record.date},${record.clockIn?.time || ""},${record.clockOut?.time || ""},${record.workingHours || 0},${record.overtime || 0},${record.status}`,
        )
        .join("\n")

      res.setHeader("Content-Type", "text/csv")
      res.setHeader("Content-Disposition", "attachment; filename=attendance-report.csv")
      res.send(csvHeader + csvData)
    } else {
      res.json({
        success: true,
        summary,
        records: attendanceRecords,
      })
    }
  } catch (error) {
    console.error("Generate attendance report error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

// Generate Leave Report
router.get("/leave", async (req, res) => {
  try {
    const { startDate, endDate, department, leaveType, status, format = "json" } = req.query

    const query = {}

    if (startDate && endDate) {
      query.startDate = { $gte: new Date(startDate), $lte: new Date(endDate) }
    }

    if (leaveType) {
      query.leaveType = leaveType
    }

    if (status) {
      query.status = status
    }

    // If department filter is applied
    if (department) {
      const employeesInDept = await User.find({ department, isActive: true }).select("employeeId")
      const employeeIds = employeesInDept.map((emp) => emp.employeeId)
      query.employeeId = { $in: employeeIds }
    }

    const leaveRecords = await Leave.find(query).sort({ appliedAt: -1 })

    // Calculate summary statistics
    const summary = {
      totalRequests: leaveRecords.length,
      approvedRequests: leaveRecords.filter((r) => r.status === "approved").length,
      pendingRequests: leaveRecords.filter((r) => r.status === "pending").length,
      rejectedRequests: leaveRecords.filter((r) => r.status === "rejected").length,
      totalLeaveDays: leaveRecords.filter((r) => r.status === "approved").reduce((sum, r) => sum + r.totalDays, 0),
    }

    if (format === "csv") {
      // Generate CSV format
      const csvHeader =
        "Employee ID,Employee Name,Leave Type,Start Date,End Date,Total Days,Status,Applied At,Approved By\n"
      const csvData = leaveRecords
        .map(
          (record) =>
            `${record.employeeId},${record.employeeName},${record.leaveType},${moment(record.startDate).format("YYYY-MM-DD")},${moment(record.endDate).format("YYYY-MM-DD")},${record.totalDays},${record.status},${moment(record.appliedAt).format("YYYY-MM-DD")},${record.approvedBy?.name || ""}`,
        )
        .join("\n")

      res.setHeader("Content-Type", "text/csv")
      res.setHeader("Content-Disposition", "attachment; filename=leave-report.csv")
      res.send(csvHeader + csvData)
    } else {
      res.json({
        success: true,
        summary,
        records: leaveRecords,
      })
    }
  } catch (error) {
    console.error("Generate leave report error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

// Generate Employee Report
router.get("/employees", async (req, res) => {
  try {
    const { department, format = "json" } = req.query

    const query = { isActive: true }
    if (department) {
      query.department = department
    }

    const employees = await User.find(query).select("-password").sort({ name: 1 })

    // Get attendance summary for each employee (current month)
    const startOfMonth = moment().startOf("month").format("YYYY-MM-DD")
    const endOfMonth = moment().endOf("month").format("YYYY-MM-DD")

    const employeesWithStats = await Promise.all(
      employees.map(async (employee) => {
        const attendanceRecords = await Attendance.find({
          employeeId: employee.employeeId,
          date: { $gte: startOfMonth, $lte: endOfMonth },
        })

        const stats = {
          totalDays: attendanceRecords.length,
          presentDays: attendanceRecords.filter((r) => r.status === "present").length,
          lateDays: attendanceRecords.filter((r) => r.status === "late").length,
          totalWorkingHours: attendanceRecords.reduce((sum, r) => sum + (r.workingHours || 0), 0),
        }

        return {
          ...employee.toObject(),
          currentMonthStats: stats,
        }
      }),
    )

    if (format === "csv") {
      // Generate CSV format
      const csvHeader = "Employee ID,Name,Email,Department,Designation,Present Days,Late Days,Total Working Hours\n"
      const csvData = employeesWithStats
        .map(
          (emp) =>
            `${emp.employeeId},${emp.name},${emp.email},${emp.department},${emp.designation || ""},${emp.currentMonthStats.presentDays},${emp.currentMonthStats.lateDays},${emp.currentMonthStats.totalWorkingHours}`,
        )
        .join("\n")

      res.setHeader("Content-Type", "text/csv")
      res.setHeader("Content-Disposition", "attachment; filename=employee-report.csv")
      res.send(csvHeader + csvData)
    } else {
      res.json({
        success: true,
        employees: employeesWithStats,
      })
    }
  } catch (error) {
    console.error("Generate employee report error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

module.exports = router
