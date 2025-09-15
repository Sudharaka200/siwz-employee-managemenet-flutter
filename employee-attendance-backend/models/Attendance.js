const mongoose = require("mongoose")

const attendanceSchema = new mongoose.Schema(
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
    date: {
      type: String,
      required: true,
    },
    clockIn: {
      time: String,
      location: {
        latitude: Number,
        longitude: Number,
        address: String,
      },
      deviceInfo: {
        deviceId: String,
        deviceType: String,
        ipAddress: String,
      },
      photo: String, // Base64 or URL
      notes: String,
    },
    clockOut: {
      time: String,
      location: {
        latitude: Number,
        longitude: Number,
        address: String,
      },
      deviceInfo: {
        deviceId: String,
        deviceType: String,
        ipAddress: String,
      },
      photo: String, // Base64 or URL
      notes: String,
    },
    breaks: [
      {
        breakStart: {
          time: String,
          location: {
            latitude: Number,
            longitude: Number,
          },
        },
        breakEnd: {
          time: String,
          location: {
            latitude: Number,
            longitude: Number,
          },
        },
        duration: Number, // in minutes
        reason: String,
      },
    ],
    status: {
      type: String,
      enum: ["present", "absent", "late", "half-day", "work-from-home", "on-leave"],
      default: "present",
    },
    workingHours: {
      type: Number,
      default: 0,
    },
    overtime: {
      type: Number,
      default: 0,
    },
    breakTime: {
      type: Number,
      default: 0,
    },
    productivity: {
      tasksCompleted: Number,
      tasksAssigned: Number,
      productivityScore: Number,
    },
    approvedBy: {
      type: String,
      ref: "User",
    },
    approvalStatus: {
      type: String,
      enum: ["pending", "approved", "rejected"],
      default: "pending",
    },
    irregularities: [
      {
        type: String,
        description: String,
        severity: {
          type: String,
          enum: ["low", "medium", "high"],
        },
      },
    ],
    workFromHome: {
      isWorkFromHome: {
        type: Boolean,
        default: false,
      },
      reason: String,
      approvedBy: String,
    },
  },
  {
    timestamps: true,
  },
)

// Index for faster queries
attendanceSchema.index({ employeeId: 1, date: 1 })
attendanceSchema.index({ date: 1 })
attendanceSchema.index({ status: 1 })

module.exports = mongoose.model("Attendance", attendanceSchema)
