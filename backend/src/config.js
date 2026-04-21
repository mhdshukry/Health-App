import dotenv from "dotenv";

dotenv.config();

export const config = {
  port: process.env.PORT || 4000,
  mongoUri: process.env.MONGO_URI || "mongodb://localhost:27017/wellness_hub",
  jwtSecret: process.env.JWT_SECRET || "change-me",
  refreshJwtSecret: process.env.JWT_REFRESH_SECRET || "change-me-refresh",
  accessTokenTtl: process.env.JWT_ACCESS_TTL || "15m",
  refreshTokenTtl: process.env.JWT_REFRESH_TTL || "30d",
  smtpHost: process.env.SMTP_HOST || "",
  smtpPort: Number(process.env.SMTP_PORT || 587),
  smtpUser: process.env.SMTP_USER || "",
  smtpPass: process.env.SMTP_PASS || "",
  smtpFrom: process.env.SMTP_FROM || "no-reply@wellness-hub.local",
  appBaseUrl: process.env.APP_BASE_URL || "http://localhost:3000",
};
