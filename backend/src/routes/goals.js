import express from "express";

import { Goal } from "../models/Goal.js";
import { listToClient, toClient } from "../utils/serialize.js";

export const router = express.Router();

router.get("/", async (req, res) => {
  const goals = await Goal.find({ userId: req.userId }).sort({ createdAt: -1 });
  return res.json({ goals: listToClient(goals) });
});

router.post("/", async (req, res) => {
  try {
    const { title, goalType, targetValue, currentValue, targetDate } = req.body;
    const status = currentValue >= targetValue ? "completed" : "active";
    const goal = await Goal.create({
      userId: req.userId,
      title,
      goalType,
      targetValue,
      currentValue,
      startDate: new Date(),
      targetDate: new Date(targetDate),
      status,
    });
    return res.status(201).json({ goal: toClient(goal) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to add goal" });
  }
});

router.patch("/:id", async (req, res) => {
  try {
    const { currentValue } = req.body;
    const goal = await Goal.findOne({ _id: req.params.id, userId: req.userId });
    if (!goal) return res.status(404).json({ error: "Goal not found" });

    goal.currentValue = currentValue;
    goal.status = currentValue >= goal.targetValue ? "completed" : "active";
    await goal.save();

    return res.json({ goal: toClient(goal) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to update goal" });
  }
});
