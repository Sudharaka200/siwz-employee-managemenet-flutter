const User = require("../models/User")
const Attendance = require("../models/Attendance")
const Leave = require("../models/Leave")
const Department = require("../models/Department")
const Shift = require("../models/Shift") // Import Shift model
const moment = require("moment")
const { generateEmployeeId, generateRandomPassword } = require("../utils/helpers") // Import helpers
const { sendWelcomeEmail } = require("../utils/emailService") // Import email service

// Get Dashboard Statistics
exports.getDashboardStats = async (req, res) => {
  try {
    const today = moment().format("YYYY-MM-DD")

    // Get total employees
    const totalEmployees = await User.countDocuments({ isActive: true, role: "employee" })

    // Get today's attendance
    const todayAttendance = await Attendance.find({ date: today })
    const presentToday = todayAttendance.filter((a) => a.status === "present" || a.status === "late").length
    const lateToday = todayAttendance.filter((a) => a.status === "late").length
    const absentToday = totalEmployees - presentToday

    // Get pending leave requests
    const pendingLeaves = await Leave.countDocuments({ status: "pending" })

    // Get department wise stats
    const departmentStats = await User.aggregate([
      { $match: { isActive: true, role: "employee" } },
      { $group: { _id: "$department", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ])

    // Get monthly attendance trend
    const monthlyTrend = await Attendance.aggregate([
      {
        $match: {
          date: {
            $gte: moment().subtract(6, "months").format("YYYY-MM-DD"),
            $lte: today,
          },
        },
      },
      {
        $group: {
          _id: { $substr: ["$date", 0, 7] }, // YYYY-MM
          totalAttendance: { $sum: 1 },
          presentCount: {
            $sum: {
              $cond: [{ $in: ["$status", ["present", "late"]] }, 1, 0],
            },
          },
        },
      },
      { $sort: { _id: 1 } },
    ])

    res.json({
      success: true,
      stats: {
        totalEmployees,
        presentToday,
        absentToday,
        lateToday,
        pendingLeaves,
        attendanceRate: totalEmployees > 0 ? Math.round((presentToday / totalEmployees) * 100) : 0,
      },
      departmentStats,
      monthlyTrend,
    })
  } catch (error) {
    console.error("Get dashboard stats error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get All Employees
exports.getAllEmployees = async (req, res) => {
  try {
    const { page = 1, limit = 20, search, department, role } = req.query

    const query = { isActive: true }

    if (search) {
      query.$or = [
        { name: { $regex: search, $options: "i" } },
        { employeeId: { $regex: search, $options: "i" } },
        { email: { $regex: search, $options: "i" } },
      ]
    }

    if (department) {
      query.department = department
    }

    if (role) {
      query.role = role
    }

    const employees = await User.find(query)
      .select("-password")
      .sort({ name: 1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .populate("shift", "name startTime endTime breakDuration") // Populate shift details

    const total = await User.countDocuments(query)

    res.json({
      success: true,
      employees,
      pagination: {
        currentPage: Number.parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get all employees error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Add Employee
exports.addEmployee = async (req, res) => {
  try {
    const {
      name,
      email,
      role,
      department,
      designation,
      phoneNumber,
      workLocation,
      workingHours,
      salary,
      dateOfJoining,
      shiftId, // New: shiftId
    } = req.body

    // Validate required fields
    if (!name || !email || !department) {
      return res.status(400).json({
        success: false,
        message: "Name, email, and department are required",
      })
    }

    // Check if email already exists
    const existingUser = await User.findOne({ email: email.toLowerCase() })

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "Email already exists",
      })
    }

    // Get department code for employee ID generation
    const dept = await Department.findOne({ name: department })
    if (!dept) {
      return res.status(400).json({
        success: false,
        message: "Invalid department provided",
      })
    }

    // Generate employee ID
    const employeeCountInDept = await User.countDocuments({ department: department })
    const generatedEmployeeId = generateEmployeeId(dept.code, employeeCountInDept + 1)

    // Generate temporary password
    const generatedPassword = generateRandomPassword(8) // 8 character password

    let assignedShift = null
    let assignedWorkingHours = workingHours

    if (shiftId) {
      assignedShift = await Shift.findById(shiftId)
      if (!assignedShift) {
        return res.status(400).json({
          success: false,
          message: "Invalid Shift ID provided",
        })
      }
      // Override workingHours if a shift is assigned
      assignedWorkingHours = {
        startTime: assignedShift.startTime,
        endTime: assignedShift.endTime,
        breakDuration: assignedShift.breakDuration,
      }
    }

    // Create new user
    const newUser = new User({
      employeeId: generatedEmployeeId.toLowerCase(),
      name,
      email: email.toLowerCase(),
      password: generatedPassword, // Use generated password
      role: role || "employee",
      department,
      designation: designation || "Employee",
      phoneNumber,
      workLocation: workLocation || {
        name: "Head Office",
        address: "123 Business Street, City, State",
        coordinates: {
          latitude: 40.7128,
          longitude: -74.006,
        },
        radius: 5000000, // Changed to a large value for testing
      },
      workingHours: assignedWorkingHours || {
        startTime: "09:00",
        endTime: "18:00",
        breakDuration: 60,
      },
      shift: assignedShift ? assignedShift._id : null, // Assign shift ID
      salary: salary || 0,
      dateOfJoining: dateOfJoining || new Date(),
    })

    await newUser.save()

    let emailResult = { success: false, message: "Email service not configured" }

    try {
      console.log("🔄 Attempting to send welcome email for:", newUser.email)
      emailResult = await sendWelcomeEmail({
        name: newUser.name,
        email: newUser.email,
        employeeId: newUser.employeeId,
        temporaryPassword: generatedPassword,
        department: newUser.department,
        designation: newUser.designation,
      })
      console.log("📧 Email service response:", emailResult)
    } catch (emailError) {
      console.error("❌ Email sending failed:", emailError)
      emailResult = { success: false, message: "Failed to send welcome email", error: emailError.message }
    }

    console.log("📤 Final email status being sent to frontend:", {
      sent: emailResult.success,
      message: emailResult.message,
      messageId: emailResult.messageId || null,
    })

    res.status(201).json({
      success: true,
      message: "Employee added successfully",
      employee: {
        id: newUser._id,
        employeeId: newUser.employeeId,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
        department: newUser.department,
        generatedPassword: generatedPassword, // Return generated password
      },
      emailStatus: {
        sent: emailResult.success,
        message: emailResult.message,
        messageId: emailResult.messageId || null,
      },
    })
  } catch (error) {
    console.error("Add employee error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Update Employee
exports.updateEmployee = async (req, res) => {
  try {
    const { id } = req.params
    const updateData = req.body

    // Remove sensitive fields that shouldn't be updated directly
    delete updateData.password
    delete updateData._id
    delete updateData.createdAt
    delete updateData.updatedAt

    const employee = await User.findByIdAndUpdate(id, updateData, { new: true, runValidators: true }).select(
      "-password",
    )

    if (!employee) {
      return res.status(404).json({
        success: false,
        message: "Employee not found",
      })
    }

    res.json({
      success: true,
      message: "Employee updated successfully",
      employee,
    })
  } catch (error) {
    console.error("Update employee error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Delete Employee (Soft delete)
exports.deleteEmployee = async (req, res) => {
  try {
    const { id } = req.params

    const employee = await User.findByIdAndUpdate(id, { isActive: false }, { new: true })

    if (!employee) {
      return res.status(404).json({
        success: false,
        message: "Employee not found",
      })
    }

    res.json({
      success: true,
      message: "Employee deleted successfully",
    })
  } catch (error) {
    console.error("Delete employee error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get All Attendance Records
exports.getAllAttendance = async (req, res) => {
  try {
    const { page = 1, limit = 50, startDate, endDate, employeeId, department, status } = req.query

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

    if (status) {
      query.status = status
    }

    // If department filter is applied, we need to join with User collection
    if (department) {
      const employeesInDept = await User.find({ department, isActive: true }).select("employeeId")
      const employeeIds = employeesInDept.map((emp) => emp.employeeId)
      query.employeeId = { $in: employeeIds }
    }

    const attendance = await Attendance.find(query)
      .sort({ date: -1, createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await Attendance.countDocuments(query)

    res.json({
      success: true,
      attendance,
      pagination: {
        currentPage: Number.parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get all attendance error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Approve/Reject Attendance
exports.updateAttendanceStatus = async (req, res) => {
  try {
    const { id } = req.params
    const { approvalStatus, notes } = req.body
    const approvedBy = req.user.employeeId

    const attendance = await Attendance.findByIdAndUpdate(
      id,
      {
        approvalStatus,
        approvedBy,
        "irregularities.0.notes": notes,
      },
      { new: true },
    )

    if (!attendance) {
      return res.status(404).json({
        success: false,
        message: "Attendance record not found",
      })
    }

    res.json({
      success: true,
      message: `Attendance ${approvalStatus} successfully`,
      attendance,
    })
  } catch (error) {
    console.error("Update attendance status error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get Employee Details
exports.getEmployeeDetails = async (req, res) => {
  try {
    const { id } = req.params

    const employee = await User.findById(id)
      .select("-password")
      .populate("shift", "name startTime endTime breakDuration")
    if (!employee) {
      return res.status(404).json({
        success: false,
        message: "Employee not found",
      })
    }

    // Get recent attendance
    const recentAttendance = await Attendance.find({ employeeId: employee.employeeId }).sort({ date: -1 }).limit(10)

    // Get leave balance (this would typically come from a separate leave balance collection)
    const currentYear = new Date().getFullYear()
    const usedLeaves = await Leave.aggregate([
      {
        $match: {
          employeeId: employee.employeeId,
          status: "approved",
          startDate: {
            $gte: new Date(`${currentYear}-01-01`),
            $lte: new Date(`${currentYear}-12-31`),
          },
        },
      },
      {
        $group: {
          _id: "$leaveType",
          totalDays: { $sum: "$totalDays" },
        },
      },
    ])

    res.json({
      success: true,
      employee,
      recentAttendance,
      leaveBalance: {
        annual: 21 - (usedLeaves.find((l) => l._id === "annual-leave")?.totalDays || 0),
        sick: 10 - (usedLeaves.find((l) => l._id === "sick-leave")?.totalDays || 0),
        casual: 12 - (usedLeaves.find((l) => l._id === "casual-leave")?.totalDays || 0),
      },
    })
  } catch (error) {
    console.error("Get employee details error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Assign Shift to Employee
exports.assignShiftToEmployee = async (req, res) => {
  try {
    const { id } = req.params // User ID
    const { shiftId } = req.body // Shift ID

    const user = await User.findById(id)
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" })
    }

    let assignedShift = null
    if (shiftId) {
      assignedShift = await Shift.findById(shiftId)
      if (!assignedShift) {
        return res.status(404).json({ success: false, message: "Shift not found" })
      }
    }

    user.shift = assignedShift ? assignedShift._id : null
    user.workingHours = assignedShift
      ? {
          startTime: assignedShift.startTime,
          endTime: assignedShift.endTime,
          breakDuration: assignedShift.breakDuration,
        }
      : {
          // Default if no shift is assigned
          startTime: "09:00",
          endTime: "18:00",
          breakDuration: 60,
        }

    await user.save()

    res.json({ success: true, message: "Shift assigned successfully", user })
  } catch (error) {
    console.error("Assign shift error:", error)
    res.status(500).json({ success: false, message: "Internal server error" })
  }
}

module.exports = exports
