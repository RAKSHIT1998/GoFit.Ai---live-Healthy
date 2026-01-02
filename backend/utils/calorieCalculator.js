// Calculate recommended calorie intake based on user data
export function calculateCalories(user) {
  const { weightKg, heightCm, activityLevel, goals, age = 30 } = user.metrics || {};
  
  if (!weightKg || !heightCm) {
    return null;
  }

  // Calculate BMR using Mifflin-St Jeor Equation
  // BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5 (for men)
  // BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161 (for women)
  // Using average (assuming gender-neutral calculation)
  const bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;

  // Activity multipliers
  const activityMultipliers = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9
  };

  const multiplier = activityMultipliers[activityLevel] || 1.55;
  let tdee = bmr * multiplier;

  // Adjust based on goals
  const goalAdjustments = {
    lose: -500, // 500 calorie deficit for ~1 lb/week weight loss
    maintain: 0,
    gain: 500  // 500 calorie surplus for ~1 lb/week weight gain
  };

  const adjustment = goalAdjustments[goals] || 0;
  const recommendedCalories = Math.round(tdee + adjustment);

  return {
    bmr: Math.round(bmr),
    tdee: Math.round(tdee),
    recommendedCalories,
    goal: goals || 'maintain',
    activityLevel: activityLevel || 'moderate'
  };
}

// Calculate calories based on target weight (for goal-based planning)
export function calculateCaloriesForTargetWeight(user, targetWeightKg) {
  const { heightCm, activityLevel, goals, age = 30 } = user.metrics || {};
  const currentWeight = user.metrics?.weightKg || 70;
  
  if (!heightCm || !targetWeightKg) {
    return null;
  }

  // Use target weight for BMR calculation
  const bmr = (10 * targetWeightKg) + (6.25 * heightCm) - (5 * age) + 5;

  // Activity multipliers
  const activityMultipliers = {
    sedentary: 1.2,
    light: 1.375,
    moderate: 1.55,
    active: 1.725,
    very_active: 1.9
  };

  const multiplier = activityMultipliers[activityLevel] || 1.55;
  let tdee = bmr * multiplier;

  // Adjust based on goals - but consider the weight difference
  const weightDifference = targetWeightKg - currentWeight;
  let adjustment = 0;
  
  if (goals === 'lose' && weightDifference < 0) {
    // Want to lose weight - create deficit
    adjustment = -500; // 500 calorie deficit for ~1 lb/week
  } else if (goals === 'gain' && weightDifference > 0) {
    // Want to gain weight - create surplus
    adjustment = 500; // 500 calorie surplus for ~1 lb/week
  } else if (goals === 'maintain') {
    // Maintain current weight
    adjustment = 0;
  } else {
    // If goal doesn't match weight difference, adjust accordingly
    if (weightDifference < 0) {
      adjustment = -500; // Need to lose
    } else if (weightDifference > 0) {
      adjustment = 500; // Need to gain
    }
  }

  const recommendedCalories = Math.round(tdee + adjustment);

  return {
    bmr: Math.round(bmr),
    tdee: Math.round(tdee),
    recommendedCalories,
    goal: goals || 'maintain',
    activityLevel: activityLevel || 'moderate',
    targetWeight: targetWeightKg,
    currentWeight: currentWeight,
    weightDifference: Math.round(weightDifference * 10) / 10
  };
}

// Calculate recommended macros based on calories and preferences
export function calculateMacros(calories, dietaryPreferences = []) {
  let proteinPercent = 0.25; // 25% default
  let carbsPercent = 0.45;  // 45% default
  let fatPercent = 0.30;    // 30% default

  // Adjust based on dietary preferences
  if (dietaryPreferences.includes('keto') || dietaryPreferences.includes('low_carb')) {
    proteinPercent = 0.25;
    carbsPercent = 0.10;
    fatPercent = 0.65;
  } else if (dietaryPreferences.includes('paleo')) {
    proteinPercent = 0.30;
    carbsPercent = 0.30;
    fatPercent = 0.40;
  } else if (dietaryPreferences.includes('high_protein')) {
    proteinPercent = 0.35;
    carbsPercent = 0.40;
    fatPercent = 0.25;
  }

  // Calculate grams (1g protein = 4 cal, 1g carbs = 4 cal, 1g fat = 9 cal)
  const proteinGrams = Math.round((calories * proteinPercent) / 4);
  const carbsGrams = Math.round((calories * carbsPercent) / 4);
  const fatGrams = Math.round((calories * fatPercent) / 9);

  return {
    protein: proteinGrams,
    carbs: carbsGrams,
    fat: fatGrams,
    proteinPercent: Math.round(proteinPercent * 100),
    carbsPercent: Math.round(carbsPercent * 100),
    fatPercent: Math.round(fatPercent * 100)
  };
}

