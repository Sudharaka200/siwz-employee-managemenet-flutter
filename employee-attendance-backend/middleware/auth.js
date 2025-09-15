const jwt = require("jsonwebtoken")
const User = require("../models/User")

exports.authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"]
  const token = authHeader && authHeader.split(" ")[1]

  if (!token) {
    return res.status(401).json({ success: false, message: "Access Denied: No token provided!" })
  }

  try {
    const verified = jwt.verify(token, process.env.JWT_SECRET)
    req.user = verified // Contains { id, role, employeeId }
    next()
  } catch (err) {
    res.status(403).json({ success: false, message: "Access Denied: Invalid token!" })
  }
}

exports.requireRole = (roles) => {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return res.status(403).json({ success: false, message: "Access Denied: You do not have the required role." })
    }
    next()
  }
}

exports.requireAdmin = (req, res, next) => {
  if (!req.user || req.user.role !== "admin") {
    return res.status(403).json({ success: false, message: "Access Denied: Admin role required." })
  }
  next()
}
