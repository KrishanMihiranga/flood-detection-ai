import { GoogleAuth } from "npm:google-auth-library@9.11.0";

Deno.serve(async (req) => {
  try {
    const payload = await req.json();
    console.log("Received webhook payload:", JSON.stringify(payload, null, 2));

    const record = payload.record;
    if (!record) {
      return new Response(
        JSON.stringify({ error: "No record found in webhook payload." }),
        {
          status: 400,
          headers: { "Content-Type": "application/json" },
        }
      );
    }

    const { title, summary, area, severity } = record;

    // 1. Retrieve the service account JSON secret
    const serviceAccountStr = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
    if (!serviceAccountStr) {
      throw new Error("Missing FIREBASE_SERVICE_ACCOUNT secret on Supabase.");
    }

    const serviceAccount = JSON.parse(serviceAccountStr);
    const projectId = serviceAccount.project_id;

    // 2. Generate Google OAuth2 Access Token for FCM
    const auth = new GoogleAuth({
      credentials: serviceAccount,
      scopes: "https://www.googleapis.com/auth/firebase.messaging",
    });

    const client = await auth.getClient();
    const tokenResponse = await client.getAccessToken();
    const accessToken = tokenResponse.token;

    if (!accessToken) {
      throw new Error("Failed to generate Google OAuth2 access token.");
    }

    // 3. Compose standard FCM v1 Payload targeting the 'all_users' topic
    const fcmPayload = {
      message: {
        topic: "all_users",
        notification: {
          title: title || "Official Broadcast",
          body: summary || "",
        },
        data: {
          area: area || "Basin-wide",
          severity: severity || "warning",
          click_action: "FLUTTER_NOTIFICATION_CLICK",
        },
        android: {
          priority: "high",
          notification: {
            sound: "default",
          },
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      },
    };

    // 4. Dispatch notification request to Firebase endpoint
    console.log(`Dispatching push alert to project [${projectId}]...`);
    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Authorization": `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const result = await response.json();
    console.log("FCM Response:", JSON.stringify(result, null, 2));

    if (!response.ok) {
      throw new Error(
        `FCM delivery failed (HTTP ${response.status}): ${JSON.stringify(result)}`
      );
    }

    return new Response(
      JSON.stringify({ success: true, messageId: result.name }),
      {
        status: 200,
        headers: { "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    console.error("Supabase send-fcm Edge Function Error:", err);
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
