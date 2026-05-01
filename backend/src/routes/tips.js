import express from "express";

import { Tip } from "../models/Tip.js";
import { listToClient } from "../utils/serialize.js";

export const router = express.Router();

const MY_HEALTHFINDER_BASE =
  "https://odphp.health.gov/myhealthfinder/api/v4";

router.get("/", async (_req, res) => {
  const tips = await Tip.find({}).sort({ createdAt: 1 });
  return res.json({ tips: listToClient(tips) });
});

router.get("/external", async (_req, res) => {
  try {
    const tips = await fetchMyHealthfinderTips();
    return res.json({ tips });
  } catch (err) {
    const fallback = await Tip.find({}).sort({ createdAt: 1 });
    return res.json({
      tips: listToClient(fallback),
      sourceFallback: true,
      warning: "External health tips API unavailable; returned cached tips.",
    });
  }
});

async function fetchJson(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);
  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) {
      throw new Error(`External API failed with ${response.status}`);
    }
    return response.json();
  } finally {
    clearTimeout(timeout);
  }
}

async function fetchMyHealthfinderTips() {
  const listUrl = `${MY_HEALTHFINDER_BASE}/itemlist.json?Type=topic`;
  const listPayload = await fetchJson(listUrl);
  const rawItems = listPayload?.Result?.Items?.Item;
  const items = Array.isArray(rawItems) ? rawItems.slice(0, 8) : [];

  const details = await Promise.all(
    items.map((item) =>
      fetchJson(`${MY_HEALTHFINDER_BASE}/topicsearch.json?TopicId=${item.Id}`),
    ),
  );

  return details
    .map((payload) => payload?.Result?.Resources?.Resource?.[0])
    .filter(Boolean)
    .map((resource) => {
      const sections = resource?.Sections?.section;
      const firstSection = Array.isArray(sections) ? sections[0] : sections;
      const content = cleanHtml(firstSection?.Content || "");
      const summary = firstSentence(content) || `Learn about ${resource.Title}.`;
      return {
        id: `myhealthfinder-${resource.Id}`,
        title: resource.Title,
        category: resource.Categories || "Health",
        summary,
        content: truncate(content || summary, 420),
        source: "ODPHP MyHealthfinder External API",
      };
    });
}

function cleanHtml(value) {
  return String(value)
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/&nbsp;/g, " ")
    .replace(/&amp;/g, "&")
    .replace(/&quot;/g, '"')
    .replace(/&#39;/g, "'")
    .replace(/\s+/g, " ")
    .trim();
}

function firstSentence(value) {
  const match = value.match(/^(.{40,220}?[.!?])\s/);
  return match ? match[1] : truncate(value, 180);
}

function truncate(value, maxLength) {
  if (value.length <= maxLength) return value;
  return `${value.slice(0, maxLength - 1).trim()}…`;
}
