const express = require("express")
const router = express.Router()
const authController = require("../controllers/authController")
const { authenticateToken } = require("../middleware/auth")

// Public routes
router.post("/login", authController.login)
router.post("/forgot-password", authController.forgotPassword)
router.post("/reset-password", authController.resetPassword)

// Protected routes
router.post("/register", authenticateToken, authController.register)
router.post("/change-password", authenticateToken, authController.changePassword)
router.post("/logout", authenticateToken, authController.logout)
router.get("/verify", authenticateToken, authController.verifyToken)

module.exports = router
