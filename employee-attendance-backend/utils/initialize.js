const User = require("../models/User")
const Department = require("../models/Department")
const Shift = require("../models/Shift")

const initializeDefaultData = async () => {
  try {
    console.log("🔄 Initializing default data...")

    // Create default departments
    await initializeDepartments()

    // Create default shifts
    await initializeShifts()

    // Create default users
    await initializeUsers()

    console.log("✅ Default data initialization completed")
  } catch (error) {
    console.error("❌ Error initializing default data:", error)
  }
}

const initializeDepartments = async () => {
  const departments = [
    {
      name: "Information Technology",
      code: "IT",
      description: "Technology and software development",
    },
    {
      name: "Human Resources",
      code: "HR",
      description: "Human resources and employee management",
    },
    {
      name: "Finance",
      code: "FIN",
      description: "Financial planning and accounting",
    },
    {
      name: "Marketing",
      code: "MKT",
      description: "Marketing and brand management",
    },
    {
      name: "Operations",
      code: "OPS",
      description: "Business operations and logistics",
    },
    {
      name: "Design",
      code: "DES",
      description: "Creative design and user experience",
    },
  ]

  for (const dept of departments) {
    const existingDept = await Department.findOne({ code: dept.code })
    if (!existingDept) {
      await Department.create(dept)
      console.log(`📁 Created department: ${dept.name}`)
    }
  }
}

const initializeShifts = async () => {
  const shifts = [
    {
      name: "Day Shift",
      code: "DAY",
      startTime: "09:00",
      endTime: "18:00",
      breakDuration: 60,
      workingDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
      description: "Standard day shift",
    },
    {
      name: "Night Shift",
      code: "NIGHT",
      startTime: "22:00",
      endTime: "07:00",
      breakDuration: 60,
      workingDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
      overtimeRate: 2.0,
      description: "Night shift with higher overtime rate",
    },
    {
      name: "Flexible Hours",
      code: "FLEX",
      startTime: "10:00",
      endTime: "19:00",
      breakDuration: 60,
      workingDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
      description: "Flexible working hours",
    },
  ]

  for (const shift of shifts) {
    const existingShift = await Shift.findOne({ code: shift.code })
    if (!existingShift) {
      await Shift.create(shift)
      console.log(`⏰ Created shift: ${shift.name}`)
    }
  }
}

const initializeUsers = async () => {
  const users = [
    {
      employeeId: "admin123",
      name: "System Administrator",
      email: "admin@swiztech.com",
      password: "admin@123",
      role: "admin",
      department: "Information Technology",
      designation: "System Administrator",
      phoneNumber: "+1234567890",
      workLocation: {
        name: "Head Office",
        address: "123 Business Street, City, State",
        coordinates: {
          latitude: 40.7128,
          longitude: -74.006,
        },
        radius: 5000000, // Changed to a large value for testing
      },
    },
    {
      employeeId: "hr123",
      name: "HR Manager",
      email: "hr@swiztech.com",
      password: "hr@123",
      role: "hr",
      department: "Human Resources",
      designation: "HR Manager",
      phoneNumber: "+1234567891",
      workLocation: {
        name: "Head Office",
        address: "123 Business Street, City, State",
        coordinates: {
          latitude: 40.7128,
          longitude: -74.006,
        },
        radius: 5000000, // Changed to a large value for testing
      },
    },
    {
      employeeId: "emp001",
      name: "Anita Sahari",
      email: "anita@swiztech.com",
      password: "emp@123",
      role: "employee",
      department: "Design",
      designation: "UI/UX Designer",
      phoneNumber: "+1234567892",
      salary: 75000,
      workLocation: {
        name: "Head Office",
        address: "123 Business Street, City, State",
        coordinates: {
          latitude: 40.7128,
          longitude: -74.006,
        },
        radius: 5000000, // Changed to a large value for testing
      },
      workingHours: {
        startTime: "09:00",
        endTime: "18:00",
        breakDuration: 60,
      },
    },
    {
      employeeId: "emp002",
      name: "John Smith",
      email: "john@swiztech.com",
      password: "emp@123",
      role: "employee",
      department: "Information Technology",
      designation: "Software Developer",
      phoneNumber: "+1234567893",
      salary: 85000,
      workLocation: {
        name: "Head Office",
        address: "123 Business Street, City, State",
        coordinates: {
          latitude: 40.7128,
          longitude: -74.006,
        },
        radius: 5000000, // Changed to a large value for testing
      },
    },
    {
      employeeId: "emp003",
      name: "Sarah Johnson",
      email: "sarah@swiztech.com",
      password: "emp@123",
      role: "employee",
      department: "Marketing",
      designation: "Marketing Specialist",
      phoneNumber: "+1234567894",
      salary: 65000,
      workLocation: {
        name: "Head Office",
        address: "123 Business Street, City, State",
        coordinates: {
          latitude: 40.7128,
          longitude: -74.006,
        },
        radius: 5000000, // Changed to a large value for testing
      },
    },
  ]

  for (const userData of users) {
    const existingUser = await User.findOne({ employeeId: userData.employeeId })
    if (!existingUser) {
      await User.create(userData)
      console.log(`👤 Created user: ${userData.name} (${userData.employeeId})`)
    }
  }
}

module.exports = initializeDefaultData
