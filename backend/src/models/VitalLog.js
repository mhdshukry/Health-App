import mongoose from "mongoose";

const vitalLogSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    category: { type: String, required: true },
    systolic: { type: Number },
    diastolic: { type: Number },
    heartRate: { type: Number },
    bloodGlucose: { type: Number },
    oxygenSaturation: { type: Number },
    temperature: { type: Number },
    waterMl: { type: Number },
    sleepHours: { type: Number },
    mood: { type: String },
    painLevel: { type: Number },
    notes: { type: String, default: "" },
    date: { type: Date, required: true },
  },
  { timestamps: true },
);

export const VitalLog = mongoose.model("VitalLog", vitalLogSchema);
