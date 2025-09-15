const express = require("express")
const router = express.Router()
const attendanceController = require("../controllers/attendanceController")
const { authenticateToken } = require("../middleware/auth")

// All routes require authentication
router.use(authenticateToken)

// Employee routes
router.get("/today", attendanceController.getTodayAttendance)
router.post("/clock-in", attendanceController.clockIn)
router.post("/clock-out", attendanceController.clockOut)
router.post("/break/start", attendanceController.startBreak)
router.post("/break/end", attendanceController.endBreak)
router.get("/history", attendanceController.getAttendanceHistory)
router.get("/summary", attendanceController.getAttendanceSummary)

module.exports = router
