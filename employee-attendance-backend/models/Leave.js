const mongoose = require("mongoose")

const leaveSchema = new mongoose.Schema(
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
    leaveType: {
      type: String,
      required: true,
      enum: [
        "sick-leave",
        "casual-leave",
        "annual-leave",
        "maternity-leave",
        "paternity-leave",
        "emergency-leave",
        "unpaid-leave",
        "compensatory-leave",
      ],
    },
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    totalDays: {
      type: Number,
      required: true,
    },
    reason: {
      type: String,
      required: true,
      maxlength: 500,
    },
    status: {
      type: String,
      enum: ["pending", "approved", "rejected", "cancelled"],
      default: "pending",
    },
    appliedAt: {
      type: Date,
      default: Date.now,
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
    documents: [
      {
        fileName: String,
        fileUrl: String,
        fileType: String,
        uploadedAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    emergencyContact: {
      name: String,
      phoneNumber: String,
      relationship: String,
    },
    handoverDetails: {
      handoverTo: String,
      tasks: String,
      instructions: String,
    },
    isHalfDay: {
      type: Boolean,
      default: false,
    },
    halfDayPeriod: {
      type: String,
      enum: ["first-half", "second-half"],
    },
  },
  {
    timestamps: true,
  },
)

// Calculate total days before saving
leaveSchema.pre("save", function (next) {
  if (this.startDate && this.endDate) {
    const timeDiff = this.endDate.getTime() - this.startDate.getTime()
    this.totalDays = Math.ceil(timeDiff / (1000 * 3600 * 24)) + 1

    if (this.isHalfDay) {
      this.totalDays = 0.5
    }
  }
  next()
})

module.exports = mongoose.model("Leave", leaveSchema)
