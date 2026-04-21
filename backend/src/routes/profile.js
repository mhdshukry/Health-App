import express from "express";

import { User } from "../models/User.js";
import { toClient } from "../utils/serialize.js";
import { profileUpdateSchema } from "../utils/validation.js";

export const router = express.Router();

function parseOrError(schema, payload) {
  const result = schema.safeParse(payload);
  if (!result.success) {
    const message = result.error.issues[0]?.message || "Invalid input";
    return { error: message };
  }
  return { data: result.data };
}

router.put("/", async (req, res) => {
  try {
    const parsed = parseOrError(profileUpdateSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const { name, age, gender, height, weight } = parsed.data;
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
