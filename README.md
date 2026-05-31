# MemoryMaker User App - Public Beta Release Source

This Flutter app is the user-side mobile app for MemoryMaker public beta. It is designed to work with the same Supabase database and no-CDN compressed media tables used by the latest web beta release.

## Included features

- User login only
- Email/password login
- Signup with email confirmation support
- Forgot/reset password flow
- Password show/hide icon
- Modern bottom navigation
- Dashboard
- My event galleries
- Free beta gallery creation while package buying is disabled
- QR code display for gallery link
- QR share action
- QR print helper action
- Camera permission request
- Gallery/media permission request
- Notification permission request
- Compressed photo upload before database save
- Gallery view
- High quality image preview through web media API URL
- Share image/gallery link action
- Print helper action
- Notifications screen
- Support ticket system
- Account/profile settings
- Profile picture update
- Password change
- Custom app logo/icon assets

## Important security note

Only put these public values in the app:

```env
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-public-anon-key
APP_URL=https://memorymaker.com
DEMO_MODE=false
```

Never put `SUPABASE_SERVICE_ROLE_KEY` inside Flutter, Android, iOS, GitHub, APK, or app source code.

## Required web/database setup

Run the latest public beta SQL migration on Supabase first. The app expects these tables/columns:

- profiles
- events
- event_guests
- media_uploads
- media_blobs
- user_notifications
- support_tickets

The app stores compressed images in `media_blobs` and displays media through:

```text
https://memorymaker.com/api/media/<mediaId>/file
```

## Local setup

```bash
flutter pub get
flutter pub run flutter_launcher_icons
flutter run
```

## Build test APK

```bash
flutter build apk --release
```

APK output:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## Demo login

When `DEMO_MODE=true` or Supabase values are empty:

```text
Email: admin@memorymaker.com
Password: Test@123456
```

## Production checklist

- Set `DEMO_MODE=false`
- Add real `SUPABASE_URL`
- Add real `SUPABASE_ANON_KEY`
- Add `APP_URL=https://memorymaker.com`
- Run Supabase migration SQL
- Confirm Supabase Auth email confirmation/reset URLs
- Build APK / App Bundle
- Test on a real Android phone
- Test login, signup, reset password, camera permission, gallery permission, notification permission, gallery creation, photo upload, QR share, support ticket, profile update and logout
