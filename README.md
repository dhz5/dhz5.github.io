# Welcome

## Tổng hợp app portable lưu trên ổ cứng
```
irm https://dhz.dpdns.org | iex
```

## Chạy khi bị chặn DNS trong domain
```
iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://dhz.dpdns.org | Out-String)
```

## Chạy app portable lưu trên RAM
```
irm https://dhz.dpdns.org/RAM_Kill_App.ps1 | iex
```
