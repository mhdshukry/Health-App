import bcrypt from "bcryptjs";
import express from "express";
import jwt from "jsonwebtoken";

import { config } from "../config.js";
import { auth } from "../middleware/auth.js";
import { buildState } from "./sync.js";
import { User } from "../models/User.js";
import { toClient } from "../utils/serialize.js";

export const router = express.Router();

function signToken(userId) {
  return jwt.sign({ userId }, config.jwtSecret, { expiresIn: "7d" });
}

router.post("/register", async (req, res) => {
  try {
    const { name, email, password, age, gender, height, weight } = req.body;
    if (!name || !email || !password)
      return res.status(400).json({ error: "Missing fields" });

    const exists = await User.findOne({ email: email.toLowerCase().trim() });
    if (exists) return res.status(409).json({ error: "Email already in use" });

    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: email.toLowerCase().trim(),
      password: hashed,
      age,
      gender,
      height,
      weight,
    });

    const token = signToken(user._id);
    const state = await buildState(user._id);
    return res.status(201).json({ token, ...state });
  } catch (err) {
    return res.status(500).json({ error: "Failed to register" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email: email.toLowerCase().trim() });
    if (!user)
      return res.status(401).json({ error: "Invalid email or password" });

    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.status(401).json({ error: "Invalid email or password" });

    const token = signToken(user._id);
    const state = await buildState(user._id);
    return res.json({ token, ...state });
  } catch (err) {
    return res.status(500).json({ error: "Failed to login" });
  }
});

router.get("/me", auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    return res.json({ user: toClient(user) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to load profile" });
  }
});
