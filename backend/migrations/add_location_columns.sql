-- Add latitude and longitude columns if they don't exist
ALTER TABLE users
ADD COLUMN IF NOT EXISTS latitude DECIMAL(10, 8) NULL,
ADD COLUMN IF NOT EXISTS longitude DECIMAL(11, 8) NULL;

-- Add encrypted location columns if they don't exist
ALTER TABLE users
ADD COLUMN IF NOT EXISTS encrypted_location TEXT NULL,
ADD COLUMN IF NOT EXISTS location_iv VARCHAR(32) NULL,
ADD COLUMN IF NOT EXISTS last_location_update TIMESTAMP NULL;

-- Add indexes if they don't exist
CREATE INDEX IF NOT EXISTS idx_location_update ON users(last_location_update);

-- Update existing locations to encrypted format
UPDATE users 
SET encrypted_location = NULL, 
    location_iv = NULL 
WHERE latitude IS NOT NULL 
  AND longitude IS NOT NULL 
  AND encrypted_location IS NULL; 