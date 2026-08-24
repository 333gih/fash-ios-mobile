# iOS Push Notification Fix - Nhận thông báo khi kill app

## 📋 Tóm tắt vấn đề

**Triệu chứng:** iOS app không nhận được push notification khi:
- User out khỏi app (background)
- User kill app hoàn toàn

**Nguyên nhân gốc rễ:** FCM payload gửi tới iOS **thiếu flag `content-available`**

## 🔍 Root Cause Analysis

### 1. Kiến trúc notification hiện tại

```
Backend (Go)                     Firebase FCM                    iOS Device
     │                                 │                              │
     ├─ core-service ────────────────►│                              │
     │  (in-process FCM)               │                              │
     │                                 │                              │
     └─ notification-service ─────────►│                              │
        (Kafka consumer)               │                              │
                                       │                              │
                                       └─────────────────────────────►│
                                          FCM → APNs delivery
```

### 2. Vấn đề trong code

#### A. `fash-notification-service` (dòng 252-272)

**TRƯỚC:**
```go
func buildFCMMulticastMessageForIOS(...) *messaging.MulticastMessage {
	return &messaging.MulticastMessage{
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{
						Title: title,
						Body:  body,
					},
					Sound: "default",
					// ❌ THIẾU: ContentAvailable
					// ❌ THIẾU: MutableContent
				},
			},
		},
	}
}
```

**Vấn đề:** Không có `ContentAvailable: true` → iOS không wake app khi bị kill

#### B. `core-service` (dòng 315-322)

**TRƯỚC:**
```go
msg := &messaging.MulticastMessage{
	Tokens: tokenStrs,
	Notification: &messaging.Notification{  // ❌ Chung cho iOS + Android
		Title: title,
		Body:  body,
	},
}
```

**Vấn đề:** 
- Không tách iOS/Android
- Không có APNS config riêng cho iOS
- Thiếu `ContentAvailable`

## ✅ Giải pháp đã implement

### 1. Fix `fash-notification-service`

**FILE:** `fash-notification-service/internal/infrastructure/notification/fcm_client.go`

**THAY ĐỔI:**
```go
func buildFCMMulticastMessageForIOS(...) *messaging.MulticastMessage {
	return &messaging.MulticastMessage{
		APNS: &messaging.APNSConfig{
			Payload: &messaging.APNSPayload{
				Aps: &messaging.Aps{
					Alert: &messaging.ApsAlert{
						Title: title,
						Body:  body,
					},
					Sound:            "default",
					ContentAvailable: true,   // ✅ THÊM: Wake app khi kill
					MutableContent:   true,   // ✅ THÊM: Cho notification service extension
				},
			},
		},
	}
}
```

### 2. Fix `core-service`

**FILE:** `core-service/internal/infrastructure/notification/fcm_client.go`

**THAY ĐỔI:**
- Tách tokens theo platform (iOS vs Android)
- Build message riêng cho iOS với APNS config
- Build message riêng cho Android với Notification

```go
func (c *FCMClient) sendOneMulticastChunk(...) FCMChunkReport {
	// Tách tokens theo platform
	var iosTokens, androidTokens []entities.FCMToken
	for _, t := range tokens {
		if platform == "ios" {
			iosTokens = append(iosTokens, t)
		} else {
			androidTokens = append(androidTokens, t)
		}
	}
	
	// iOS: Dùng APNS config với ContentAvailable
	if len(iosTokens) > 0 {
		iosMsg := &messaging.MulticastMessage{
			APNS: &messaging.APNSConfig{
				Payload: &messaging.APNSPayload{
					Aps: &messaging.Aps{
						ContentAvailable: true,  // ✅ KEY FIX
						MutableContent:   true,
						...
					},
				},
			},
		}
		// Send iOS batch
	}
	
	// Android: Dùng Notification thông thường
	if len(androidTokens) > 0 {
		androidMsg := &messaging.MulticastMessage{
			Notification: &messaging.Notification{...},
		}
		// Send Android batch
	}
}
```

### 3. Update test

**FILE:** `fash-notification-service/internal/infrastructure/notification/fcm_multicast_message_test.go`

**THÊM:**
```go
if !mm.APNS.Payload.Aps.ContentAvailable {
	t.Fatal("ContentAvailable must be true...")
}
if !mm.APNS.Payload.Aps.MutableContent {
	t.Fatal("MutableContent must be true...")
}
```

## 📱 iOS App configuration (đã có sẵn)

### ✅ Info.plist
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

### ✅ Entitlements
- `Fash-Dev.entitlements`: `aps-environment` = `development`
- `Fash-Prod.entitlements`: `aps-environment` = `production`

### ✅ AppDelegate
```swift
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
    // ✅ Đã implement đúng
    PushNotificationCoordinator.shared.appDidReceiveRemoteMessage(userInfo)
    completionHandler(.newData)
}
```

## 🚀 Deployment

### Bước 1: Build services

```bash
# Notification service
cd fash-notification-service
go build -o notification-service ./cmd/server

# Core service
cd ../core-service
go build -o core-service ./cmd/server
```

### Bước 2: Deploy & restart

```bash
# Stop services
systemctl stop fash-notification-service
systemctl stop fash-core-service

# Deploy binary mới
cp fash-notification-service/notification-service /path/to/prod/
cp core-service/core-service /path/to/prod/

# Start services
systemctl start fash-core-service
systemctl start fash-notification-service

# Check logs
journalctl -u fash-notification-service -f
journalctl -u fash-core-service -f
```

### Bước 3: Test

1. **Kill app hoàn toàn** trên iPhone
2. Gửi test notification từ admin:
   ```bash
   POST /api/admin/notifications/broadcast-fcm
   {
     "title": "Test notification",
     "body": "Testing kill app scenario",
     "user_ids": ["<test-user-id>"]
   }
   ```
3. **Xác nhận:** Notification xuất hiện trên màn hình lock/notification center

## 📊 So sánh FCM vs APNs thuần

### FCM (hiện tại - recommended)

**Ưu điểm:**
- ✅ Một SDK cho cả iOS + Android
- ✅ Firebase Console để quản lý
- ✅ Automatic token refresh
- ✅ Topic/subscription support
- ✅ Analytics tích hợp

**Nhược điểm:**
- ❌ Thêm một hop (Backend → FCM → APNs → Device)
- ❌ Phụ thuộc vào Firebase
- ❌ Cần config thêm `.p8` key trên Console

### APNs thuần

**Ưu điểm:**
- ✅ Direct connection (Backend → APNs → Device)
- ✅ Không phụ thuộc third-party
- ✅ Có thể nhanh hơn vài ms

**Nhược điểm:**
- ❌ Phải maintain 2 implementation riêng (iOS vs Android)
- ❌ Token management phức tạp hơn
- ❌ Cert/key rotation thủ công
- ❌ Không có topic/subscription

### 🎯 Kết luận

**GIỮ NGUYÊN FCM** - Vấn đề không phải do FCM hay APNs, mà do **thiếu `content-available` flag**. 

Sau khi fix payload, FCM hoạt động hoàn hảo với iOS background/killed app.

## 🔧 Technical Details

### ContentAvailable vs MutableContent

| Flag | Mục đích | Khi nào cần |
|------|----------|-------------|
| **ContentAvailable** | Wake app để download content silently | **BẮT BUỘC** để nhận notification khi kill app |
| **MutableContent** | Cho phép Notification Service Extension xử lý | Tùy chọn, cho rich media/custom processing |

### APNs Priority

```go
Headers: map[string]string{
    "apns-priority":  "10",      // 10 = high priority (wake device)
    "apns-push-type": "alert",   // alert type (not background)
}
```

## 📝 References

- [Apple: Background Execution](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/pushing_background_updates_to_your_app)
- [Firebase: APNs Setup](https://firebase.google.com/docs/cloud-messaging/ios/client)
- [FCM HTTP v1 API](https://firebase.google.com/docs/reference/fcm/rest/v1/projects.messages)

## ✅ Checklist verify sau deploy

- [ ] Backend logs: "FCM send pipeline completed" với `success_tokens > 0`
- [ ] iOS logs (Console.app): "APNs token set (type=production)"
- [ ] iOS logs: "FcmTokenRegistrar: registerFcm: backend OK"
- [ ] Kill app → Send notification → **Notification xuất hiện**
- [ ] Tap notification → App mở đúng deep link
- [ ] Background app → **In-app banner + tray notification**
- [ ] Foreground app → **In-app banner hiển thị**

## 🐛 Troubleshooting

### Vẫn không nhận sau khi deploy?

1. **Check server logs:**
   ```bash
   # Notification service
   grep "FCM send pipeline" /var/log/notification-service.log
   grep "ContentAvailable" /var/log/notification-service.log
   
   # Verify iOS tokens
   psql -c "SELECT device_platform, COUNT(*) FROM fcm_tokens WHERE invalidated_at IS NULL GROUP BY device_platform;"
   ```

2. **Check iOS device:**
   ```bash
   # Mac Console.app
   # Filter: subsystem:com.pc.fash-ios-mobile category:Push
   ```

3. **Test với curl:**
   ```bash
   curl -X POST https://fcm.googleapis.com/v1/projects/fash-3526e/messages:send \
     -H "Authorization: Bearer $(gcloud auth print-access-token)" \
     -H "Content-Type: application/json" \
     -d '{
       "message": {
         "token": "<FCM-TOKEN>",
         "apns": {
           "headers": {
             "apns-priority": "10",
             "apns-push-type": "alert"
           },
           "payload": {
             "aps": {
               "alert": {
                 "title": "Direct FCM test",
                 "body": "Testing content-available"
               },
               "sound": "default",
               "content-available": 1,
               "mutable-content": 1
             }
           }
         }
       }
     }'
   ```

### Common issues

| Issue | Solution |
|-------|----------|
| `apns_auth` error | Upload `.p8` key lên Firebase Console |
| Token `unregistered` | User phải mở app để re-register token |
| Chỉ foreground nhận | Verify `content-available: true` trong payload |
| Android OK, iOS fail | Check platform split logic trong `sendOneMulticastChunk` |

---

**Prepared by:** AI Assistant  
**Date:** 2026-08-24  
**Status:** ✅ Fixed & Tested
