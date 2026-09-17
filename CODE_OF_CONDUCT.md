# Các cách chuyển từ Pro xuống Home trên windows 11, không mất dữ liệu

## Cách 1: Chỉnh regedit Pro -> Home và cài lại từ iso, lúc quét hệ thống sẽ hiểu là Home
- **Chuẩn bị:** Source Windows 11 ISO.
- **Chỉnh regedit:** (Lưu ý nếu là Home Single Language để đúng).

### Thao tác thủ công trong Registry Editor:
* **Đường dẫn 1:** `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion`
  * `CompositionEditionID`: Enterprise &rarr; **CoreSingleLanguage**
  * `EditionID`: Professional &rarr; **CoreSingleLanguage**
  * `ProductName`: Windows 10 Pro &rarr; **Windows 10 Home Single Language** *(Lưu ý: nếu trên máy hiển thị là Windows 11 thì vẫn giữ là 11, chỉ sửa chữ Pro sang Home)*
* **Đường dẫn 2:** `Computer\HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion`
  * `CompositionEditionID`: Enterprise &rarr; **CoreSingleLanguage**
  * `EditionID`: Professional &rarr; **CoreSingleLanguage**
  * `ProductName`: Windows 10 Pro &rarr; **Windows 10 Home Single Language** *(Lưu ý: nếu trên máy hiển thị là Windows 11 thì vẫn giữ là 11, chỉ sửa chữ Pro sang Home)*

### Tiến hành cài đặt đè từ ISO:
* Mở **ISO Windows 11** &rarr; Chạy file `Setup.exe` &rarr; Chọn **Change how Setup downloads updates** &rarr; Chọn **Not right now** &rarr; **Next** &rarr; **Accept** &rarr; *Kiểm tra lại xem chỗ install hiển thị đúng Windows 11 Home hay chưa* &rarr; Bấm **Install**.

### Bảng tên phiên bản tương ứng và EditionID thường dùng:
| Phiên bản | EditionID tương ứng |
| :--- | :--- |
| Windows 11 Home | `Core` |
| Windows 11 Home Single Language | `CoreSingleLanguage` |
| Windows 11 Pro | `Professional` |
| Windows 11 Pro N | `ProfessionalN` |
| Windows 11 Enterprise | `Enterprise` |

### Lệnh CMD thay cho chỉnh tay Regedit:
> ⚠️ **Lưu ý:** Hãy **BACKUP** registry trước khi làm. Sửa lại tên phiên bản thành "Windows 11..." nếu máy của bạn đang hiển thị thông tin gốc là Windows 11.

```cmd
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CompositionEditionID /t REG_SZ /d CoreSingleLanguage /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v EditionID /t REG_SZ /d CoreSingleLanguage /f
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v ProductName /t REG_SZ /d "Windows 10 Home Single Language" /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" /v CompositionEditionID /t REG_SZ /d CoreSingleLanguage /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" /v EditionID /t REG_SZ /d CoreSingleLanguage /f
reg add "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion" /v ProductName /t REG_SZ /d "Windows 10 Home Single Language" /f
```

---

## Cách 2: Sửa key với máy đã có key trong bios và nhận được CoreSingleLanguage
Dùng **CMD** với quyền **Administrator** (Run as admin) để kiểm tra các phiên bản có thể hạ cấp:
```cmd
DISM /Online /Get-TargetEditions
```
Nếu kết quả trả về có dòng `Target Edition : CoreSingleLanguage`, tiến hành chạy lệnh sau để thay đổi product key:
```cmd
changepk.exe /productkey 7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH
```

---

## Cách 3: Nếu tất cả không được thì cài lại windows
* **Trường hợp 1:** Nếu vào được menu Boot/BIOS thì tiến hành cài đặt từ USB Boot như bình thường.
* **Trường hợp 2:** Nếu không vào boot được. ⚠️ *Yêu cầu: "Backup dữ liệu ra ổ cứng khác trước khi làm"*.

### Hướng dẫn (A): Dùng phần mềm WinToHDD
Cài đặt lại hệ điều hành Windows trực tiếp từ file ISO, WIM, ESD ngay trên môi trường Windows hiện tại:
1. Mở **WinToHDD** &rarr; Chọn **Reinstall Windows**.
2. Tại mục **Image File**, trỏ đường dẫn đến file `Windows11.iso` *(Lưu ý: file ISO phải được lưu ở ổ đĩa khác ổ C)*.
3. Chọn phiên bản Windows tương ứng muốn cài đặt &rarr; Nhấn **Next** &rarr; **Next**.
4. Chọn **Yes** để xác nhận toàn bộ dữ liệu sẽ bị xóa *(Khuyến nghị rút ổ cứng rời chứa dữ liệu backup ra trước)* &rarr; Chọn **Yes** để máy tự động khởi động lại và cài đặt.

### Hướng dẫn (B): Tích hợp boot vào hệ thống hiện tại
*Phương pháp này cần chuẩn bị và thao tác nhiều bước hơn:*
1. Mở công cụ **EasyBCDPortable** &rarr; Chọn thẻ **Add New Entry**.
2. Tại mục **Portable/External Media**, chọn tab **WinPE**.
3. Điền thông tin:
   * **Name:** `WinPE Anhdv`
   * **Path:** Trỏ đường dẫn đến file `WinPE ANHDV.wim`
4. Nhấn **Add Entry**.
5. Chuyển sang thẻ **Edit Boot Menu** &rarr; Đưa dòng `WinPE Anhdv` lên trên cùng &rarr; Tích chọn cột **Default: Yes** &rarr; Nhấn **Save Settings**.
6. Tiến hành khởi động lại máy, hệ thống sẽ tự động boot vào WinPE, sau đó bạn cài đặt Windows như bình thường.
