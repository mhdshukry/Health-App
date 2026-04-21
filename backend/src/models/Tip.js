import mongoose from "mongoose";

const tipSchema = new mongoose.Schema(
  {
    title: { type: String, required: true },
    category: { type: String, required: true },
    summary: { type: String, required: true },
    content: { type: String, required: true },
    source: { type: String, required: true },
  },
  { timestamps: true },
);

export const Tip = mongoose.model("Tip", tipSchema);
