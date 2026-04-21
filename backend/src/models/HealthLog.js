import mongoose from "mongoose";

const healthLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    weight: { type: Number, required: true },
    height: { type: Number, required: true },
    bmi: { type: Number, required: true },
    notes: { type: String, default: "" },
    date: { type: Date, required: true },
  },
  { timestamps: true },
);

export const HealthLog = mongoose.model("HealthLog", healthLogSchema);
