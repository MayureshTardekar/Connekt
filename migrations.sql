-- Migration to add is_archived to chat_conversations
ALTER TABLE chat_conversations
ADD COLUMN IF NOT EXISTS is_archived BOOLEAN DEFAULT false;
