// routes/meals.js
import express from "express";
import { saveParsedMeal, syncMeals } from "../controllers/mealController.js";
import { authMiddleware } from "../middleware/authMiddleware.js";

const router = express.Router();

// single save (app->save)
router.post("/save", authMiddleware, saveParsedMeal);

// batch sync: client uploads queued records
router.post("/sync", authMiddleware, syncMeals);

export default router;
