const ExpenseClaim = require("../models/ExpenseClaim")
const User = require("../models/User")
const moment = require("moment")

// Apply for Expense Claim
const applyExpenseClaim = async (req, res) => {
  try {
    if (!req.user || !req.user.employeeId) {
      return res.status(401).json({
        success: false,
        message: "Authentication required: Employee ID not found in token.",
      })
    }

    const { expenseType, amount, currency, description, receiptUrl } = req.body
    const employeeId = req.user.employeeId
    const user = await User.findOne({ employeeId })

    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    if (!expenseType || !amount || !description) {
      return res.status(400).json({
        success: false,
        message: "Expense type, amount, and description are required.",
      })
    }

    const newClaim = new ExpenseClaim({
      employeeId,
      employeeName: user.name || "Unknown",
      expenseType,
      amount,
      currency: currency || "USD",
      description,
      receiptUrl: receiptUrl || null,
      status: "pending",
    })

    await newClaim.save()
    console.log("Expense claim saved:", newClaim) // Logging for debugging
    res.status(201).json({
      success: true,
      message: "Expense claim submitted successfully",
      claim: newClaim,
    })
  } catch (error) {
    console.error("Apply expense claim error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get My Expense Claims
const getMyExpenseClaims = async (req, res) => {
  try {
    const employeeId = req.user.employeeId
    const { page = 1, limit = 20, status, year } = req.query

    const query = { employeeId }

    if (status) {
      query.status = status
    }

    if (year) {
      query.claimDate = {
        $gte: new Date(`${year}-01-01`),
        $lte: new Date(`${year}-12-31`),
      }
    }

    const claims = await ExpenseClaim.find(query)
      .sort({ claimDate: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    const total = await ExpenseClaim.countDocuments(query)

    res.json({
      success: true,
      claims,
      pagination: {
        currentPage: Number.parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get my expense claims error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Get All Expense Claims (Admin/HR)
const getAllExpenseClaims = async (req, res) => {
  try {
    const { page = 1, limit = 20, status, employeeId, department, expenseType, startDate, endDate } = req.query

    const query = {}

    if (status) query.status = status
    if (expenseType) query.expenseType = expenseType
    if (startDate && endDate) {
      query.claimDate = {
        $gte: new Date(startDate),
        $lte: new Date(endDate),
      }
    }
    if (employeeId) query.employeeId = employeeId

    if (department) {
      const employeesInDept = await User.find({ department, isActive: true }).select("employeeId")
      const employeeIds = employeesInDept.map((emp) => emp.employeeId)
      query.employeeId = { $in: employeeIds }
    }

    const claims = await ExpenseClaim.find(query)
      .sort({ claimDate: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)
      .lean()

    const total = await ExpenseClaim.countDocuments(query)

    const claimsWithEmployeeNames = await Promise.all(
      claims.map(async (claim) => {
        const employee = await User.findOne({ employeeId: claim.employeeId }).select("name")
        return {
          ...claim,
          employeeName: employee?.name || claim.employeeName || "Unknown",
          expenseType: claim.expenseType || "N/A",
          amount: claim.amount || 0,
          description: claim.description || "N/A",
          status: claim.status || "pending",
        }
      }),
    )

    res.json({
      success: true,
      claims: claimsWithEmployeeNames,
      pagination: {
        currentPage: Number.parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalRecords: total,
        hasNext: page < Math.ceil(total / limit),
        hasPrev: page > 1,
      },
    })
  } catch (error) {
    console.error("Get all expense claims error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Update Expense Claim Status (Admin/HR)
const updateExpenseClaimStatus = async (req, res) => {
  try {
    const { id } = req.params
    const { status, rejectionReason } = req.body
    const approverEmployeeId = req.user.employeeId

    const approver = await User.findOne({ employeeId: approverEmployeeId })

    const claim = await ExpenseClaim.findById(id)
    if (!claim) {
      return res.status(404).json({
        success: false,
        message: "Expense claim not found",
      })
    }

    if (claim.status !== "pending") {
      return res.status(400).json({
        success: false,
        message: "Expense claim has already been processed",
      })
    }

    claim.status = status
    claim.approvedBy = {
      employeeId: approverEmployeeId,
      name: approver.name,
      role: approver.role,
    }
    claim.approvedAt = new Date()

    if (status === "rejected" && rejectionReason) {
      claim.rejectionReason = rejectionReason
    }

    await claim.save()

    res.json({
      success: true,
      message: `Expense claim ${status} successfully`,
      claim,
    })
  } catch (error) {
    console.error("Update expense claim status error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

module.exports = {
  applyExpenseClaim,
  getMyExpenseClaims,
  getAllExpenseClaims,
  updateExpenseClaimStatus,
}
