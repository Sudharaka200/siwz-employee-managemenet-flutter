const mongoose = require("mongoose")
const Shift = require("../models/Shift")
require("dotenv").config()

const updateShifts = async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI)
    console.log("🔄 Connected to MongoDB")

    const shiftsData = [
      {
        code: "DAY",
        name: "Day Shift",
        startTime: "09:00",
        endTime: "18:00",
        breakDuration: 60,
        workingDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        description: "Standard day shift from 9 AM to 6 PM",
        isActive: true,
      },
      {
        code: "NIGHT",
        name: "Night Shift",
        startTime: "22:00",
        endTime: "07:00",
        breakDuration: 60,
        workingDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        overtimeRate: 2.0,
        description: "Night shift from 10 PM to 7 AM with higher overtime rate",
        isActive: true,
      },
      {
        code: "FLEX",
        name: "Flexible Hours",
        startTime: "10:00",
        endTime: "19:00",
        breakDuration: 60,
        workingDays: ["monday", "tuesday", "wednesday", "thursday", "friday"],
        description: "Flexible working hours from 10 AM to 7 PM",
        isActive: true,
      },
    ]

    for (const shiftData of shiftsData) {
      const result = await Shift.findOneAndUpdate({ code: shiftData.code }, shiftData, { upsert: true, new: true })
      console.log(`✅ Updated shift: ${result.name} (${result.code})`)
    }

    console.log("🎉 All shifts updated successfully!")
    process.exit(0)
  } catch (error) {
    console.error("❌ Error updating shifts:", error)
    process.exit(1)
  }
}

updateShifts()
