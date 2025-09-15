const moment = require("moment")

// Calculate distance between two coordinates (Haversine formula)
const calculateDistance = (lat1, lon1, lat2, lon2) => {
  const R = 6371e3 // Earth's radius in meters
  const φ1 = (lat1 * Math.PI) / 180
  const φ2 = (lat2 * Math.PI) / 180
  const Δφ = ((lat2 - lat1) * Math.PI) / 180
  const Δλ = ((lon2 - lon1) * Math.PI) / 180

  const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) + Math.cos(φ1) * Math.cos(φ2) * Math.sin(Δλ / 2) * Math.sin(Δλ / 2)
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))

  return R * c // Distance in meters
}

// Format time duration
const formatDuration = (minutes) => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  return `${hours}h ${mins}m`
}

// Check if time is within working hours
const isWithinWorkingHours = (currentTime, startTime, endTime) => {
  const current = moment(currentTime, "HH:mm")
  const start = moment(startTime, "HH:mm")
  const end = moment(endTime, "HH:mm")

  return current.isBetween(start, end, null, "[]")
}

// Calculate working days between two dates
const calculateWorkingDays = (startDate, endDate, excludeWeekends = true) => {
  const start = moment(startDate)
  const end = moment(endDate)
  let workingDays = 0

  while (start.isSameOrBefore(end)) {
    if (excludeWeekends) {
      if (start.day() !== 0 && start.day() !== 6) {
        // Not Sunday or Saturday
        workingDays++
      }
    } else {
      workingDays++
    }
    start.add(1, "day")
  }

  return workingDays
}

// Generate employee ID
const generateEmployeeId = (department, sequence) => {
  const deptCode = department.substring(0, 3).toUpperCase()
  const seqStr = sequence.toString().padStart(3, "0")
  return `${deptCode}${seqStr}`
}

// Validate email format
const isValidEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
  return emailRegex.test(email)
}

// Validate phone number format
const isValidPhoneNumber = (phone) => {
  const phoneRegex = /^\+?[\d\s\-$$$$]{10,}$/
  return phoneRegex.test(phone)
}

// Get current date in YYYY-MM-DD format
const getCurrentDate = () => {
  return moment().format("YYYY-MM-DD")
}

// Get current time in HH:mm:ss format
const getCurrentTime = () => {
  return moment().format("HH:mm:ss")
}

// Check if date is weekend
const isWeekend = (date) => {
  const day = moment(date).day()
  return day === 0 || day === 6 // Sunday or Saturday
}

// Calculate age from date of birth
const calculateAge = (dateOfBirth) => {
  return moment().diff(moment(dateOfBirth), "years")
}

// Format currency
const formatCurrency = (amount, currency = "USD") => {
  return new Intl.NumberFormat("en-US", {
    style: "currency",
    currency: currency,
  }).format(amount)
}

// Generate random password
const generateRandomPassword = (length = 8) => {
  const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
  let password = ""
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length))
  }
  return password
}

module.exports = {
  calculateDistance,
  formatDuration,
  isWithinWorkingHours,
  calculateWorkingDays,
  generateEmployeeId,
  isValidEmail,
  isValidPhoneNumber,
  getCurrentDate,
  getCurrentTime,
  isWeekend,
  calculateAge,
  formatCurrency,
  generateRandomPassword,
}
