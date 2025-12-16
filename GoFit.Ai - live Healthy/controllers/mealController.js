// controllers/mealController.js
import Meal from "../models/Meal.js";

/**
 * Save corrected meal (single meal).
 * Expected body:
 * { userId?, imageUrl?, items: [ { name, qtyText, calories, protein, carbs, fat } ], recommendations? }
 */
export const saveParsedMeal = async (req, res) => {
  try {
    const { userId, imageUrl, items, recommendations } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ message: "items required" });
    }

    const meal = await Meal.create({
      userId: userId || (req.user?._id),
      imageUrl: imageUrl || null,
      parsedItems: items,
      recommendations: recommendations || null,
      source: req.body.source || "app",
      synced: true
    });

    return res.status(201).json({
      mealId: meal._id,
      parsedItems: meal.parsedItems,
      recommendations: meal.recommendations
    });
  } catch (err) {
    console.error("saveParsedMeal", err);
    return res.status(500).json({ message: "Server error", error: err.message });
  }
};

/**
 * Batch sync endpoint: accepts an array of queued meals (from offline)
 * Body:
 * { records: [ { clientId, timestamp, imageUrl?, items: [...] , recommendations? } ] }
 * returns mapping of clientId -> saved mealId so client can mark as synced.
 */
export const syncMeals = async (req, res) => {
  try {
    const { records } = req.body;
    if (!Array.isArray(records) || records.length === 0) {
      return res.status(400).json({ message: "records array required" });
    }

    const results = [];
    for (const rec of records) {
      const items = rec.items || [];
      if (!items.length) {
        results.push({ clientId: rec.clientId, error: "no items" });
        continue;
      }
      const meal = await Meal.create({
        userId: rec.userId || (req.user?._id),
        timestamp: rec.timestamp ? new Date(rec.timestamp) : new Date(),
        imageUrl: rec.imageUrl || null,
        parsedItems: items,
        recommendations: rec.recommendations || null,
        source: "batch-sync",
        synced: true,
        rawAiResponse: rec.rawAiResponse || null
      });
      results.push({ clientId: rec.clientId, mealId: meal._id });
    }

    return res.json({ synced: results });
  } catch (err) {
    console.error("syncMeals", err);
    return res.status(500).json({ message: "Server error", error: err.message });
  }
};
