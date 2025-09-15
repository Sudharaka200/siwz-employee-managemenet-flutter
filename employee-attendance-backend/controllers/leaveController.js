const Leave = require("../models/Leave")
const User = require("../models/User")
const moment = require("moment")

// Apply for Leave
exports.applyLeave = async (req, res) => {
  try {
    const { leaveType, startDate, endDate, reason, isHalfDay, halfDayPeriod, emergencyContact, handoverDetails } =
      req.body

    const employeeId = req.user.employeeId
    const user = await User.findOne({ employeeId })

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Check for overlapping leaves
    const overlappingLeave = await Leave.findOne({
      employeeId,
      status: { $in: ["pending", "approved"] },
      $or: [
        {
          startDate: { $lte: new Date(endDate) },
          endDate: { $gte: new Date(startDate) },
        },
      ],
    })

    if (overlappingLeave) {
      return res.status(400).json({
        success: false,
        message: "You already have a leave request for overlapping dates",
      })
    }

    // Calculate total days
    let totalDays
    if (isHalfDay) {
      totalDays = 0.5
    } else {
      const start = moment(startDate)
      const end = moment(endDate)
      totalDays = end.diff(start, "days") + 1
    }

    const newLeave = new Leave({
      employeeId,
      employeeName: user.name,
      leaveType,
      startDate: new Date(startDate),
      endDate: new Date(endDate),
      totalDays,
      reason,
      isHalfDay: isHalfDay || false,
      halfDayPeriod,
      emergencyContact,
      handoverDetails,
    })

    await newLeave.save()

    res.status(201).json({
      success: true,
      message: "Leave application submitted successfully",
      leave: newLeave,
    })
  } catch (error) {
    console.error("Apply leave error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get My Leaves
exports.getMyLeaves = async (req, res) => {
  try {
    const employeeId = req.user.employeeId
    const { page = 1, limit = 20, status, year } = req.query

    const query = { employeeId }

    if (status) {
      query.status = status
    }

    if (year) {
      query.startDate = {
        $gte: new Date(`${year}-01-01`),
        $lte: new Date(`${year}-12-31`),
      }
    }

    const leaves = await Leave.find(query)
      .sort({ appliedAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await Leave.countDocuments(query)

    // Calculate leave balance
    const currentYear = new Date().getFullYear()
    const usedLeaves = await Leave.aggregate([
      {
        $match: {
          employeeId,
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

    const leaveBalance = {
      "annual-leave": 21 - (usedLeaves.find((l) => l._id === "annual-leave")?.totalDays || 0),
      "sick-leave": 10 - (usedLeaves.find((l) => l._id === "sick-leave")?.totalDays || 0),
      "casual-leave": 12 - (usedLeaves.find((l) => l._id === "casual-leave")?.totalDays || 0),
      "emergency-leave": 5 - (usedLeaves.find((l) => l._id === "emergency-leave")?.totalDays || 0),
    }

    res.json({
      success: true,
      leaves,
      leaveBalance,
      pagination: {
        currentPage: Number.parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get my leaves error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Cancel Leave
exports.cancelLeave = async (req, res) => {
  try {
    const { id } = req.params
    const employeeId = req.user.employeeId

    const leave = await Leave.findOne({ _id: id, employeeId })

    if (!leave) {
      return res.status(404).json({
        success: false,
        message: "Leave request not found",
      })
    }

    if (leave.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Only pending leave requests can be cancelled",
      })
    }

    leave.status = "cancelled"
    await leave.save()

    res.json({
      success: true,
      message: "Leave request cancelled successfully",
      leave,
    })
  } catch (error) {
    console.error("Cancel leave error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get All Leave Requests (Admin/HR)
exports.getAllLeaves = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, department, leaveType, startDate, endDate } = req.query

    const query = {}

    if (status) {
      query.status = status
    }

    if (leaveType) {
      query.leaveType = leaveType
    }

    if (startDate && endDate) {
      query.startDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      }
    }

    // If department filter is applied
    if (department) {
      const employeesInDept = await User.find({ department, isActive: true }).select("employeeId")
      const employeeIds = employeesInDept.map((emp) => emp.employeeId)
      query.employeeId = { $in: employeeIds }
    }

    const leaves = await Leave.find(query)
      .sort({ appliedAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await Leave.countDocuments(query)

    res.json({
      success: true,
      leaves,
      pagination: {
        currentPage: Number.parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get all leaves error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Approve/Reject Leave
exports.updateLeaveStatus = async (req, res) => {
  try {
    const { id } = req.params
    const { status, rejectionReason } = req.body
    const approverEmployeeId = req.user.employeeId

    const approver = await User.findOne({ employeeId: approverEmployeeId })

    const leave = await Leave.findById(id)
    if (!leave) {
      return res.status(404).json({
        success: false,
        message: "Leave request not found",
      })
    }

    if (leave.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Leave request has already been processed",
      })
    }

    leave.status = status
    leave.approvedBy = {
      employeeId: approverEmployeeId,
      name: approver.name,
      role: approver.role,
    }
    leave.approvedAt = new Date()

    if (status === "rejected" && rejectionReason) {
      leave.rejectionReason = rejectionReason
    }

    await leave.save()

    res.json({
      success: true,
      message: `Leave request ${status} successfully`,
      leave,
    })
  } catch (error) {
    console.error("Update leave status error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get Leave Statistics
exports.getLeaveStatistics = async (req, res) => {
  try {
    const { year = new Date().getFullYear() } = req.query

    // Get leave statistics by type
    const leaveStats = await Leave.aggregate([
      {
        $match: {
          startDate: {
            $gte: new Date(`${year}-01-01`),
            $lte: new Date(`${year}-12-31`),
          },
          status: "approved",
        },
      },
      {
        $group: {
          _id: "$leaveType",
          totalRequests: { $sum: 1 },
          totalDays: { $sum: "$totalDays" },
        },
      },
    ])

    // Get monthly leave trend
    const monthlyTrend = await Leave.aggregate([
      {
        $match: {
          startDate: {
            $gte: new Date(`${year}-01-01`),
            $lte: new Date(`${year}-12-31`),
          },
          status: "approved",
        },
      },
      {
        $group: {
          _id: { $month: "$startDate" },
          totalRequests: { $sum: 1 },
          totalDays: { $sum: "$totalDays" },
        },
      },
      { $sort: { _id: 1 } },
    ])

    // Get department wise leave statistics
    const departmentStats = await Leave.aggregate([
      {
        $match: {
          startDate: {
            $gte: new Date(`${year}-01-01`),
            $lte: new Date(`${year}-12-31`),
          },
          status: "approved",
        },
      },
      {
        $lookup: {
          from: "users",
          localField: "employeeId",
          foreignField: "employeeId",
          as: "employee",
        },
      },
      {
        $unwind: "$employee",
      },
      {
        $group: {
          _id: "$employee.department",
          totalRequests: { $sum: 1 },
          totalDays: { $sum: "$totalDays" },
        },
      },
    ])

    res.json({
      success: true,
      statistics: {
        leaveStats,
        monthlyTrend,
        departmentStats,
      },
    })
  } catch (error) {
    console.error("Get leave statistics error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

module.exports = exports
