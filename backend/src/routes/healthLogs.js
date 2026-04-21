import express from "express";

import { HealthLog } from "../models/HealthLog.js";
import { User } from "../models/User.js";
import { listToClient, toClient } from "../utils/serialize.js";

export const router = express.Router();

router.get("/", async (req, res) => {
  const logs = await HealthLog.find({ userId: req.userId }).sort({ date: 1 });
  return res.json({ healthLogs: listToClient(logs) });
});

router.post("/", async (req, res) => {
  try {
    const { weight, height, notes, date } = req.body;
    const heightM = height / 100;
    const bmi = Number((weight / (heightM * heightM)).toFixed(2));

    const log = await HealthLog.create({
      userId: req.userId,
      weight,
      height,
      bmi,
      notes: notes || "",
      date: date ? new Date(date) : new Date(),
    });

    const user = await User.findByIdAndUpdate(
      req.userId,
      { weight, height },
      { new: true },
    );

    return res
      .status(201)
      .json({ healthLog: toClient(log), user: toClient(user) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to add health log" });
  }
});
