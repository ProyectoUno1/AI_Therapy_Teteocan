// backend/routes/hello.js

const express = require("express");
const router = express.Router();
const verifyFirebaseToken = require("../middlewares/auth_middleware");

// Ruta protegida
router.get("/hello", verifyFirebaseToken, (req, res) => {
  const user = req.firebaseUser;
  res.json({
    message: `¡Hola, ${user.email || "usuario"}!`,
    uid: user.uid,
    email_verified: user.email_verified,
  });
});

module.exports = router;
