-- Add payment slip URL column to carts table
-- Run this in Supabase SQL editor.

ALTER TABLE public.carts
ADD COLUMN IF NOT EXISTS payment_slip_url text;

COMMENT ON COLUMN public.carts.payment_slip_url IS 'Public URL of uploaded payment slip image';
