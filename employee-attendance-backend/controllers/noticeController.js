const Notice = require("../models/Notice")
const User = require("../models/User")

// Get all notices for employees
const getNotices = async (req, res) => {
  try {
    const { page = 1, limit = 10, priority, category, unreadOnly } = req.query
    const userId = req.user.id || req.user.userId || req.user._id

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "Unable to identify user. Please login again.",
      })
    }

    // Get user details for filtering
    const user = await User.findById(userId)
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    // Build query for notices
    const query = {
      isActive: true,
      $or: [{ expiryDate: { $exists: false } }, { expiryDate: null }, { expiryDate: { $gte: new Date() } }],
    }

    // Filter by target audience
    const audienceFilter = {
      $or: [
        { targetAudience: "all" },
        { targetAudience: "department", targetDepartment: user.department },
        { targetAudience: "role", targetRole: user.role },
      ],
    }

    // Combine filters
    query.$and = [audienceFilter]

    // Apply additional filters
    if (priority) query.priority = priority
    if (category) query.category = category

    let notices = await Notice.find(query)
      .populate("createdBy", "name email")
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    // Filter unread notices if requested
    if (unreadOnly === "true") {
      notices = notices.filter((notice) => !notice.isReadBy(userId))
    }

    // Add read status to each notice
    const noticesWithReadStatus = notices.map((notice) => ({
      ...notice.toObject(),
      isRead: notice.isReadBy(userId),
    }))

    const total = await Notice.countDocuments(query)

    res.json({
      success: true,
      data: noticesWithReadStatus,
      pagination: {
        current: Number.parseInt(page),
        pages: Math.ceil(total / limit),
        total,
      },
    })
  } catch (error) {
    console.error("Get notices error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch notices",
      error: error.message,
    })
  }
}

// Get single notice
const getNotice = async (req, res) => {
  try {
    const notice = await Notice.findById(req.params.id).populate("createdBy", "name email")

    if (!notice) {
      return res.status(404).json({
        success: false,
        message: "Notice not found",
      })
    }

    const userId = req.user.id || req.user.userId || req.user._id

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "Unable to identify user. Please login again.",
      })
    }

    // Check if user can access this notice
    const user = await User.findById(userId)
    const canAccess =
      notice.targetAudience === "all" ||
      (notice.targetAudience === "department" && notice.targetDepartment === user.department) ||
      (notice.targetAudience === "role" && notice.targetRole === user.role)

    if (!canAccess) {
      return res.status(403).json({
        success: false,
        message: "Access denied",
      })
    }

    const isRead = notice.isReadBy(userId)

    res.json({
      success: true,
      data: {
        ...notice.toObject(),
        isRead,
      },
    })
  } catch (error) {
    console.error("Get notice error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch notice",
      error: error.message,
    })
  }
}

// Create notice (Admin only)
const createNotice = async (req, res) => {
  try {
    console.log("Create notice request received:", req.body)
    console.log("User role:", req.user.role)
    console.log("User object:", req.user)
    console.log("Available user fields:", Object.keys(req.user || {}))

    // Check if user is admin
    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin privileges required.",
      })
    }

    const {
      title,
      content,
      priority = "Medium",
      category = "General",
      targetAudience = "all",
      targetDepartment,
      targetRole,
      expiryDate,
    } = req.body

    // Validate required fields
    if (!title || !content) {
      return res.status(400).json({
        success: false,
        message: "Title and content are required",
      })
    }

    const userId = req.user.id || req.user.userId || req.user._id
    console.log("Extracted user ID:", userId)

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "Unable to identify user. Please login again.",
      })
    }

    const notice = new Notice({
      title,
      content,
      priority,
      category,
      targetAudience,
      targetDepartment,
      targetRole,
      createdBy: userId, // Using extracted userId instead of req.user.id
      expiryDate: expiryDate ? new Date(expiryDate) : null,
    })

    await notice.save()
    await notice.populate("createdBy", "name email")

    console.log("Notice created successfully:", notice._id)

    res.status(201).json({
      success: true,
      message: "Notice created successfully",
      data: notice,
    })
  } catch (error) {
    console.error("Create notice error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to create notice",
      error: error.message,
    })
  }
}

// Update notice (Admin only)
const updateNotice = async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin privileges required.",
      })
    }

    const { title, content, priority, category, targetAudience, targetDepartment, targetRole, expiryDate, isActive } =
      req.body

    const updateData = {
      title,
      content,
      priority,
      category,
      targetAudience,
      targetDepartment,
      targetRole,
      expiryDate: expiryDate ? new Date(expiryDate) : null,
      isActive,
    }

    // Remove undefined fields
    Object.keys(updateData).forEach((key) => updateData[key] === undefined && delete updateData[key])

    const notice = await Notice.findByIdAndUpdate(req.params.id, updateData, {
      new: true,
      runValidators: true,
    }).populate("createdBy", "name email")

    if (!notice) {
      return res.status(404).json({
        success: false,
        message: "Notice not found",
      })
    }

    res.json({
      success: true,
      message: "Notice updated successfully",
      data: notice,
    })
  } catch (error) {
    console.error("Update notice error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to update notice",
      error: error.message,
    })
  }
}

// Delete notice (Admin only)
const deleteNotice = async (req, res) => {
  try {
    console.log("Delete notice request for ID:", req.params.id)
    console.log("User role:", req.user.role)

    // Check if user is admin
    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin privileges required.",
      })
    }

    const notice = await Notice.findByIdAndDelete(req.params.id)

    if (!notice) {
      return res.status(404).json({
        success: false,
        message: "Notice not found",
      })
    }

    console.log("Notice deleted successfully:", req.params.id)

    res.json({
      success: true,
      message: "Notice deleted successfully",
    })
  } catch (error) {
    console.error("Delete notice error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to delete notice",
      error: error.message,
    })
  }
}

// Get all notices for admin
const getAdminNotices = async (req, res) => {
  try {
    console.log("Get admin notices request")
    console.log("User role:", req.user.role)

    // Check if user is admin
    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin privileges required.",
      })
    }

    const { page = 1, limit = 10, priority, category, isActive } = req.query

    const query = {}
    if (priority) query.priority = priority
    if (category) query.category = category
    if (isActive !== undefined) query.isActive = isActive === "true"

    const notices = await Notice.find(query)
      .populate("createdBy", "name email")
      .populate("readBy.user", "name email")
      .sort({ createdAt: -1 })
      .limit(limit * 1)
      .skip((page - 1) * limit)

    // Add read statistics to each notice
    const noticesWithStats = notices.map((notice) => ({
      ...notice.toObject(),
      readCount: notice.readBy.length,
    }))

    const total = await Notice.countDocuments(query)

    console.log(`Found ${notices.length} notices for admin`)

    res.json({
      success: true,
      data: noticesWithStats,
      pagination: {
        current: Number.parseInt(page),
        pages: Math.ceil(total / limit),
        total,
      },
    })
  } catch (error) {
    console.error("Get admin notices error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch notices",
      error: error.message,
    })
  }
}

// Get notice statistics
const getNoticeStats = async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied. Admin privileges required.",
      })
    }

    const totalNotices = await Notice.countDocuments()
    const activeNotices = await Notice.countDocuments({ isActive: true })
    const expiredNotices = await Notice.countDocuments({
      expiryDate: { $lt: new Date() },
    })

    const priorityStats = await Notice.aggregate([{ $group: { _id: "$priority", count: { $sum: 1 } } }])

    const categoryStats = await Notice.aggregate([{ $group: { _id: "$category", count: { $sum: 1 } } }])

    // Get recent notices
    const recentNotices = await Notice.find()
      .populate("createdBy", "name")
      .sort({ createdAt: -1 })
      .limit(5)
      .select("title createdAt readBy")

    res.json({
      success: true,
      data: {
        totalNotices,
        activeNotices,
        expiredNotices,
        priorityStats,
        categoryStats,
        recentNotices: recentNotices.map((notice) => ({
          ...notice.toObject(),
          readCount: notice.readBy.length,
        })),
      },
    })
  } catch (error) {
    console.error("Get notice stats error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to fetch notice statistics",
      error: error.message,
    })
  }
}

// Mark notice as read
const markAsRead = async (req, res) => {
  try {
    const noticeId = req.params.id
    const userId = req.user.id || req.user.userId || req.user._id

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "Unable to identify user. Please login again.",
      })
    }

    const notice = await Notice.findById(noticeId)

    if (!notice) {
      return res.status(404).json({
        success: false,
        message: "Notice not found",
      })
    }

    // Check if user can access this notice
    const user = await User.findById(userId)
    const canAccess =
      notice.targetAudience === "all" ||
      (notice.targetAudience === "department" && notice.targetDepartment === user.department) ||
      (notice.targetAudience === "role" && notice.targetRole === user.role)

    if (!canAccess) {
      return res.status(403).json({
        success: false,
        message: "Access denied",
      })
    }

    // Mark as read
    await notice.markAsRead(userId)

    res.json({
      success: true,
      message: "Notice marked as read",
    })
  } catch (error) {
    console.error("Mark as read error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to mark notice as read",
      error: error.message,
    })
  }
}

// Get unread count for user
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.user.id || req.user.userId || req.user._id

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "Unable to identify user. Please login again.",
      })
    }

    // Get user details for filtering
    const user = await User.findById(userId)
    if (!user) {
      return res.status(404).json({
        success: false,
        message: "User not found",
      })
    }

    const query = {
      isActive: true,
      $or: [{ expiryDate: { $exists: false } }, { expiryDate: null }, { expiryDate: { $gte: new Date() } }],
      $and: [
        {
          $or: [
            { targetAudience: "all" },
            { targetAudience: "department", targetDepartment: user.department },
            { targetAudience: "role", targetRole: user.role },
          ],
        },
      ],
    }

    const notices = await Notice.find(query)
    const unreadCount = notices.filter((notice) => !notice.isReadBy(userId)).length

    res.json({
      success: true,
      data: { unreadCount },
    })
  } catch (error) {
    console.error("Get unread count error:", error)
    res.status(500).json({
      success: false,
      message: "Failed to get unread count",
      error: error.message,
    })
  }
}

module.exports = {
  getNotices,
  getNotice,
  createNotice,
  updateNotice,
  deleteNotice,
  getAdminNotices,
  getNoticeStats,
  markAsRead,
  getUnreadCount,
}
