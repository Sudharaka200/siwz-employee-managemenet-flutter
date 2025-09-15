const express = require("express");
const router = express.Router();
const { authenticateToken, requireAdmin } = require("../middleware/auth");

// Import controller functions
const {
  getNotices,
  getNotice,
  createNotice,
  updateNotice,
  deleteNotice,
  getAdminNotices,
  getNoticeStats,
  markAsRead,
  getUnreadCount,
} = require("../controllers/noticeController");

// Employee routes
router.get("/", authenticateToken, getNotices);
router.get("/unread-count", authenticateToken, getUnreadCount);
router.get("/:id", authenticateToken, getNotice);
router.put("/:id/read", authenticateToken, markAsRead);

// Admin routes
router.get("/admin/all", authenticateToken, requireAdmin, getAdminNotices);
router.get("/admin/stats", authenticateToken, requireAdmin, getNoticeStats);
router.post("/", authenticateToken, requireAdmin, createNotice);
router.put("/:id", authenticateToken, requireAdmin, updateNotice);
router.delete("/:id", authenticateToken, requireAdmin, deleteNotice);

module.exports = router;