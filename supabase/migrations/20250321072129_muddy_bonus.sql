/*
  # Create Grocery Items Table

  1. New Tables
    - `grocery_items`
      - `id` (bigint, primary key)
      - `item` (text, not null)
      - `quantity` (numeric, not null)
      - `unit` (text, not null)
      - `is_selected` (boolean, default false)
      - `created_at` (timestamp with time zone, default now())

  2. Security
    - Enable RLS on `grocery_items` table
    - Add policies for authenticated users to perform all operations
*/

CREATE TABLE IF NOT EXISTS grocery_items (
  id bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
  item text NOT NULL,
  quantity numeric NOT NULL,
  unit text NOT NULL,
  is_selected boolean DEFAULT false,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE grocery_items ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated users to read grocery items
CREATE POLICY "Allow authenticated users to read grocery items"
  ON grocery_items
  FOR SELECT
  TO authenticated
  USING (true);

-- Allow all authenticated users to insert grocery items
CREATE POLICY "Allow authenticated users to insert grocery items"
  ON grocery_items
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Allow all authenticated users to update grocery items
CREATE POLICY "Allow authenticated users to update grocery items"
  ON grocery_items
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- Allow all authenticated users to delete grocery items
CREATE POLICY "Allow authenticated users to delete grocery items"
  ON grocery_items
  FOR DELETE
  TO authenticated
  USING (true);