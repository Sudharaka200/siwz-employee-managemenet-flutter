const express = require("express")
const router = express.Router()
const expenseController = require("../controllers/expenseController")
const { authenticateToken, requireRole } = require("../middleware/auth")

// All routes require authentication
router.use(authenticateToken)

// Employee routes
router.post("/apply", expenseController.applyExpenseClaim)
router.get("/my-claims", expenseController.getMyExpenseClaims)

// Admin/HR routes
router.get("/all", requireRole(["admin", "hr"]), expenseController.getAllExpenseClaims)
router.put("/:id/status", requireRole(["admin", "hr"]), expenseController.updateExpenseClaimStatus)

module.exports = router
