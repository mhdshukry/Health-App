export function logInfo(message, meta = {}) {
  // eslint-disable-next-line no-console
  console.log(JSON.stringify({ level: "info", message, ...meta }));
}

export function logWarn(message, meta = {}) {
  // eslint-disable-next-line no-console
  console.warn(JSON.stringify({ level: "warn", message, ...meta }));
}

export function logError(message, meta = {}) {
  // eslint-disable-next-line no-console
  console.error(JSON.stringify({ level: "error", message, ...meta }));
}
