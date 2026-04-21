import express from "express";

import { Activity } from "../models/Activity.js";
import { listToClient, toClient } from "../utils/serialize.js";
import { activityCreateSchema } from "../utils/validation.js";

export const router = express.Router();

function parseOrError(schema, payload) {
  const result = schema.safeParse(payload);
  if (!result.success) {
    const message = result.error.issues[0]?.message || "Invalid input";
    return { error: message };
  }
  return { data: result.data };
}

router.get("/", async (req, res) => {
  const activities = await Activity.find({ userId: req.userId }).sort({
    date: -1,
  });
  return res.json({ activities: listToClient(activities) });
});

router.post("/", async (req, res) => {
  try {
    const parsed = parseOrError(activityCreateSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });

    const { type, duration, steps, distance, calories, notes, date } =
      parsed.data;
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
