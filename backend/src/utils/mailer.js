import nodemailer from "nodemailer";

import { config } from "../config.js";

let cachedTransport = null;

function getTransport() {
  if (cachedTransport) return cachedTransport;
  if (!config.smtpHost || !config.smtpUser || !config.smtpPass) {
    return null;
  }

  cachedTransport = nodemailer.createTransport({
    host: config.smtpHost,
    port: config.smtpPort,
    secure: config.smtpPort === 465,
    auth: {
      user: config.smtpUser,
      pass: config.smtpPass,
    },
  });

  return cachedTransport;
}

export async function sendPasswordResetEmail({ to, token }) {
  const transport = getTransport();
  if (!transport) return false;

  const resetUrl = `${config.appBaseUrl}/password-reset?token=${token}`;

  await transport.sendMail({
    from: config.smtpFrom,
    to,
    subject: "Reset your Wellness Hub password",
    text: `Use this link to reset your password: ${resetUrl}`,
  });

  return true;
}
