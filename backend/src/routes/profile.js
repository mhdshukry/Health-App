import express from "express";

import { User } from "../models/User.js";
import { toClient } from "../utils/serialize.js";

export const router = express.Router();

router.put("/", async (req, res) => {
  try {
    const { name, age, gender, height, weight } = req.body;
    const user = await User.findByIdAndUpdate(
      req.userId,
      { name, age, gender, height, weight },
      { new: true },
    );
    return res.json({ user: toClient(user) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to update profile" });
  }
});
