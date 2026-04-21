import jwt from "jsonwebtoken";
import { config } from "../config.js";

export function auth(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "Missing token" });

  try {
    const decoded = jwt.verify(token, config.jwtSecret);
    req.userId = decoded.userId;
    return next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}
