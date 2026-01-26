// @ts-nocheck

import { corsHeaders } from "../_shared/cors.ts";
import { getGoogleAccessToken } from "../_shared/googleAuth.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response(JSON.stringify({ error: "Method not allowed" }), {
      status: 405,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }

  try {
    const body = await req.json().catch(() => ({}));
    const userId = String(body.user_id ?? "").trim();
    const email = String(body.email ?? "").trim();
    const name = String(body.name ?? "").trim();
    const surname = String(body.surname ?? "").trim();

    if (!userId || !email) {
      return new Response(
        JSON.stringify({ error: "user_id and email are required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    // Firebase service account config (set via `supabase secrets set`)
    const projectId = Deno.env.get("FIREBASE_PROJECT_ID") ?? "";
    const clientEmail = Deno.env.get("FIREBASE_CLIENT_EMAIL") ?? "";
    const privateKey = Deno.env.get("FIREBASE_PRIVATE_KEY") ?? "";

    if (!projectId || !clientEmail || !privateKey) {
      return new Response(
        JSON.stringify({
          error:
            "Missing FIREBASE_PROJECT_ID / FIREBASE_CLIENT_EMAIL / FIREBASE_PRIVATE_KEY secrets",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const accessToken = await getGoogleAccessToken({
      clientEmail,
      privateKeyPem: privateKey,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
    });

    const displayName = `${name} ${surname}`.trim();
    const title = "มีผู้ใช้สมัครใหม่";
    const notifBody = displayName
      ? `${displayName} (${email})`
      : email;

    const fcmResp = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          message: {
            topic: "admins",
            notification: {
              title,
              body: notifBody,
            },
            data: {
              type: "new_user",
              user_id: userId,
              email,
              name,
              surname,
            },
          },
        }),
      },
    );

    const fcmText = await fcmResp.text();
    if (!fcmResp.ok) {
      return new Response(
        JSON.stringify({ error: "FCM send failed", detail: fcmText }),
        {
          status: 502,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({ ok: true, fcm: JSON.parse(fcmText) }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
