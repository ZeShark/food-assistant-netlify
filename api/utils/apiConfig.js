// API configuration utility
import { createClient } from '@supabase/supabase-js';

// Supabase configuration
export function getSupabaseConfig() {
  return {
    url: process.env.SUPABASE_URL,
    key: process.env.SUPABASE_ANON_KEY
  };
}

// Create and export Supabase client instance
export function createSupabaseClient() {
  const config = getSupabaseConfig();
  return createClient(config.url, config.key);
}

// OpenRouter configuration
export function getOpenRouterConfig() {
  return {
    apiKey: process.env.OPENROUTER_API_KEY,
    referer: process.env.OPENROUTER_REFERER || 'https://food-assistant.vercel.app',
    title: process.env.OPENROUTER_TITLE || 'Food Assistant'
  };
}

// HuggingFace configuration
export function getHuggingFaceConfig() {
  return {
    apiKey: process.env.HUGGINGFACE_API_KEY
  };
}

// Validate all required environment variables
export function validateEnvironment() {
  const errors = [];
  
  if (!process.env.SUPABASE_URL) errors.push('SUPABASE_URL is required');
  if (!process.env.SUPABASE_ANON_KEY) errors.push('SUPABASE_ANON_KEY is required');
  if (!process.env.OPENROUTER_API_KEY) errors.push('OPENROUTER_API_KEY is required');
  
  return errors;
}