-- เพิ่ม field ใหม่สำหรับข้อมูลการจัดส่งในตาราง cart_items

-- 1. เพิ่ม field shipped_by (จัดส่งโดย)
ALTER TABLE cart_items 
ADD COLUMN IF NOT EXISTS shipped_by TEXT;

-- 2. เพิ่ม field tracking_number (เลขติดตามพัสดุ)
ALTER TABLE cart_items 
ADD COLUMN IF NOT EXISTS tracking_number TEXT;

-- 3. เพิ่ม field shipment_images (รูปภาพพัสดุ - เก็บเป็น array)
ALTER TABLE cart_items 
ADD COLUMN IF NOT EXISTS shipment_images TEXT[];

-- 4. เพิ่ม comment อธิบาย field
COMMENT ON COLUMN cart_items.shipped_by IS 'จัดส่งโดย (ชื่อบริษัทขนส่งหรือผู้ส่ง)';
COMMENT ON COLUMN cart_items.tracking_number IS 'เลขติดตามพัสดุสำหรับการจัดส่ง';
COMMENT ON COLUMN cart_items.shipment_images IS 'URL รูปภาพพัสดุก่อนจัดส่ง (เก็บเป็น array)';

-- 5. (Optional) เพิ่ม index สำหรับการค้นหาที่เร็วขึ้น
CREATE INDEX IF NOT EXISTS idx_cart_items_tracking_number ON cart_items(tracking_number);
