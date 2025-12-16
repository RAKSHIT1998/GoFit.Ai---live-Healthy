// middleware/authMiddleware.js
import jwt from "jsonwebtoken";
import User from "../models/User.js"; // adjust path

export const authMiddleware = async (req, res, next) => {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith("Bearer ")) return res.status(401).json({ message: "No token" });
    const token = header.split(" ")[1];
    const secret = process.env.JWT_SECRET;
    const payload = jwt.verify(token, secret);
    if (!payload?.id) return res.status(401).json({ message: "Invalid token" });
    const user = await User.findById(payload.id).select("-passwordHash");
    if (!user) return res.status(401).json({ message: "User not found" });
    req.user = user;
    next();
  } catch (err) {
    console.error("auth error", err);
    return res.status(401).json({ message: "Unauthorized", error: err.message });
  }
};
