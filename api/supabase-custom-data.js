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
      case 'getCustomCuisines':
        return await handleGetCustomCuisines(req, res, data);
      case 'getCustomAppliances':
        return await handleGetCustomAppliances(req, res, data);
      case 'addCustomCuisine':
        return await handleAddCustomCuisine(req, res, data);
      case 'addCustomAppliance':
        return await handleAddCustomAppliance(req, res, data);
      case 'removeCustomCuisine':
        return await handleRemoveCustomCuisine(req, res, data);
      case 'removeCustomAppliance':
        return await handleRemoveCustomAppliance(req, res, data);
      default:
        return res.status(400).json({ 
          success: false,
          error: 'Invalid action specified' 
        });
    }
  } catch (error) {
    console.error('Supabase custom data API error:', error);
    res.status(500).json({ 
      success: false,
      error: 'Internal server error: ' + error.message 
    });
  }
}

async function handleGetCustomCuisines(req, res, data) {
  const { userId } = data;

  if (!userId) {
    return res.status(400).json({ error: 'UserId is required' });
  }

  const { data: cuisines, error } = await supabase
    .from('custom_cuisines')
    .select('name')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('Error fetching custom cuisines:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    cuisines: cuisines.map(item => item.name) || [],
  });
}

async function handleGetCustomAppliances(req, res, data) {
  const { userId } = data;

  if (!userId) {
    return res.status(400).json({ error: 'UserId is required' });
  }

  const { data: appliances, error } = await supabase
    .from('custom_appliances')
    .select('name')
    .eq('user_id', userId)
    .order('created_at', { ascending: true });

  if (error) {
    console.error('Error fetching custom appliances:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    appliances: appliances.map(item => item.name) || [],
  });
}

async function handleAddCustomCuisine(req, res, data) {
  const { userId, name } = data;

  if (!userId || !name) {
    return res.status(400).json({ error: 'UserId and name are required' });
  }

  const { error } = await supabase
    .from('custom_cuisines')
    .insert({
      user_id: userId,
      name: name
    });

  if (error) {
    console.error('Error adding custom cuisine:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    message: 'Custom cuisine added successfully',
  });
}

async function handleAddCustomAppliance(req, res, data) {
  const { userId, name } = data;

  if (!userId || !name) {
    return res.status(400).json({ error: 'UserId and name are required' });
  }

  const { error } = await supabase
    .from('custom_appliances')
    .insert({
      user_id: userId,
      name: name
    });

  if (error) {
    console.error('Error adding custom appliance:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    message: 'Custom appliance added successfully',
  });
}

async function handleRemoveCustomCuisine(req, res, data) {
  const { userId, name } = data;

  if (!userId || !name) {
    return res.status(400).json({ error: 'UserId and name are required' });
  }

  const { error } = await supabase
    .from('custom_cuisines')
    .delete()
    .eq('user_id', userId)
    .eq('name', name);

  if (error) {
    console.error('Error removing custom cuisine:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    message: 'Custom cuisine removed successfully',
  });
}

async function handleRemoveCustomAppliance(req, res, data) {
  const { userId, name } = data;

  if (!userId || !name) {
    return res.status(400).json({ error: 'UserId and name are required' });
  }

  const { error } = await supabase
    .from('custom_appliances')
    .delete()
    .eq('user_id', userId)
    .eq('name', name);

  if (error) {
    console.error('Error removing custom appliance:', error);
    throw error;
  }

  res.status(200).json({
    success: true,
    message: 'Custom appliance removed successfully',
  });
}