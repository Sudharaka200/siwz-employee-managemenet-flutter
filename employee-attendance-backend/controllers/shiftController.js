const Shift = require("../models/Shift")

// Get All Shifts - now accessible to all authenticated users
exports.getAllShifts = async (req, res) => {
  try {
    const shifts = await Shift.find({ isActive: true }).sort({ name: 1 })
    res.json({
      success: true,
      shifts,
    })
  } catch (error) {
    console.error("Get all shifts error:", error)
    res.status(500).json({
      success: false,
      message: "Internal server error",
    })
  }
}

// Add Shift - Admin/HR only
exports.addShift = async (req, res) => {
  try {
    const { name, code, startTime, endTime, breakDuration, workingDays, overtimeRate, description } = req.body

    if (!name || !code || !startTime || !endTime) {
      return res.status(400).json({ success: false, message: "Name, code, start time, and end time are required." })
    }

    const existingShift = await Shift.findOne({ code: code.toUpperCase() })
    if (existingShift) {
      return res.status(400).json({ success: false, message: "Shift with this code already exists." })
    }

    const newShift = new Shift({
      name,
      code: code.toUpperCase(),
      startTime,
      endTime,
      breakDuration,
      workingDays,
      overtimeRate,
      description,
    })

    await newShift.save()

    res.status(201).json({ success: true, message: "Shift added successfully", shift: newShift })
  } catch (error) {
    console.error("Add shift error:", error)
    res.status(500).json({ success: false, message: "Internal server error" })
  }
}

// Update Shift - Admin/HR only
exports.updateShift = async (req, res) => {
  try {
    const { id } = req.params
    const updateData = req.body

    const updatedShift = await Shift.findByIdAndUpdate(id, updateData, { new: true, runValidators: true })

    if (!updatedShift) {
      return res.status(404).json({ success: false, message: "Shift not found" })
    }

    res.json({ success: true, message: "Shift updated successfully", shift: updatedShift })
  } catch (error) {
    console.error("Update shift error:", error)
    res.status(500).json({ success: false, message: "Internal server error" })
  }
}

// Delete Shift - Admin/HR only
exports.deleteShift = async (req, res) => {
  try {
    const { id } = req.params

    const deletedShift = await Shift.findByIdAndUpdate(id, { isActive: false }, { new: true })

    if (!deletedShift) {
      return res.status(404).json({ success: false, message: "Shift not found" })
    }

    res.json({ success: true, message: "Shift deleted successfully" })
  } catch (error) {
    console.error("Delete shift error:", error)
    res.status(500).json({ success: false, message: "Internal server error" })
  }
}
