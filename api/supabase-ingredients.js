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
    // PARSE JSON BODY
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
      case 'getIngredients':
        return await handleGetIngredients(req, res, data);
      case 'addIngredient':
        return await handleAddIngredient(req, res, data);
      case 'removeIngredient':
        return await handleRemoveIngredient(req, res, data);
      case 'updateIngredient':
        return await handleUpdateIngredient(req, res, data);
      case 'searchIngredients':
        return await handleSearchIngredients(req, res, data);
      default:
        return res.status(400).json({ 
          success: false,
          error: 'Invalid action specified' 
        });
    }
  } catch (error) {
    console.error('Supabase ingredients API error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error: ' + error.message 
    });
  }
}

// ADD THIS MISSING FUNCTION - THIS WAS THE PROBLEM
async function handleGetIngredients(req, res, data) {
  const { userId } = data;

  if (!userId) {
    return res.status(400).json({ error: 'UserId is required' });
  }

  const { data: result, error } = await supabase
    .from('ingredients')
    .select('*')
    .eq('user_id', userId)
    .order('name', { ascending: true });

  if (error) throw error;

  res.status(200).json({
    success: true,
    ingredients: result || [],
  });
}

async function handleAddIngredient(req, res, data) {
  const { name, category, unit, userId } = data;

  if (!name || !userId) {
    return res.status(400).json({ error: 'Name and userId are required' });
  }

  const { data: result, error } = await supabase
    .from('ingredients')
    .insert({
      name: name.toLowerCase().trim(),
      category: category || 'other',
      unit: unit || 'unit',
      user_id: userId,
      created_at: new Date().toISOString(),
    })
    .select();

  if (error) throw error;

  res.status(200).json({
    success: true,
    ingredient: result[0],
  });
}

async function handleRemoveIngredient(req, res, data) {
  const { ingredientId, userId } = data;

  if (!ingredientId || !userId) {
    return res.status(400).json({ error: 'IngredientId and userId are required' });
  }

  const { error } = await supabase
    .from('ingredients')
    .delete()
    .eq('id', ingredientId)
    .eq('user_id', userId);

  if (error) throw error;

  res.status(200).json({
    success: true,
    message: 'Ingredient removed successfully',
  });
}

async function handleUpdateIngredient(req, res, data) {
  const { ingredientId, userId, name, category } = data;

  if (!ingredientId || !userId) {
    return res.status(400).json({ error: 'IngredientId and userId are required' });
  }

  const updateData = {};
  if (name) updateData.name = name.toLowerCase().trim();
  if (category) updateData.category = category;
  updateData.updated_at = new Date().toISOString();

  const { data: result, error } = await supabase
    .from('ingredients')
    .update(updateData)
    .eq('id', ingredientId)
    .eq('user_id', userId)
    .select();

  if (error) throw error;

  res.status(200).json({
    success: true,
    ingredient: result[0],
  });
}

async function handleSearchIngredients(req, res, data) {
  const { query, userId } = data;

  if (!query || !userId) {
    return res.status(400).json({ error: 'Query and userId are required' });
  }

  const { data: result, error } = await supabase
    .from('ingredients')
    .select('*')
    .ilike('name', `%${query}%`)
    .eq('user_id', userId)
    .order('name', { ascending: true });

  if (error) throw error;

  res.status(200).json({
    success: true,
    ingredients: result || [],
  });
}