import { createSupabaseClient } from './utils/apiConfig.js';

const supabase = createSupabaseClient();

export default async function handler(req, res) {
  // Set CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  // Handle OPTIONS request for CORS
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  // Check method
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Parse JSON body
    let body = req.body;
    if (typeof body === 'string') {
      try {
        body = JSON.parse(body);
      } catch (parseError) {
        return res.status(400).json({
          success: false,
          error: 'Invalid JSON in request body'
        });
      }
    }

    const { action, ...data } = body;

    if (!action) {
      return res.status(400).json({
        success: false,
        error: 'Action parameter is required'
      });
    }

    switch (action) {
      case 'getRecipes':
        return await handleGetRecipes(req, res, data);
      case 'saveRecipe':
        return await handleSaveRecipe(req, res, data);
      case 'removeRecipe':
        return await handleRemoveRecipe(req, res, data);
      default:
        return res.status(400).json({ 
          success: false,
          error: 'Invalid action specified' 
        });
    }
  } catch (error) {
    console.error('Supabase recipes API error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error: ' + error.message 
    });
  }
}

async function handleGetRecipes(req, res, data) {
  const { userId } = data;

  if (!userId) {
    return res.status(400).json({ error: 'UserId is required' });
  }

  const { data: recipes, error } = await supabase
    .from('recipes')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });

  if (error) {
    console.error('Error fetching recipes:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    recipes: recipes || [],
  });
}

async function handleSaveRecipe(req, res, data) {
  const { userId, recipe } = data;

  if (!userId || !recipe) {
    return res.status(400).json({ error: 'UserId and recipe are required' });
  }

  // Prepare recipe data for Supabase
  const recipeData = {
  user_id: userId,
  title: recipe.title || 'Untitled Recipe',
  description: recipe.description,
  ingredients: recipe.ingredients || [],
  instructions: recipe.instructions || [],
  cooking_time: recipe.cookingTime,
  difficulty: recipe.difficulty,
  cuisine: recipe.cuisine,
  meal_type: recipe.mealType,
};

  const { data: savedRecipe, error } = await supabase
    .from('recipes')
    .insert(recipeData)
    .select();

  if (error) {
    console.error('Error saving recipe:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    recipe: savedRecipe[0],
  });
}

async function handleRemoveRecipe(req, res, data) {
  const { userId, recipeId } = data;

  if (!userId || !recipeId) {
    return res.status(400).json({ error: 'UserId and recipeId are required' });
  }

  const { error } = await supabase
    .from('recipes')
    .delete()
    .eq('id', recipeId)
    .eq('user_id', userId);

  if (error) {
    console.error('Error removing recipe:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    message: 'Recipe removed successfully',
  });
}