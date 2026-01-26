# notify-admins-new-user

Supabase Edge Function สำหรับส่ง Push Notification ไปยัง FCM topic `admins` เมื่อมีผู้ใช้สมัครใหม่

## 1) เตรียม Firebase
1. ไปที่ Firebase Console → Project settings → **Cloud Messaging**
2. สร้าง/เปิดใช้งาน **Firebase Cloud Messaging API (HTTP v1)**
3. ไปที่ Project settings → **Service accounts** → Generate new private key

คุณจะได้ไฟล์ JSON ของ service account

## 2) ตั้งค่า Supabase Secrets
เอาค่าใน service account JSON มาใส่เป็น secrets:
- `FIREBASE_PROJECT_ID`
- `FIREBASE_CLIENT_EMAIL`
- `FIREBASE_PRIVATE_KEY`

ตัวอย่างคำสั่ง (ต้องติดตั้ง Supabase CLI และ login แล้ว):

- `supabase secrets set FIREBASE_PROJECT_ID="<project-id>"`
- `supabase secrets set FIREBASE_CLIENT_EMAIL="<client-email>"`
- `supabase secrets set FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\\n...\\n-----END PRIVATE KEY-----\\n"`

หมายเหตุ: private key ต้องใช้ `\\n` (escaped newline)

## 3) Deploy Function
- `supabase functions deploy notify-admins-new-user`

## 4) เรียกใช้งาน
แอปเรียก endpoint:
- `POST https://<project-ref>.supabase.co/functions/v1/notify-admins-new-user`

Body:
```json
{
  "user_id": "...",
  "email": "user@example.com",
  "name": "...",
  "surname": "..."
}
```

## 5) ฝั่งแอป (Admin)
แอปต้อง subscribe topic `admins` (ทำไว้แล้วใน `NotificationService.syncTopics(isAdmin: true)`).
