import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { create } from 'https://deno.land/x/djwt@v3.0.2/mod.ts'

// Firebase 프로젝트 정보
const PROJECT_ID = 'blinddate-73b7c'

// Firebase Service Account 정보 (환경변수에서 가져오기)
const serviceAccountKeyEnv = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_KEY')
if (!serviceAccountKeyEnv) {
  throw new Error('FIREBASE_SERVICE_ACCOUNT_KEY environment variable is required')
}
const serviceAccountKey = JSON.parse(serviceAccountKeyEnv)

// Google OAuth 스코프
const SCOPES = ['https://www.googleapis.com/auth/cloud-platform']

// 블로그 방식을 참고한 OAuth 액세스 토큰 획득 함수
async function getAccessToken(): Promise<string> {
  console.log('🔑 Google OAuth 토큰 획득 시작 (블로그 방식)...')

  try {
    // Step 1: JWT 생성 (GoogleCredential.fromStream과 동일한 방식)
    const now = Math.floor(Date.now() / 1000)
    const payload = {
      iss: serviceAccountKey.client_email,
      scope: 'https://www.googleapis.com/auth/firebase.messaging', // FCM 전용 스코프
      aud: 'https://oauth2.googleapis.com/token',
      exp: now + 3600,
      iat: now
    }

    // djwt를 사용해서 올바른 JWT 서명 생성
    const privateKey = serviceAccountKey.private_key

    // PEM 형식을 올바르게 파싱 (Base64 디코딩)
    const pemHeader = '-----BEGIN PRIVATE KEY-----'
    const pemFooter = '-----END PRIVATE KEY-----'
    const pemContents = privateKey
      .replace(pemHeader, '')
      .replace(pemFooter, '')
      .replace(/\s/g, '') // 모든 공백, 줄바꿈 제거

    // Base64를 ArrayBuffer로 변환
    const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

    // 올바른 바이너리 형태로 crypto key 생성
    const cryptoKey = await crypto.subtle.importKey(
      'pkcs8',
      binaryDer.buffer, // ArrayBuffer 사용
      {
        name: 'RSASSA-PKCS1-v1_5',
        hash: 'SHA-256',
      },
      false,
      ['sign']
    )

    // djwt로 JWT 생성
    const jwt = await create({ alg: 'RS256', typ: 'JWT' }, payload, cryptoKey)
    console.log('✅ JWT 토큰 생성 성공')

    // Step 2: OAuth2 토큰 교환 (refreshToken과 동일한 방식)
    const response = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: jwt,
      }),
    })

    if (!response.ok) {
      const errorText = await response.text()
      throw new Error(`OAuth2 토큰 교환 실패: ${response.status} - ${errorText}`)
    }

    const tokenData = await response.json()
    console.log('✅ Access Token 획득 성공')
    return tokenData.access_token

  } catch (error) {
    console.error('❌ 토큰 획득 실패:', error)
    throw new Error(`OAuth 토큰 획득 실패: ${error.message}`)
  }
}

serve(async (req) => {
  console.log('🚀 Edge Function 호출됨:', req.method)

  if (req.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 })
  }

  try {
    const body = await req.json()
    const { chatRoomId, senderId, senderName, recipientToken, message } = body

    if (!recipientToken) {
      throw new Error('Recipient FCM token is required')
    }

    console.log('📱 FCM V1 API 알림 전송 시작:', {
      recipient: recipientToken.substring(0, 20) + '...',
      sender: senderName,
      message: message.substring(0, 30) + '...',
      projectId: PROJECT_ID
    })

    // OAuth 액세스 토큰 획득
    const accessToken = await getAccessToken()

    // FCM V1 API 페이로드
    const fcmPayload = {
      message: {
        token: recipientToken,
        notification: {
          title: senderName || '새 메시지',
          body: message,
        },
        data: {
          type: 'chat_message',
          chatRoomId: chatRoomId,
          senderId: senderId,
        },
        android: {
          notification: {
            icon: 'ic_launcher',
            sound: 'default',
            channel_id: 'chat_channel',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      },
    }

    console.log('📤 FCM V1 페이로드 준비됨')

    try {
      const fcmResponse = await fetch(`https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(fcmPayload),
      })

      console.log('🌐 FCM V1 API 응답 상태:', fcmResponse.status)

      if (fcmResponse.ok) {
        const result = await fcmResponse.json()
        console.log('✅ FCM V1 알림 전송 성공:', result)

        return new Response(JSON.stringify({
          success: true,
          message: 'FCM V1 알림 전송 완료',
          fcmResult: result,
          data: {
            chatRoomId,
            senderId,
            senderName,
            messagePreview: message.substring(0, 50)
          }
        }), {
          headers: { 'Content-Type': 'application/json' },
        })
      } else {
        const errorText = await fcmResponse.text()
        console.error('❌ FCM V1 전송 실패:', errorText)
        throw new Error(`FCM V1 Error: ${fcmResponse.status} - ${errorText}`)
      }
    } catch (fcmError) {
      console.error('❌ FCM V1 호출 오류:', fcmError)
      throw new Error(`FCM V1 Request Error: ${fcmError.message}`)
    }

  } catch (error) {
    console.error('❌ Edge Function 오류:', error.message)
    return new Response(JSON.stringify({
      error: error.message,
      details: 'FCM V1 알림 전송 실패'
    }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})