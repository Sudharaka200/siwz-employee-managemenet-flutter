const Attendance = require("../models/Attendance")
const User = require("../models/User")
const moment = require("moment")

// Get today's attendance
exports.getTodayAttendance = async (req, res) => {
  try {
    const today = moment().format("YYYY-MM-DD")
    const employeeId = req.user.employeeId

    const attendance = await Attendance.findOne({
      employeeId,
      date: today,
    })

    res.json({
      success: true,
      attendance: attendance || null,
    })
  } catch (error) {
    console.error("Get today attendance error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Clock In
exports.clockIn = async (req, res) => {
  try {
    const { latitude, longitude, address, deviceInfo, photo, notes } = req.body
    const employeeId = req.user.employeeId
    const today = moment().format("YYYY-MM-DD")
    const currentTime = moment().format("HH:mm:ss")

    // Get user details
    const user = await User.findOne({ employeeId })
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Check if already clocked in today
    let attendance = await Attendance.findOne({
      employeeId,
      date: today,
    })

    if (attendance && attendance.clockIn) {
      return res.status(400).json({
        success: false,
        message: "Already clocked in today",
      })
    }

    // --- REMOVED GEOFENCING CHECK ---
    // The following block is commented out to allow clocking in from anywhere.
    // if (user.workLocation && user.workLocation.coordinates) {
    //   const distance = calculateDistance(
    //     latitude,
    //     longitude,
    //     user.workLocation.coordinates.latitude,
    //     user.workLocation.coordinates.longitude,
    //   )
    //   if (distance > user.workLocation.radius) {
    //     return res.status(400).json({
    //       success: false,
    //       message: "You are outside the allowed work location",
    //       distance: Math.round(distance),
    //       allowedRadius: user.workLocation.radius,
    //     })
    //   }
    // }
    // --- END REMOVED GEOFENCING CHECK ---

    // Determine status (late, on-time, etc.)
    const workStartTime = user.workingHours.startTime || "09:00"
    const isLate = moment(currentTime, "HH:mm:ss").isAfter(moment(workStartTime, "HH:mm"))

    const clockInData = {
      time: currentTime,
      location: {
        latitude,
        longitude,
        address, // Now this will be the actual address from Flutter
      },
      deviceInfo,
      photo,
      notes,
    }

    if (attendance) {
      // Update existing attendance record
      attendance.clockIn = clockInData
      attendance.status = isLate ? "late" : "present"
    } else {
      // Create new attendance record
      attendance = new Attendance({
        employeeId,
        employeeName: user.name,
        date: today,
        clockIn: clockInData,
        status: isLate ? "late" : "present",
      })
    }

    await attendance.save()

    res.json({
      success: true,
      message: "Clocked in successfully",
      attendance,
      isLate,
    })
  } catch (error) {
    console.error("Clock in error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Clock Out
exports.clockOut = async (req, res) => {
  try {
    const { latitude, longitude, address, deviceInfo, photo, notes } = req.body
    const employeeId = req.user.employeeId
    const today = moment().format("YYYY-MM-DD")
    const currentTime = moment().format("HH:mm:ss")

    // Find today's attendance
    const attendance = await Attendance.findOne({
      employeeId,
      date: today,
    })

    console.log("Clock Out Request - Employee ID:", employeeId, "Date:", today)
    console.log("Found attendance record:", attendance ? JSON.stringify(attendance.toObject()) : "No record found")

    if (!attendance || !attendance.clockIn) {
      return res.status(400).json({
        success: false,
        message: "Must clock in first",
      })
    }

    if (attendance.clockOut && attendance.clockOut.time) {
      console.log("Attempted to clock out, but attendance.clockOut is already set:", attendance.clockOut)
      return res.status(400).json({
        success: false,
        message: "Already clocked out today",
      })
    }

    // Calculate working hours
    const clockInTime = moment(attendance.clockIn.time, "HH:mm:ss")
    const clockOutTime = moment(currentTime, "HH:mm:ss")
    const workingMinutes = clockOutTime.diff(clockInTime, "minutes")
    const workingHours = workingMinutes / 60

    // Calculate break time
    const totalBreakTime = attendance.breaks.reduce((total, breakItem) => {
      return total + (breakItem.duration || 0)
    }, 0)

    const actualWorkingHours = workingHours - totalBreakTime / 60

    // Calculate overtime (assuming 8 hours is standard)
    const standardHours = 8
    const overtime = Math.max(0, actualWorkingHours - standardHours)

    // Update attendance
    attendance.clockOut = {
      time: currentTime,
      location: {
        latitude,
        longitude,
        address, // Now this will be the actual address from Flutter
      },
      deviceInfo,
      photo,
      notes,
    }
    attendance.workingHours = Math.round(actualWorkingHours * 100) / 100
    attendance.overtime = Math.round(overtime * 100) / 100
    attendance.breakTime = totalBreakTime

    await attendance.save()

    res.json({
      success: true,
      message: "Clocked out successfully",
      attendance,
      workingHours: attendance.workingHours,
      overtime: attendance.overtime,
    })
  } catch (error) {
    console.error("Clock out error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Start Break
exports.startBreak = async (req, res) => {
  try {
    const { latitude, longitude, reason } = req.body
    const employeeId = req.user.employeeId
    const today = moment().format("YYYY-MM-DD")
    const currentTime = moment().format("HH:mm:ss")

    const attendance = await Attendance.findOne({
      employeeId,
      date: today,
    })

    if (!attendance || !attendance.clockIn) {
      return res.status(400).json({
        success: false,
        message: "Must clock in first",
      })
    }

    // Check if already on break
    const activeBreak = attendance.breaks.find((b) => b.breakStart && !b.breakEnd)
    if (activeBreak) {
      return res.status(400).json({
        success: false,
        message: "Already on break",
      })
    }

    attendance.breaks.push({
      breakStart: {
        time: currentTime,
        location: { latitude, longitude },
      },
      reason,
    })

    await attendance.save()

    res.json({
      success: true,
      message: "Break started successfully",
      attendance,
    })
  } catch (error) {
    console.error("Start break error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// End Break
exports.endBreak = async (req, res) => {
  try {
    const { latitude, longitude } = req.body
    const employeeId = req.user.employeeId
    const today = moment().format("YYYY-MM-DD")
    const currentTime = moment().format("HH:mm:ss")

    const attendance = await Attendance.findOne({
      employeeId,
      date: today,
    })

    if (!attendance) {
      return res.status(400).json({
        success: false,
        message: "No attendance record found",
      })
    }

    // Find active break
    const activeBreakIndex = attendance.breaks.findIndex((b) => b.breakStart && !b.breakEnd)
    if (activeBreakIndex === -1) {
      return res.status(400).json({
        success: false,
        message: "No active break found",
      })
    }

    const activeBreak = attendance.breaks[activeBreakIndex]
    const breakStartTime = moment(activeBreak.breakStart.time, "HH:mm:ss")
    const breakEndTime = moment(currentTime, "HH:mm:ss")
    const breakDuration = breakEndTime.diff(breakStartTime, "minutes")

    attendance.breaks[activeBreakIndex].breakEnd = {
      time: currentTime,
      location: { latitude, longitude },
    }
    attendance.breaks[activeBreakIndex].duration = breakDuration

    await attendance.save()

    res.json({
      success: true,
      message: "Break ended successfully",
      breakDuration,
      attendance,
    })
  } catch (error) {
    console.error("End break error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get Attendance History
exports.getAttendanceHistory = async (req, res) => {
  try {
    const employeeId = req.user.employeeId
    const { page = 1, limit = 30, startDate, endDate } = req.query

    const query = { employeeId }

    if (startDate && endDate) {
      query.date = {
        $gte: startDate,
        $lte: endDate,
      }
    }

    const attendance = await Attendance.find(query)
      .sort({ date: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await Attendance.countDocuments(query)

    res.json({
      success: true,
      attendance,
      pagination: {
        currentPage: page,
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get attendance history error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get Attendance Summary
exports.getAttendanceSummary = async (req, res) => {
  try {
    const employeeId = req.user.employeeId
    const { month, year } = req.query

    const startDate = moment(`${year}-${month}-01`).format("YYYY-MM-DD")
    const endDate = moment(`${year}-${month}-01`).endOf("month").format("YYYY-MM-DD")

    const attendance = await Attendance.find({
      employeeId,
      date: { $gte: startDate, $lte: endDate },
    })

    const summary = {
      totalDays: attendance.length,
      presentDays: attendance.filter((a) => a.status === "present").length,
      lateDays: attendance.filter((a) => a.status === "late").length,
      absentDays: attendance.filter((a) => a.status === "absent").length,
      halfDays: attendance.filter((a) => a.status === "half-day").length,
      totalWorkingHours: attendance.reduce((sum, a) => sum + (a.workingHours || 0), 0),
      totalOvertime: attendance.reduce((sum, a) => sum + (a.overtime || 0), 0),
      averageWorkingHours: 0,
    }

    if (summary.totalDays > 0) {
      summary.averageWorkingHours = summary.totalWorkingHours / summary.totalDays
    }

    res.json({
      success: true,
      summary,
      attendance,
    })
  } catch (error) {
    console.error("Get attendance summary error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Helper function to calculate distance between two coordinates (no longer used for geofencing)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371e3 // Earth's radius in meters
  const φ1 = (lat1 * Math.PI) / 180
  const φ2 = (lat2 * Math.PI) / 180
  const Δφ = ((lat2 - lat1) * Math.PI) / 180
  const Δλ = ((lon2 - lon1) * Math.PI) / 180

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return R * c // Distance in meters
}

module.exports = exports
