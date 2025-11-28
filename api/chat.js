import { getOpenRouterConfig, getHuggingFaceConfig } from './utils/apiConfig.js';

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,OPTIONS,PATCH,DELETE,POST,PUT');
  res.setHeader('Access-Control-Allow-Headers', 'X-CSRF-Token, X-Requested-With, Accept, Accept-Version, Content-Length, Content-MD5, Content-Type, Date, X-Api-Version');

  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

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

  try {
    const { message, chatHistory = [], model = 'google/gemini-flash-1.5' } = body; // Default model

    if (!message) {
      return res.status(400).json({ error: 'Message is required' });
    }

    const openRouterConfig = getOpenRouterConfig();
    
    const messages = [
      {
        role: 'system',
        content: `You are a helpful food and cooking assistant. You help with recipes, cooking techniques, 
        ingredient substitutions, nutritional advice, and general cooking questions. Be friendly, informative, 
        and provide practical advice.`
      },
      ...chatHistory,
      {
        role: 'user',
        content: message
      }
    ];

    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterConfig.apiKey}`,
        'Content-Type': 'application/json',
        'HTTP-Referer': openRouterConfig.referer,
        'X-Title': openRouterConfig.title
      },
      body: JSON.stringify({
        model: model, // Use the selected model
        messages: messages,
        max_tokens: 1000,
        temperature: 0.7
      })
    });

    if (!response.ok) {
      throw new Error(`OpenRouter API error: ${response.status}`);
    }

    const data = await response.json();
    const assistantMessage = data.choices[0].message.content;

    res.status(200).json({
      success: true,
      response: assistantMessage,
      usage: data.usage
    });

  } catch (error) {
    console.error('Error in chat:', error);
    res.status(500).json({ 
      success: false,
      error: 'Failed to process chat message: ' + error.message 
    });
  }
}