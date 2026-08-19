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
