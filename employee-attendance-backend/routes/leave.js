const express = require("express")
const router = express.Router()
const leaveController = require("../controllers/leaveController")
const { authenticateToken, requireRole } = require("../middleware/auth")

// All routes require authentication
router.use(authenticateToken)

// Employee routes
router.post("/apply", leaveController.applyLeave)
router.get("/my-leaves", leaveController.getMyLeaves)
router.put("/cancel/:id", leaveController.cancelLeave)

// Admin/HR routes
router.get("/all", requireRole(["admin", "hr"]), leaveController.getAllLeaves)
router.put("/:id/status", requireRole(["admin", "hr"]), leaveController.updateLeaveStatus)
router.get("/statistics", requireRole(["admin", "hr"]), leaveController.getLeaveStatistics)

module.exports = router
