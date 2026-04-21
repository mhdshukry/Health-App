import express from "express";

import { Activity } from "../models/Activity.js";
import { listToClient, toClient } from "../utils/serialize.js";

export const router = express.Router();

router.get("/", async (req, res) => {
  const activities = await Activity.find({ userId: req.userId }).sort({
    date: -1,
  });
  return res.json({ activities: listToClient(activities) });
});

router.post("/", async (req, res) => {
  try {
    const { type, duration, steps, distance, calories, notes, date } = req.body;
    const activity = await Activity.create({
      userId: req.userId,
      type,
      duration,
      steps,
      distance,
      calories,
      notes: notes || "",
      date: date ? new Date(date) : new Date(),
    });
    return res.status(201).json({ activity: toClient(activity) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to add activity" });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    await Activity.deleteOne({ _id: req.params.id, userId: req.userId });
    return res.json({ success: true });
  } catch (err) {
    return res.status(500).json({ error: "Failed to delete activity" });
  }
});
