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
  weight: z.number(),
  height: z.number(),
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
