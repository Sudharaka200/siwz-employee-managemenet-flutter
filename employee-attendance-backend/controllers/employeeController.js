const User = require("../models/User")
const Shift = require("../models/Shift")

// Get employee's assigned schedule
exports.getMySchedule = async (req, res) => {
  try {
    console.log("🔍 Getting schedule for employee:", req.user.employeeId)

    const user = await User.findOne({ employeeId: req.user.employeeId })
      .select("shift workingHours")
      .populate("shift", "name code startTime endTime breakDuration workingDays description isActive")

    if (!user) {
      console.log("❌ User not found:", req.user.employeeId)
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    console.log("👤 User found:", user.employeeId)
    console.log("📋 User shift:", user.shift)

    // If user has an assigned shift, return it
    if (user.shift) {
      console.log("✅ Returning assigned shift:", user.shift.name)
      res.json({
        success: true,
        schedule: {
          hasSchedule: true,
          shift: {
            name: user.shift.name,
            code: user.shift.code,
            startTime: user.shift.startTime,
            endTime: user.shift.endTime,
            breakDuration: user.shift.breakDuration,
            workingDays: user.shift.workingDays,
            description: user.shift.description,
          },
          workingHours: user.workingHours,
        },
      })
    } else {
      console.log("⚠️ No shift assigned to user")
      // If no shift assigned, return empty schedule
      res.json({
        success: true,
        schedule: {
          hasSchedule: false,
          shift: null,
          workingHours: user.workingHours,
        },
      })
    }
  } catch (error) {
    console.error("❌ Get employee schedule error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}
