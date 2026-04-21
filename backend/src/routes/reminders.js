import express from "express";

import { Reminder } from "../models/Reminder.js";
import { listToClient, toClient } from "../utils/serialize.js";
import { reminderCreateSchema } from "../utils/validation.js";

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
  const reminders = await Reminder.find({ userId: req.userId }).sort({
    createdAt: -1,
  });
  return res.json({ reminders: listToClient(reminders) });
});

router.post("/", async (req, res) => {
  try {
    const parsed = parseOrError(reminderCreateSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });

    const { title, message, scheduledTime, repeat } = parsed.data;
    const reminder = await Reminder.create({
      userId: req.userId,
      title,
      message,
      scheduledTime,
      repeat,
      isActive: true,
    });
    return res.status(201).json({ reminder: toClient(reminder) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to add reminder" });
  }
});

router.patch("/:id/toggle", async (req, res) => {
  try {
    const reminder = await Reminder.findOne({
      _id: req.params.id,
      userId: req.userId,
    });
    if (!reminder) return res.status(404).json({ error: "Reminder not found" });
    reminder.isActive = !reminder.isActive;
    await reminder.save();
    return res.json({ reminder: toClient(reminder) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to toggle reminder" });
  }
});
