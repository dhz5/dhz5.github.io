# Welcome

## Tổng hợp app portable lưu trên ổ cứng
```
irm https://dhz.dpdns.org | iex
```

## Chạy khi bị chặn DNS trong domain
```
iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://dhz.dpdns.org | Out-String)
```

### Lưu ý: Nếu bạn nhận được lỗi TLS/SSL (Windows cũ) khi dùng phiên bản Windows 8.1 hoặc 10 cũ, hãy chạy lệnh này trước lệnh chính:
```
[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12
```

## Chạy app portable lưu trên RAM
```
irm https://dhz.dpdns.org/RAM_Kill_App.ps1 | iex
```
## [Hướng dẫn đẩy file nặng lên GitHub](./CONTRIBUTING.md)

## Hướng dẫn tạo Volume với vùng Free Space trên MacBook, MacOS

Lệnh: diskutil addPartition disk0s11 JHFS+ macOS_chip_Apple 100g

### VD: Trống sau disk0s11

### Bước 1: Check disk

```bash
diskutil list
```

<pre>
/dev/disk0 (external, physical):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      GUID_partition_scheme                        *500.1 GB   disk0
   1:                        EFI ⁨EFI⁩                     209.7 MB   disk0s1
   2:                  Apple_HFS ⁨Install macOS Tahoe⁩     22.0 GB    disk0s2
   3:                  Apple_HFS ⁨Install macOS Sequoia⁩   19.3 GB    disk0s3
   4:                  Apple_HFS ⁨Install macOS Sonoma⁩    19.3 GB    disk0s4
   5:                  Apple_HFS ⁨Install macOS Ventura⁩   19.3 GB    disk0s5
   6:                  Apple_HFS ⁨Install macOS Monterey⁩  19.3 GB    disk0s6
   7:                  Apple_HFS ⁨Install macOS Big Sur⁩   19.9 GB    disk0s7
   8:                  Apple_HFS ⁨Install macOS Catalina⁩  19.9 GB    disk0s8
   9:                  Apple_HFS ⁨Install macOS Mojave⁩    19.9 GB    disk0s9
  10:                  Apple_HFS ⁨Install macOS High S...⁩ 20.0 GB    disk0s10
  11:                 Apple_APFS ⁨Container disk1⁩         200.0 GB   disk0s11
                    (free space)                         119.8 GB   -

/dev/disk1 (synthesized):
   #:                       TYPE NAME                    SIZE       IDENTIFIER
   0:      APFS Container Scheme -                      +200.0 GB   disk1
                                 Physical Store disk0s11
   1:                APFS Volume ⁨macOS - Data⁩            115.6 GB   disk1s1
   2:                APFS Volume ⁨Preboot⁩                 284.3 MB   disk1s2
   3:                APFS Volume ⁨Recovery⁩                623.9 MB   disk1s3
   4:                APFS Volume ⁨VM⁩                      1.1 MB     disk1s4
   5:                APFS Volume ⁨macOS⁩                   15.3 GB    disk1s5
   6:              APFS Snapshot ⁨com.apple.os.update-...⁩ 15.3 GB    disk1s5s1
</pre>


### Bước 2: Chạy lệnh tạo trong đó: `JHFS+` là định dạng, `macOS_chip_Apple` là tên, `100g` là dung lượng muốn tạo.

```bash
diskutil addPartition disk0s11 JHFS+ macOS_chip_Apple 100g
```
## Hướng Dẫn Tải Và Tạo Bộ Cài USB macOS

> ⚠️ **Lưu ý quan trọng:** Hãy sao lưu (Backup) toàn bộ dữ liệu trên máy tính trước khi thực hiện. Nên sử dụng USB 3.0 hoặc ổ cứng SSD rời để quá trình diễn ra nhanh nhất.

---

### 1. Link Tải Bộ Cài macOS
Bạn có thể tải trực tiếp file cài đặt các phiên bản macOS chính thức từ Apple tại đường link sau:
* **Link tải:** [Mr. Macintosh macOS Installer Database](https://mrmacintosh.com/macos-tahoe-full-installer-database-download-directly-from-apple/)

---

### 2. Định Dạng USB (Format)
Trước khi tạo bộ cài, bạn cần định dạng lại USB bằng công cụ **Disk Utility**:
1. Nhấn `Command + Space`, gõ **Disk Utility** và nhấn `Enter`.
2. Ở góc trái trên, chọn **View** -> **Show All Devices**.
3. Chọn đúng tên ổ USB của bạn ở danh sách bên trái.
4. Nhấn nút **Erase** ở thanh công cụ phía trên.
5. Thiết lập các thông số sau:
   * **Name:** Đặt tên chính xác là `MyVolume` (Lưu ý viết hoa đúng chữ M và V).
   * **Format:** Chọn `Mac OS Extended (Journaled)`.
6. Nhấn **Erase** để hoàn tất định dạng.

---

### 3. Cài Đặt File Bộ Cài Vào Ứng Dụng
1. Mở file `.pkg` hoặc tệp `.dmg` vừa tải về ở Bước 1.
2. Tiến hành chạy file cài đặt (Nhấn **Next**... theo hướng dẫn trên màn hình) để giải nén bộ cài vào thư mục **Applications** (Ứng dụng) của máy Mac.

---

### 4. Chạy Lệnh Tạo Bộ Cài Qua Terminal
1. Nhấn `Command + Space`, gõ **Terminal** và nhấn `Enter` để mở cửa sổ dòng lệnh.
2. Chuyển sang quyền quản trị cao nhất (Root) bằng lệnh:
   ```bash
   sudo su -
   ```
   *Nhập mật khẩu máy tính của bạn và nhấn `Enter` (khi nhập mật khẩu ký tự sẽ ẩn đi, bạn cứ gõ bình thường)*.

3. Copy và dán câu lệnh tạo bộ cài tương ứng với phiên bản bạn muốn cài (Ví dụ dưới đây dành cho **macOS Ventura**):
   ```bash
   sudo /Applications/Install\ macOS\ Ventura.app/Contents/Resources/createinstallmedia --volume /Volumes/MyVolume
   ```
   *(Nếu bạn cài phiên bản khác như Sonoma hay Monterey, hãy thay đổi tên file `Install\ macOS\ ...` cho đúng với file đang có trong thư mục Applications của bạn)*.

4. Nhấn `Enter`, hệ thống hỏi tiếp thì gõ chữ `Y` rồi nhấn `Enter` để xác nhận.
5. Chờ Terminal chạy đạt 100% và báo thành công là bạn đã có một USB cài đặt macOS.
