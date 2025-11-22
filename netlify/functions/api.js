// netlify/functions/api.js
import { createClient } from '@supabase/supabase-js';
import axios from 'axios';

// Initialize Supabase
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_KEY
);

// In-memory storage for conversation
let conversationHistory = [];
let providerUsage = {
  openrouter: { used_today: 0, daily_limit: 100 }
};

// Helper function for JSON responses
function jsonResponse(statusCode, data) {
  return {
    statusCode,
    headers: { 
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS'
    },
    body: JSON.stringify(data)
  };
}

// === INGREDIENT HANDLERS ===
async function handleGetIngredients() {
  const { data, error } = await supabase
    .from('ingredients')
    .select('*')
    .order('added_date', { ascending: false });
  
  if (error) throw error;
  
  return jsonResponse(200, { 
    success: true,
    ingredients: data 
  });
}

async function handleAddIngredient(body) {
  const { name, category, quantity, unit } = body;
  
  if (!name) {
    return jsonResponse(400, { error: 'Ingredient name is required' });
  }

  const { data, error } = await supabase
    .from('ingredients')
    .insert([{
      name: name.toLowerCase().trim(),
      category: category || 'uncategorized',
      quantity: quantity || 1,
      unit: unit || 'unit'
    }])
    .select()
    .single();

  if (error) throw error;

  return jsonResponse(200, { 
    success: true, 
    ingredient: data,
    message: `Added ${name} to your ingredients`
  });
}

async function handleUpdateIngredient(id, body) {
  const { name, category } = body;
  
  const { data, error } = await supabase
    .from('ingredients')
    .update({
      ...(name && { name: name.toLowerCase().trim() }),
      ...(category && { category })
    })
    .eq('id', id)
    .select()
    .single();

  if (error) throw error;
  if (!data) {
    return jsonResponse(404, { error: 'Ingredient not found' });
  }

  return jsonResponse(200, { 
    success: true, 
    ingredient: data 
  });
}

async function handleImportIngredients(body) {
  const { ingredients } = body;
  
  if (!ingredients || !Array.isArray(ingredients)) {
    return jsonResponse(400, { error: 'Ingredients array is required' });
  }

  const imported = [];
  const errors = [];

  for (const ing of ingredients) {
    if (!ing.name) {
      errors.push('Ingredient missing name');
      continue;
    }

    try {
      const { data, error } = await supabase
        .from('ingredients')
        .insert([{
          name: ing.name.toLowerCase().trim(),
          category: ing.category || 'uncategorized',
          quantity: ing.quantity || 1,
          unit: ing.unit || 'unit'
        }])
        .select()
        .single();

      if (error) {
        errors.push(`Failed to add ${ing.name}: ${error.message}`);
      } else {
        imported.push(data);
      }
    } catch (e) {
      errors.push(`Failed to add ${ing.name}: ${e.message}`);
    }
  }

  return jsonResponse(200, { 
    success: true, 
    imported: imported,
    errors: errors,
    message: `Imported ${imported.length} ingredients successfully`
  });
}

async function handleDeleteIngredient(id) {
  const { error } = await supabase
    .from('ingredients')
    .delete()
    .eq('id', id);

  if (error) throw error;

  return jsonResponse(200, { 
    success: true, 
    message: 'Ingredient removed successfully' 
  });
}

async function handleClearIngredients() {
  const { count, error } = await supabase
    .from('ingredients')
    .delete()
    .neq('id', 0);

  if (error) throw error;

  return jsonResponse(200, { 
    success: true, 
    message: `Cleared all ${count} ingredients` 
  });
}

async function handleSearchIngredients(query) {
  const { data, error } = await supabase
    .from('ingredients')
    .select('*')
    .ilike('name', `%${query}%`)
    .order('name');

  if (error) throw error;

  return jsonResponse(200, { 
    success: true,
    ingredients: data 
  });
}

async function handleGetIngredientsByCategory(category) {
  const { data, error } = await supabase
    .from('ingredients')
    .select('*')
    .eq('category', category)
    .order('name');

  if (error) throw error;

  return jsonResponse(200, { 
    success: true,
    ingredients: data 
  });
}

// === AI HANDLERS ===
async function handleAIRequest(userMessage) {
  const recentMessages = conversationHistory.slice(-6);
  const messages = [
    { 
      role: 'system', 
      content: `You are a helpful food and cooking assistant. Help with recipes, ingredient management, food storage tips, expiration dates, freezer advice, and cooking suggestions. Be practical and concise. Focus on food-related topics. Always provide a response.`
    },
    ...recentMessages
  ];

  try {
    const response = await axios.post(
      'https://openrouter.ai/api/v1/chat/completions',
      {
        model: 'google/gemma-7b-it:free',
        messages: messages,
        max_tokens: 500
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.OPENROUTER_API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://your-app.netlify.app',
          'X-Title': 'Food Assistant'
        },
        timeout: 30000
      }
    );

    providerUsage.openrouter.used_today++;
    return response.data.choices[0].message.content;
  } catch (error) {
    console.error('AI Request failed:', error.response?.data || error.message);
    throw new Error('AI service unavailable');
  }
}

async function handleRecipeSuggest(body) {
  const { cuisine, diet, time, appliances } = body;
  
  const { data: ingredients, error } = await supabase
    .from('ingredients')
    .select('name');
  
  if (error) throw error;
  
  const ingredientNames = ingredients.map(ing => ing.name);
  
  if (ingredientNames.length === 0) {
    return jsonResponse(400, { error: 'No ingredients available. Add some ingredients first!' });
  }

  let message = `I have these ingredients: ${ingredientNames.join(', ')}. `;
  if (cuisine) message += `I want ${cuisine} cuisine. `;
  if (diet) message += `Dietary preference: ${diet}. `;
  if (time) message += `I have ${time} to cook. `;
  if (appliances && appliances.length > 0) {
    message += `I have these appliances available: ${appliances.join(', ')}. `;
    message += `Please only suggest recipes that can be made with these appliances. `;
  }
  message += `What are 2-3 specific recipes I can make?`;

  try {
    const response = await handleAIRequest(message);
    
    return jsonResponse(200, { 
      success: true,
      ingredients: ingredientNames,
      suggestions: response,
      filters: { cuisine, diet, time, appliances }
    });
  } catch (error) {
    console.error('Recipe suggestion error:', error);
    return jsonResponse(500, { 
      success: false,
      error: 'Failed to get recipe suggestions'
    });
  }
}

async function handleChat(body) {
  const { message } = body;
  
  if (!message) {
    return jsonResponse(400, { error: 'Message is required' });
  }

  conversationHistory.push({ role: 'user', content: message });

  try {
    const response = await handleAIRequest(message);
    conversationHistory.push({ role: 'assistant', content: response });
    conversationHistory = conversationHistory.slice(-10);
    
    return jsonResponse(200, { 
      success: true,
      response: response,
      conversationHistory: conversationHistory
    });
  } catch (error) {
    console.error('Chat error:', error);
    const fallback = "I'm currently having trouble accessing my recipe database. Try asking me about specific ingredients or cooking techniques!";
    conversationHistory.push({ role: 'assistant', content: fallback });
    
    return jsonResponse(200, { 
      success: true,
      response: fallback,
      conversationHistory: conversationHistory
    });
  }
}

// === CONVERSATION HANDLERS ===
async function handleGetConversation() {
  return jsonResponse(200, {
    success: true,
    history: conversationHistory
  });
}

async function handleClearConversation() {
  conversationHistory = [];
  return jsonResponse(200, { 
    success: true,
    message: 'Conversation cleared!' 
  });
}

// === USAGE HANDLERS ===
async function handleGetUsage() {
  return jsonResponse(200, {
    success: true,
    ...providerUsage
  });
}

// Main handler
export async function handler(event) {
  let path = event.path.replace(/\.netlify\/functions\/[^/]+/, '');
  path = path.replace(/^\/api/, ''); // Now this will work
  const segments = path.split('/').filter(e => e);
  
  console.log('🔍 DEBUG ROUTING:');
  console.log('  event.path:', event.path);
  console.log('  cleaned path:', path);
  console.log('  segments:', segments);
  console.log('  method:', event.httpMethod);

  console.log(`📨 ${event.httpMethod} ${path}`);
  
  try {
    // Health check
    if (path === '' || path === '/' || path === '/api' || path === '/api/') {
      return jsonResponse(200, { 
        status: '🍕 Food Assistant API Running on Netlify!',
        database: 'Supabase',
        hosting: 'Netlify'
      });
    }
    
    // === INGREDIENT ENDPOINTS ===
    if (event.httpMethod === 'GET' && segments[0] === 'ingredients') {
      if (segments[1] === 'search' && segments[2]) {
        return await handleSearchIngredients(segments[2]);
      }
      if (segments[1] === 'category' && segments[2]) {
        return await handleGetIngredientsByCategory(segments[2]);
      }
      return await handleGetIngredients();
    }
        
    if (event.httpMethod === 'PUT' && segments[0] === 'ingredients' && segments[1]) {
      return await handleUpdateIngredient(segments[1], JSON.parse(event.body));
    }

    if (event.httpMethod === 'POST' && segments[0] === 'ingredients') {
      if (segments[1] === 'import') {
        return await handleImportIngredients(JSON.parse(event.body));
      }
      return await handleAddIngredient(JSON.parse(event.body));
    }
    
    if (event.httpMethod === 'DELETE' && segments[0] === 'ingredients') {
      if (segments[1]) {
        return await handleDeleteIngredient(segments[1]);
      }
      return await handleClearIngredients();
    }
    
    // === RECIPE & AI ENDPOINTS ===
    if (event.httpMethod === 'POST' && segments[0] === 'recipes' && segments[1] === 'suggest') {
      return await handleRecipeSuggest(JSON.parse(event.body));
    }
    
    if (event.httpMethod === 'POST' && segments[0] === 'chat') {
      return await handleChat(JSON.parse(event.body));
    }
    
    // === CONVERSATION ENDPOINTS ===
    if (event.httpMethod === 'GET' && segments[0] === 'conversation') {
      return await handleGetConversation();
    }
    
    if (event.httpMethod === 'POST' && segments[0] === 'conversation' && segments[1] === 'clear') {
      return await handleClearConversation();
    }
    
    // === USAGE ENDPOINTS ===
    if (event.httpMethod === 'GET' && segments[0] === 'usage') {
      return await handleGetUsage();
    }
    
    return jsonResponse(404, { error: 'Endpoint not found' });
    
  } catch (error) {
    console.error('❌ API Error:', error);
    return jsonResponse(500, { error: error.message || 'Internal server error' });
  }
}