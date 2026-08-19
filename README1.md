# Hướng dẫn đẩy file nặng từ máy tính lên GitHub

## Bước 1: Chạy Git

Chạy file:

`Git-2.55.0.4-64-bit.exe`

## Bước 2: Chạy Git LFS

Chạy file:

`git-lfs-windows-v3.7.1.exe`

## Bước 3: Mở Git Bash và đi đến thư mục chứa file nặng

Nhấn **Windows** → gõ chữ **Git Bash**.

Sau đó gõ lệnh `cd` để đi đến folder chứa file nặng.

Ví dụ:

`cd "C:\Users\WDAGUtilityAccount\Downloads"`

Sau đó chạy lệnh:

`git lfs install`

## Bước 4: Khởi tạo Git

Chạy lần lượt:

`git init`

`git branch -M main`

## Bước 5: Kết nối thư mục với GitHub

Chạy lệnh:

`git remote add origin https://github.com/dhz5/dhz5.github.io.git`

### Kiểm tra

Chạy:

`git remote -v`

## Bước 6: Cấu hình bắt buộc cho file `.exe`

Chạy lệnh:

`git lfs track "*.exe"`

## Bước 7: Add file `.exe`

Nếu chỉ có một file, có thể dùng:

`git add "TenFile.exe"`

Nếu có nhiều file, dùng lệnh:

`git add .`

## Bước 8: Cấu hình email

Chạy:

`git config --global user.email "emailcuaban@gmail.com"`

## Bước 9: Commit

Chạy:

`git commit -m "Add executable"`

## Bước 10: Push lên GitHub

Chạy:

`git push -u origin main`
