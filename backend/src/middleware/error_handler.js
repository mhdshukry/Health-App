import { logError } from "../utils/logger.js";

export function errorHandler(err, _req, res, _next) {
  const status = err.statusCode || err.status || 500;
  const message = err.expose
    ? err.message
    : status >= 500
      ? "Internal server error"
      : err.message || "Request failed";

  logError("request_failed", {
    status,
    message: err.message,
  });

  return res.status(status).json({ error: message });
}
