const User = require("../models/User");
const jwt = require("jsonwebtoken");
const bcrypt = require("bcryptjs");
const { sendForgotPasswordEmail } = require("../utils/emailService");

const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || "24h";

// Generate JWT Token
const generateToken = (userId, employeeId, role) => {
  return jwt.sign({ userId, employeeId, role }, JWT_SECRET, {
    expiresIn: JWT_EXPIRES_IN,
  });
};

// Generate temporary password
const generateTempPassword = () => {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789@#$";
  let tempPassword = "";
  for (let i = 0; i < 8; i++) {
    tempPassword += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return tempPassword;
};

// ===================== LOGIN =====================
exports.login = async (req, res) => {
  try {
    const { employeeId, password, deviceInfo } = req.body;

    if (!employeeId || !password) {
      return res.status(400).json({
        success: false,
        message: "Employee ID and password are required",
      });
    }

    // Find active user
    const user = await User.findOne({
      employeeId: employeeId.toLowerCase(),
      isActive: true,
    });

    if (!user) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    // Validate password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({ success: false, message: "Invalid credentials" });
    }

    // Update login details
    user.lastLogin = new Date();
    if (deviceInfo) {
      user.deviceInfo = deviceInfo;
    }
    await user.save();

    // Generate JWT
    const token = generateToken(user._id, user.employeeId, user.role);

    res.json({
      success: true,
      message: "Login successful",
      token,
      user: {
        id: user._id,
        employeeId: user.employeeId,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        designation: user.designation,
        profilePicture: user.profilePicture,
        workLocation: user.workLocation,
        workingHours: user.workingHours,
      },
    });
  } catch (error) {
    console.error("Login error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};

// ===================== AUTH MIDDLEWARE =====================
exports.authenticateToken = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    return res.status(401).json({ message: "Access denied" });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: "Invalid token" });
    req.user = user;
    next();
  });
};

// ===================== REGISTER =====================
exports.register = async (req, res) => {
  try {
    const {
      employeeId,
      name,
      email,
      password,
      role,
      department,
      designation,
      phoneNumber,
      workLocation,
      workingHours,
      salary,
    } = req.body;

    // Check for duplicates
    const existingUser = await User.findOne({
      $or: [{ employeeId }, { email }],
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: "Employee ID or email already exists",
      });
    }

    // Create user
    const newUser = new User({
      employeeId: employeeId.toLowerCase(),
      name,
      email: email.toLowerCase(),
      password,
      role: role || "employee",
      department,
      designation,
      phoneNumber,
      workLocation,
      workingHours,
      salary,
    });

    await newUser.save();

    res.status(201).json({
      success: true,
      message: "User registered successfully",
      user: {
        id: newUser._id,
        employeeId: newUser.employeeId,
        name: newUser.name,
        email: newUser.email,
        role: newUser.role,
        department: newUser.department,
      },
    });
  } catch (error) {
    console.error("Register error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};

// ===================== CHANGE PASSWORD =====================
exports.changePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const userId = req.user.userId;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const isCurrentPasswordValid = await user.comparePassword(currentPassword);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({ success: false, message: "Current password is incorrect" });
    }

    user.password = newPassword;
    await user.save();

    res.json({ success: true, message: "Password changed successfully" });
  } catch (error) {
    console.error("Change password error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};

// ===================== FORGOT PASSWORD =====================
exports.forgotPassword = async (req, res) => {
  try {
    const { employeeId, email } = req.body;

    let user;
    if (employeeId) {
      user = await User.findOne({ employeeId: employeeId.toLowerCase(), isActive: true });
    } else if (email) {
      user = await User.findOne({ email: email.toLowerCase(), isActive: true });
    } else {
      return res.status(400).json({ success: false, message: "Employee ID or email is required" });
    }

    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    const tempPassword = generateTempPassword();
    user.password = tempPassword;
    user.isTemporaryPassword = true;
    await user.save();

    let emailResult;
    try {
      emailResult = await sendForgotPasswordEmail(
        user.email,
        user.name,
        user.employeeId,
        tempPassword
      );
    } catch (emailError) {
      console.error("Error sending forgot password email:", emailError);
      emailResult = { success: false, message: emailError.message };
    }

    res.json({
      success: true,
      message: "Temporary password sent to your email",
      emailStatus: emailResult,
    });
  } catch (error) {
    console.error("Forgot password error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};

// ===================== RESET PASSWORD =====================
exports.resetPassword = async (req, res) => {
  try {
    const { employeeId, tempPassword, newPassword } = req.body;

    if (!employeeId || !tempPassword || !newPassword) {
      return res.status(400).json({
        success: false,
        message: "Employee ID, temporary password, and new password are required",
      });
    }

    const user = await User.findOne({ employeeId: employeeId.toLowerCase(), isActive: true });
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    if (!user.isTemporaryPassword) {
      return res.status(400).json({
        success: false,
        message: "No temporary password found. Please request a new one.",
      });
    }

    const isTempPasswordValid = await user.comparePassword(tempPassword);
    if (!isTempPasswordValid) {
      return res.status(400).json({ success: false, message: "Invalid temporary password" });
    }

    user.password = newPassword;
    user.isTemporaryPassword = false;
    await user.save();

    res.json({ success: true, message: "Password reset successfully" });
  } catch (error) {
    console.error("Reset password error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};

// ===================== LOGOUT =====================
exports.logout = async (req, res) => {
  try {
    // Optional: implement token blacklist
    res.json({ success: true, message: "Logged out successfully" });
  } catch (error) {
    console.error("Logout error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};

// ===================== VERIFY TOKEN =====================
exports.verifyToken = async (req, res) => {
  try {
    const user = await User.findById(req.user.userId);
    if (!user) {
      return res.status(404).json({ success: false, message: "User not found" });
    }

    res.json({
      success: true,
      user: {
        id: user._id,
        employeeId: user.employeeId,
        name: user.name,
        email: user.email,
        role: user.role,
        department: user.department,
        designation: user.designation,
      },
    });
  } catch (error) {
    console.error("Verify token error:", error);
    res.status(500).json({ success: false, message: "Internal server error" });
  }
};
