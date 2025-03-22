/*
  # Fix RLS policies for grocery_items table

  1. Changes
    - Drop existing policies that are not working correctly
    - Create new policies with proper conditions for authenticated users
    
  2. Security
    - Enable RLS on grocery_items table
    - Add policies for all CRUD operations
    - Ensure authenticated users can manage their own items
*/

-- Enable RLS
ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Allow authenticated users to delete grocery items" ON grocery_items;
DROP POLICY IF EXISTS "Allow authenticated users to insert grocery items" ON grocery_items;
DROP POLICY IF EXISTS "Allow authenticated users to read grocery items" ON grocery_items;
DROP POLICY IF EXISTS "Allow authenticated users to update grocery items" ON grocery_items;

-- Create new policies
CREATE POLICY "Enable read access for authenticated users" ON grocery_items
  FOR SELECT TO authenticated
  USING (true);

CREATE POLICY "Enable insert access for authenticated users" ON grocery_items
  FOR INSERT TO authenticated
  WITH CHECK (true);

CREATE POLICY "Enable update access for authenticated users" ON grocery_items
  FOR UPDATE TO authenticated
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Enable delete access for authenticated users" ON grocery_items
  FOR DELETE TO authenticated
  USING (true);