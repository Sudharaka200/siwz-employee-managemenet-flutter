const express = require("express")
const router = express.Router()
const authController = require("../controllers/authController")
// const { authenticateToken } = require("../middleware/auth")
const jwt =  require("jsonwebtoken");
const bcrypt = require("bcryptjs");

const users = [{ id: 1, email: 'test@gmail.com', password: 'dajqijdnjanii' }];

router.post('/login', async (req, res) => {
    const { email, password} = req.body;

    const user = users.find(u => u.email === email);
    if(!user) {
        return res.status(401).json({ message: 'Invalid Credentials' });
    }

    const isvalid = await bcrypt.compare(password, user.password);
    if(!user) {
        return res.status(401).json({ message: 'Invalid Credentials' });
    }

    const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });

    res.json({ token, user: {id: user.id, email: user.email} });

});

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) return res.status(401).json({ message: 'Access denied' });

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ message: 'Invalid token' });
    req.user = user;
    next();
  });
};

router.get('/profile', authenticateToken, (req, res) => {
  res.json({ message: 'Protected data', user: req.user });
});


// Public routes
// router.post("/login", authController.login)
router.post("/forgot-password", authController.forgotPassword)
router.post("/reset-password", authController.resetPassword)

// Protected routes
router.post("/register", authenticateToken, authController.register)
router.post("/change-password", authenticateToken, authController.changePassword)
router.post("/logout", authenticateToken, authController.logout)
router.get("/verify", authenticateToken, authController.verifyToken)

module.exports = router
