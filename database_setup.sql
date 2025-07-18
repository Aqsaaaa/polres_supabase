-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create items table
CREATE TABLE IF NOT EXISTS items (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    image TEXT DEFAULT '',
    stock INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create transactions table (history)
CREATE TABLE IF NOT EXISTS transactions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    item_id UUID REFERENCES items(id) ON DELETE CASCADE,
    item_name TEXT NOT NULL,
    borrower_name TEXT NOT NULL,
    responsible_person TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'borrowed' CHECK (status IN ('borrowed', 'returned')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    returned_at TIMESTAMP WITH TIME ZONE
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_items_created_at ON items(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_transactions_item_id ON transactions(item_id);
CREATE INDEX IF NOT EXISTS idx_transactions_status ON transactions(status);
CREATE INDEX IF NOT EXISTS idx_transactions_created_at ON transactions(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE items ENABLE ROW LEVEL SECURITY;
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for users table
CREATE POLICY "Users can view their own profile" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Create RLS policies for items table (allow all authenticated users to read/write)
CREATE POLICY "Authenticated users can view items" ON items
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert items" ON items
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update items" ON items
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can delete items" ON items
    FOR DELETE USING (auth.role() = 'authenticated');

-- Create RLS policies for transactions table
CREATE POLICY "Authenticated users can view transactions" ON transactions
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can insert transactions" ON transactions
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can update transactions" ON transactions
    FOR UPDATE USING (auth.role() = 'authenticated');

-- Create function to decrease stock
CREATE OR REPLACE FUNCTION decrease_stock(item_id UUID, amount INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE items 
    SET stock = stock - amount, updated_at = NOW()
    WHERE id = item_id AND stock >= amount;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item not found or insufficient stock';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create function to increase stock
CREATE OR REPLACE FUNCTION increase_stock(item_id UUID, amount INTEGER)
RETURNS VOID AS $$
BEGIN
    UPDATE items 
    SET stock = stock + amount, updated_at = NOW()
    WHERE id = item_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Item not found';
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_items_updated_at
    BEFORE UPDATE ON items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Insert sample data (optional)
INSERT INTO items (name, image, stock) VALUES 
    ('Laptop Dell Inspiron', 'https://example.com/laptop.jpg', 5),
    ('Proyektor Epson', 'https://example.com/projector.jpg', 3),
    ('Speaker JBL', 'https://example.com/speaker.jpg', 8),
    ('Microphone Shure', 'https://example.com/microphone.jpg', 4)
ON CONFLICT DO NOTHING; 