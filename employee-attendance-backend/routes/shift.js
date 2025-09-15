const express = require("express")
const router = express.Router()
const shiftController = require("../controllers/shiftController")
const { authenticateToken, requireRole } = require("../middleware/auth")

router.use(authenticateToken)

// Get all active shifts - accessible to all authenticated users
router.get("/", shiftController.getAllShifts)

router.use(requireRole(["admin", "hr"]))
router.post("/", shiftController.addShift)
router.put("/:id", shiftController.updateShift)
router.delete("/:id", shiftController.deleteShift)

module.exports = router
