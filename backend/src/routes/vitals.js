import express from "express";

import { VitalLog } from "../models/VitalLog.js";
import { listToClient, toClient } from "../utils/serialize.js";
import { vitalLogCreateSchema } from "../utils/validation.js";

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
  const vitals = await VitalLog.find({ userId: req.userId }).sort({ date: -1 });
  return res.json({ vitals: listToClient(vitals) });
});

router.post("/", async (req, res) => {
  try {
    const parsed = parseOrError(vitalLogCreateSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });

    const vital = await VitalLog.create({
      userId: req.userId,
      ...parsed.data,
      notes: parsed.data.notes || "",
      date: parsed.data.date ? new Date(parsed.data.date) : new Date(),
    });

    return res.status(201).json({ vital: toClient(vital) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to add vital log" });
  }
});
