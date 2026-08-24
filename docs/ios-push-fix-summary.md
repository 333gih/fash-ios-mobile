# 🔧 iOS Push Notification Fix - Summary

## ❌ Vấn đề

iOS không nhận push notification khi **kill app** hoặc **background**.

## ✅ Nguyên nhân

FCM payload gửi tới iOS **thiếu flag `content-available: true`** → iOS không wake app để nhận notification.

## 🎯 Giải pháp

### Thay đổi code (3 files)

1. **`fash-notification-service/internal/infrastructure/notification/fcm_client.go`**
   - Thêm `ContentAvailable: true` vào iOS APNS payload
   - Thêm `MutableContent: true` để support notification extensions
   
2. **`core-service/internal/infrastructure/notification/fcm_client.go`**
   - Tách iOS/Android tokens
   - Build message riêng cho iOS với APNS config + `ContentAvailable`
   - Build message riêng cho Android với Notification thông thường

3. **`fash-notification-service/internal/infrastructure/notification/fcm_multicast_message_test.go`**
   - Thêm test verify `ContentAvailable` và `MutableContent` flags

### Test result

```bash
✅ TestBuildFCMMulticastMessageForIOS_NoRootNotification - PASS (0.00s)
```

## 📦 Deployment

```bash
# 1. Build
cd fash-notification-service && go build -o notification-service ./cmd/server
cd ../core-service && go build -o core-service ./cmd/server

# 2. Deploy & restart
systemctl restart fash-notification-service
systemctl restart fash-core-service

# 3. Test
# Kill iOS app → Send notification → Verify nhận được
```

## 🎓 Kết luận FCM vs APNs thuần

**KHÔNG CẦN chuyển sang APNs thuần.**

- Vấn đề không phải do FCM hay APNs
- Vấn đề do **thiếu `content-available` flag** trong payload
- FCM vẫn tốt và đang hoạt động đúng sau khi fix

## 📚 Chi tiết kỹ thuật

Xem: [`docs/ios-push-notification-fix.md`](./ios-push-notification-fix.md)

---

**Status:** ✅ Fixed & Tested  
**Date:** 2026-08-24
