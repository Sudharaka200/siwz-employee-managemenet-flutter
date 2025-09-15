const express = require("express")
const mongoose = require("mongoose")
const cors = require("cors")
const dotenv = require("dotenv")

// Load environment variables
dotenv.config()

const app = express()

// Middleware
app.use(cors())
app.use(express.json())
app.use(express.urlencoded({ extended: true }))

// MongoDB Connection
const MONGODB_URI =
  process.env.MONGODB_URI ||
  "mongodb+srv://employee_attendance:Swiztech@987@cluster0.hdgapev.mongodb.net/?retryWrites=true&w=majority"

mongoose
  .connect(MONGODB_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
  })
  .then(() => console.log("✅ Connected to MongoDB"))
  .catch((err) => console.error("❌ MongoDB connection error:", err))

// Import Routes
const authRoutes = require("./routes/auth")
const attendanceRoutes = require("./routes/attendance")
const adminRoutes = require("./routes/admin")
const leaveRoutes = require("./routes/leave")
const employeeRoutes = require("./routes/employee")
const reportRoutes = require("./routes/reports")
const expenseRoutes = require("./routes/expense")
const shiftRoutes = require("./routes/shift") 
const noticeRoutes = require("./routes/notices")

// Use Routes
app.use("/api/auth", authRoutes)
app.use("/api/attendance", attendanceRoutes)
app.use("/api/admin", adminRoutes)
app.use("/api/leave", leaveRoutes)
app.use("/api/employee", employeeRoutes)
app.use("/api/expense", expenseRoutes)
app.use("/api/reports", reportRoutes)
app.use("/api/shifts", shiftRoutes) 
app.use("/api/notices", noticeRoutes)

// Initialize default data
const initializeData = require("./utils/initialize")
initializeData()

// Health check endpoint
app.get("/api/health", (req, res) => {
  res.json({
    success: true,
    message: "Server is running",
    timestamp: new Date().toISOString(),
    version: "1.0.0",
  })
})

// Error handling middleware
app.use((err, req, res, next) => {
  console.error("Error:", err.stack)
  res.status(500).json({
    success: false,
    message: "Something went wrong!",
    error: process.env.NODE_ENV === "development" ? err.message : "Internal server error",
  })
})

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    success: false,
    message: "Route not found",
  })
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`)
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`)
  console.log(`🌐 Environment: ${process.env.NODE_ENV || "development"}`)
})

module.exports = app
