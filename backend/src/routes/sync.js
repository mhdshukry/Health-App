import express from "express";

import { Activity } from "../models/Activity.js";
import { Goal } from "../models/Goal.js";
import { HealthLog } from "../models/HealthLog.js";
import { Reminder } from "../models/Reminder.js";
import { Tip } from "../models/Tip.js";
import { User } from "../models/User.js";
import { listToClient, toClient } from "../utils/serialize.js";

export const router = express.Router();

export async function buildState(userId) {
  const user = await User.findById(userId);
  const [activities, healthLogs, goals, reminders, tips] = await Promise.all([
    Activity.find({ userId }).sort({ date: -1 }),
    HealthLog.find({ userId }).sort({ date: 1 }),
    Goal.find({ userId }).sort({ createdAt: -1 }),
    Reminder.find({ userId }).sort({ createdAt: -1 }),
    Tip.find({}).sort({ createdAt: 1 }),
  ]);

  return {
    user: toClient(user),
    activities: listToClient(activities),
    healthLogs: listToClient(healthLogs),
    goals: listToClient(goals),
    reminders: listToClient(reminders),
    tips: listToClient(tips),
  };
}

router.get("/", async (req, res) => {
  try {
    const state = await buildState(req.userId);
    return res.json(state);
  } catch (err) {
    return res.status(500).json({ error: "Failed to load data" });
  }
});
