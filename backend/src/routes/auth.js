import bcrypt from "bcryptjs";
import crypto from "crypto";
import express from "express";
import jwt from "jsonwebtoken";

import { config } from "../config.js";
import { auth } from "../middleware/auth.js";
import { buildState } from "./sync.js";
import { User } from "../models/User.js";
import { toClient } from "../utils/serialize.js";
import { sendPasswordResetEmail } from "../utils/mailer.js";
import {
  loginSchema,
  passwordResetConfirmSchema,
  passwordResetRequestSchema,
  refreshSchema,
  registerSchema,
} from "../utils/validation.js";

export const router = express.Router();

function signAccessToken(userId) {
  return jwt.sign({ userId }, config.jwtSecret, {
    expiresIn: config.accessTokenTtl,
  });
}

function signRefreshToken(userId) {
  return jwt.sign({ userId }, config.refreshJwtSecret, {
    expiresIn: config.refreshTokenTtl,
  });
}

function hashRefreshToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

function hashResetToken(token) {
  return crypto.createHash("sha256").update(token).digest("hex");
}

async function issueTokens(userId) {
  const accessToken = signAccessToken(userId);
  const refreshToken = signRefreshToken(userId);

  await User.findByIdAndUpdate(userId, {
    refreshTokenHash: hashRefreshToken(refreshToken),
    refreshTokenIssuedAt: new Date(),
  });

  return { accessToken, refreshToken };
}

function normalizeEmail(email) {
  return email.toLowerCase().trim();
}

function parseOrError(schema, payload) {
  const result = schema.safeParse(payload);
  if (!result.success) {
    const message = result.error.issues[0]?.message || "Invalid input";
    return { error: message };
  }
  return { data: result.data };
}

router.post("/register", async (req, res) => {
  try {
    const parsed = parseOrError(registerSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const { name, email, password, age, gender, height, weight } = parsed.data;

    const normalizedEmail = normalizeEmail(email);
    const exists = await User.findOne({ email: normalizedEmail });
    if (exists) return res.status(409).json({ error: "Email already in use" });

    const hashed = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email: normalizedEmail,
      password: hashed,
      age,
      gender,
      height,
      weight,
    });

    const { accessToken, refreshToken } = await issueTokens(user._id);
    const state = await buildState(user._id);
    return res.status(201).json({ token: accessToken, refreshToken, ...state });
  } catch (err) {
    return res.status(500).json({ error: "Failed to register" });
  }
});

router.post("/login", async (req, res) => {
  try {
    const parsed = parseOrError(loginSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const { email, password } = parsed.data;

    const user = await User.findOne({ email: normalizeEmail(email) });
    if (!user)
      return res.status(401).json({ error: "Invalid email or password" });

    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.status(401).json({ error: "Invalid email or password" });

    const { accessToken, refreshToken } = await issueTokens(user._id);
    const state = await buildState(user._id);
    return res.json({ token: accessToken, refreshToken, ...state });
  } catch (err) {
    return res.status(500).json({ error: "Failed to login" });
  }
});

router.post("/refresh", async (req, res) => {
  try {
    const parsed = parseOrError(refreshSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const { refreshToken } = parsed.data;

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, config.refreshJwtSecret);
    } catch (err) {
      return res
        .status(401)
        .json({ error: "Invalid or expired refresh token" });
    }

    const user = await User.findById(decoded.userId);
    if (!user || !user.refreshTokenHash) {
      return res.status(401).json({ error: "Refresh token revoked" });
    }

    const incomingHash = hashRefreshToken(refreshToken);
    if (incomingHash !== user.refreshTokenHash) {
      return res.status(401).json({ error: "Refresh token mismatch" });
    }

    const { accessToken, refreshToken: newRefreshToken } = await issueTokens(
      user._id,
    );
    return res.json({ token: accessToken, refreshToken: newRefreshToken });
  } catch (err) {
    return res.status(500).json({ error: "Failed to refresh token" });
  }
});

router.post("/logout", auth, async (req, res) => {
  try {
    await User.findByIdAndUpdate(req.userId, {
      refreshTokenHash: null,
      refreshTokenIssuedAt: null,
    });
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: "Failed to logout" });
  }
});

router.post("/password-reset", async (req, res) => {
  try {
    const parsed = parseOrError(passwordResetRequestSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const { email } = parsed.data;

    const user = await User.findOne({ email: normalizeEmail(email) });
    if (!user) {
      return res.json({ ok: true });
    }

    const resetToken = crypto.randomBytes(32).toString("hex");
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000);

    user.passwordResetTokenHash = hashResetToken(resetToken);
    user.passwordResetExpiresAt = expiresAt;
    await user.save();

    const emailSent = await sendPasswordResetEmail({
      to: user.email,
      token: resetToken,
    });

    if (!emailSent) {
      return res.json({ ok: true, resetToken });
    }

    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: "Failed to request password reset" });
  }
});

router.post("/password-reset/confirm", async (req, res) => {
  try {
    const parsed = parseOrError(passwordResetConfirmSchema, req.body);
    if (parsed.error) return res.status(400).json({ error: parsed.error });
    const { token, password } = parsed.data;

    const hashedToken = hashResetToken(token);
    const user = await User.findOne({
      passwordResetTokenHash: hashedToken,
      passwordResetExpiresAt: { $gt: new Date() },
    });

    if (!user) {
      return res.status(400).json({ error: "Invalid or expired reset token" });
    }

    user.password = await bcrypt.hash(password, 10);
    user.passwordResetTokenHash = null;
    user.passwordResetExpiresAt = null;
    await user.save();

    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ error: "Failed to reset password" });
  }
});

router.get("/me", auth, async (req, res) => {
  try {
    const user = await User.findById(req.userId);
    return res.json({ user: toClient(user) });
  } catch (err) {
    return res.status(500).json({ error: "Failed to load profile" });
  }
});
