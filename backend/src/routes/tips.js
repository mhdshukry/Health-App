import express from "express";

import { Tip } from "../models/Tip.js";
import { listToClient } from "../utils/serialize.js";

export const router = express.Router();

router.get("/", async (_req, res) => {
  const tips = await Tip.find({}).sort({ createdAt: 1 });
  return res.json({ tips: listToClient(tips) });
});
