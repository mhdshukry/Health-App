import mongoose from "mongoose";

const activitySchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    type: { type: String, required: true },
    duration: { type: Number, required: true },
    steps: { type: Number, required: true },
    distance: { type: Number, required: true },
    calories: { type: Number, required: true },
    notes: { type: String, default: "" },
    date: { type: Date, required: true },
  },
  { timestamps: true },
);

export const Activity = mongoose.model("Activity", activitySchema);
