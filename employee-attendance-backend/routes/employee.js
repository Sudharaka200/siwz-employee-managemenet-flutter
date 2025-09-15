const express = require("express")
const router = express.Router()
const User = require("../models/User")
const employeeController = require("../controllers/employeeController") // Added employee controller import
const { authenticateToken } = require("../middleware/auth")

// All routes require authentication
router.use(authenticateToken)

router.get("/schedule", employeeController.getMySchedule)

// Get employee profile
router.get("/profile", async (req, res) => {
  try {
    const user = await User.findOne({ employeeId: req.user.employeeId }).select("-password")
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    res.json({
      success: true,
      user,
    })
  } catch (error) {
    console.error("Get profile error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

// Update employee profile
router.put("/profile", async (req, res) => {
  try {
    const { name, email, phoneNumber, address, emergencyContact, profilePicture, workLocation } = req.body

    const updateFields = {
      name,
      email,
      phoneNumber,
      address,
      emergencyContact,
      profilePicture,
    }

    // Only update workLocation if provided in the request body
    if (workLocation) {
      updateFields.workLocation = workLocation
    }

    const user = await User.findOneAndUpdate({ employeeId: req.user.employeeId }, updateFields, {
      new: true,
      runValidators: true,
    }).select("-password")

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    res.json({
      success: true,
      message: "Profile updated successfully",
      user,
    })
  } catch (error) {
    console.error("Update profile error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
})

module.exports = router
