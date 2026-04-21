import cors from "cors";
import express from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import mongoose from "mongoose";
import morgan from "morgan";

import { config } from "./config.js";
import { auth } from "./middleware/auth.js";
import { errorHandler } from "./middleware/error_handler.js";
import { router as activitiesRouter } from "./routes/activities.js";
import { router as authRouter } from "./routes/auth.js";
import { router as goalsRouter } from "./routes/goals.js";
import { router as healthLogsRouter } from "./routes/healthLogs.js";
import { router as profileRouter } from "./routes/profile.js";
import { router as remindersRouter } from "./routes/reminders.js";
import { router as syncRouter } from "./routes/sync.js";
import { router as tipsRouter } from "./routes/tips.js";
import { Tip } from "./models/Tip.js";
import { logInfo } from "./utils/logger.js";

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 200,
  standardHeaders: "draft-7",
  legacyHeaders: false,
});
app.use("/api", apiLimiter);

app.get("/api/health", (_req, res) => res.json({ status: "ok" }));

app.use("/api/auth", authRouter);
app.use("/api/sync", auth, syncRouter);
app.use("/api/profile", auth, profileRouter);
app.use("/api/activities", auth, activitiesRouter);
app.use("/api/health-logs", auth, healthLogsRouter);
app.use("/api/goals", auth, goalsRouter);
app.use("/api/reminders", auth, remindersRouter);
app.use("/api/tips", auth, tipsRouter);

app.use(errorHandler);

async function seedTips() {
  const count = await Tip.countDocuments();
  if (count > 0) return;
  await Tip.insertMany([
    {
      title: "Stay Hydrated",
      category: "Hydration",
      summary: "Aim for regular water intake throughout the day.",
      content:
        "Hydration supports circulation, temperature regulation, and exercise performance. Start the day with water and keep a bottle nearby.",
      source: "Wellness Hub Editorial",
    },
    {
      title: "Build Small Daily Movement",
      category: "Fitness",
      summary: "Short walks and stretching sessions improve consistency.",
      content:
        "Instead of waiting for a perfect workout, stack 10 to 15 minute movement blocks. Consistency drives better long-term health outcomes.",
      source: "Wellness Hub Editorial",
    },
    {
      title: "Protect Your Sleep Window",
      category: "Sleep",
      summary: "Sleep quality directly affects recovery and appetite control.",
      content:
        "Try a consistent wind-down routine, reduce late caffeine, and keep screens lower before sleep to improve recovery and mood.",
      source: "Wellness Hub Editorial",
    },
    {
      title: "Use Goals You Can Measure",
      category: "Productivity",
      summary: "Specific, measurable goals improve adherence.",
      content:
        "Choose goals like 8,000 steps per day or 4 workouts this week instead of vague goals. Measuring progress keeps motivation visible.",
      source: "Wellness Hub Editorial",
    },
  ]);
  // eslint-disable-next-line no-console
  console.log("Seeded default tips");
}

async function start() {
  try {
    await mongoose.connect(config.mongoUri, { dbName: "wellness_hub" });
    await seedTips();
    app.listen(config.port, () => {
      logInfo("api_ready", { port: config.port });
    });
  } catch (err) {
    logInfo("api_start_failed", { error: err?.message || String(err) });
    process.exit(1);
  }
}

start();
