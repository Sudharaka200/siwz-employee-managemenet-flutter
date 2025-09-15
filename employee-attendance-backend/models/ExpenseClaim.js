const mongoose = require("mongoose")

const expenseClaimSchema = new mongoose.Schema(
  {
    employeeId: {
      type: String,
      required: true,
      ref: "User",
    },
    employeeName: {
      type: String,
      required: true,
    },
    claimDate: {
      type: Date,
      default: Date.now,
    },
    expenseType: {
      type: String,
      required: true,
      enum: [
        "travel",
        "food",
        "accommodation",
        "office-supplies",
        "software",
        "transportation",
        "training",
        "other",
      ],
    },
    amount: {
      type: Number,
      required: true,
      min: 0,
    },
    currency: {
      type: String,
      default: "USD",
    },
    description: {
      type: String,
      required: true,
      maxlength: 1000,
    },
    receiptUrl: {
      type: String, // URL to the uploaded receipt image/document
      default: null,
    },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },
    approvedBy: {
      employeeId: String,
      name: String,
      role: String,
    },
    approvedAt: {
      type: Date,
    },
    rejectionReason: {
      type: String,
      maxlength: 500,
    },
  },
  {
    timestamps: true,
  },
)

// Index for faster queries
expenseClaimSchema.index({ employeeId: 1, claimDate: -1 })
expenseClaimSchema.index({ status: 1 })

module.exports = mongoose.model("ExpenseClaim", expenseClaimSchema)
