# Hướng dẫn nhanh: Deploy vào branch `web` với base href đúng

## Vấn đề: Màn hình trắng

Nếu bạn thấy màn hình trắng khi truy cập `https://lamquynh257.github.io/mobile-flutterpos/`, 
đó là do **base href không đúng**. 

**Đã sửa:** File `web/index.html` đã được cập nhật với placeholder `$FLUTTER_BASE_HREF` để Flutter tự động thay thế khi build.

## Giải pháp nhanh

### Bước 1: Build lại với base href đúng

```bash
cd flutter-pos
flutter build web --release --base-href "/mobile-flutterpos/"
```

### Bước 2: Deploy vào branch `web`

```bash
# Checkout branch web
git checkout web

# Xóa file cũ (Windows PowerShell)
Get-ChildItem -Exclude .git | Remove-Item -Recurse -Force

# Copy file mới (Windows PowerShell)
Copy-Item -Path build\web\* -Destination . -Recurse -Force

# Commit và push
git add .
git commit -m "Fix: Update base href to /mobile-flutterpos/"
git push origin web

# Quay lại branch chính
git checkout main  # hoặc branch bạn đang làm việc
```

### Hoặc dùng script tự động:

**Windows PowerShell (Khuyên dùng):**
```powershell
cd flutter-pos
.\deploy-web.ps1
```

**Windows CMD:**
```bash
cd flutter-pos
.\deploy-to-web-branch.bat
```

**Linux/Mac:**
```bash
cd flutter-pos
chmod +x deploy-to-web-branch.sh
./deploy-to-web-branch.sh
```

## Kiểm tra sau khi deploy

1. Đợi vài phút để GitHub Pages cập nhật
2. Truy cập: https://lamquynh257.github.io/mobile-flutterpos/
3. Mở Console (F12) để kiểm tra lỗi:
   - Nếu thấy lỗi 404 cho các file JS/CSS → base href vẫn chưa đúng
   - Nếu thấy lỗi CORS → cần cấu hình backend API

## Lưu ý

- Base href **PHẢI** khớp với tên repository: `/mobile-flutterpos/`
- Phải có dấu `/` ở đầu và cuối
- Sau khi deploy, đợi 1-2 phút để GitHub Pages cập nhật

