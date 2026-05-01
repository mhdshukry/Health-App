import { z } from "zod";

export const registerSchema = z.object({
  name: z.string().trim().min(1, "Name is required"),
  email: z.string().email("Valid email is required"),
  password: z.string().min(8, "Password must be at least 8 characters"),
  age: z.number(),
  gender: z.string().trim().min(1, "Gender is required"),
  height: z.number(),
  weight: z.number(),
});

export const loginSchema = z.object({
  email: z.string().email("Valid email is required"),
  password: z.string().min(1, "Password is required"),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1, "Refresh token is required"),
});

export const passwordResetRequestSchema = z.object({
  email: z.string().email("Valid email is required"),
});

export const passwordResetConfirmSchema = z.object({
  token: z.string().min(1, "Reset token is required"),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

export const profileUpdateSchema = z.object({
  name: z.string().trim().min(1, "Name is required"),
  age: z.number(),
  gender: z.string().trim().min(1, "Gender is required"),
  height: z.number(),
  weight: z.number(),
});

export const activityCreateSchema = z.object({
  type: z.string().trim().min(1, "Type is required"),
  duration: z.number(),
  steps: z.number(),
  distance: z.number(),
  calories: z.number(),
  notes: z.string().optional(),
  date: z.string().datetime().optional(),
});

export const healthLogCreateSchema = z.object({
  weight: z
    .number()
    .min(20, "Weight must be at least 20 kg")
    .max(350, "Weight must be 350 kg or less"),
  height: z
    .number()
    .min(80, "Height must be at least 80 cm")
    .max(250, "Height must be 250 cm or less"),
  notes: z.string().optional(),
  date: z.string().datetime().optional(),
});

export const goalCreateSchema = z.object({
  title: z.string().trim().min(1, "Title is required"),
  goalType: z.string().trim().min(1, "Goal type is required"),
  targetValue: z.number(),
  currentValue: z.number(),
  targetDate: z.string().datetime(),
});

export const goalUpdateSchema = z.object({
  currentValue: z.number(),
});

export const reminderCreateSchema = z.object({
  title: z.string().trim().min(1, "Title is required"),
  message: z.string().trim().min(1, "Message is required"),
  scheduledTime: z.string().min(1, "Scheduled time is required"),
  repeat: z.string().trim().min(1, "Repeat is required"),
});

export const vitalLogCreateSchema = z.object({
  category: z.string().trim().min(1, "Category is required"),
  systolic: z.number().optional(),
  diastolic: z.number().optional(),
  heartRate: z.number().optional(),
  bloodGlucose: z.number().optional(),
  oxygenSaturation: z.number().optional(),
  temperature: z.number().optional(),
  waterMl: z.number().optional(),
  sleepHours: z.number().optional(),
  mood: z.string().optional(),
  painLevel: z.number().optional(),
  notes: z.string().optional(),
  date: z.string().datetime().optional(),
});
