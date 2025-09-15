const mongoose = require("mongoose")

const noticeSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, "Title is required"],
      trim: true,
      maxlength: [200, "Title cannot exceed 200 characters"],
    },
    content: {
      type: String,
      required: [true, "Content is required"],
      trim: true,
    },
    priority: {
      type: String,
      enum: ["Low", "Medium", "High"],
      default: "Medium",
    },
    category: {
      type: String,
      enum: ["General", "Announcement", "Policy", "Event", "Urgent"],
      default: "General",
    },
    targetAudience: {
      type: String,
      enum: ["all", "department", "role"],
      default: "all",
    },
    targetDepartment: {
      type: String,
      required: function () {
        return this.targetAudience === "department"
      },
    },
    targetRole: {
      type: String,
      required: function () {
        return this.targetAudience === "role"
      },
    },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    readBy: [
      {
        user: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "User",
        },
        readAt: {
          type: Date,
          default: Date.now,
        },
      },
    ],
    isActive: {
      type: Boolean,
      default: true,
    },
    expiryDate: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
)

// Indexes for better performance
noticeSchema.index({ createdAt: -1 })
noticeSchema.index({ priority: 1 })
noticeSchema.index({ category: 1 })
noticeSchema.index({ targetAudience: 1 })
noticeSchema.index({ isActive: 1 })

// Helper method to check if notice is read by a user
noticeSchema.methods.isReadBy = function (userId) {
  return this.readBy.some((read) => read.user.toString() === userId.toString())
}

// Helper method to mark notice as read
noticeSchema.methods.markAsRead = function (userId) {
  if (!this.isReadBy(userId)) {
    this.readBy.push({
      user: userId,
      readAt: new Date(),
    })
    return this.save()
  }
  return Promise.resolve(this)
}

module.exports = mongoose.model("Notice", noticeSchema)
