import mongoose from "mongoose";

const goalSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    title: { type: String, required: true },
    goalType: { type: String, required: true },
    targetValue: { type: Number, required: true },
    currentValue: { type: Number, required: true },
    startDate: { type: Date, required: true },
    targetDate: { type: Date, required: true },
    status: { type: String, enum: ["active", "completed"], default: "active" },
  },
  { timestamps: true },
);

export const Goal = mongoose.model("Goal", goalSchema);
