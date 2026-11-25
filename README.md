# Cờ Tỷ Phú Đa Thế Giới

Game bàn cờ 3D offline: một người cùng ba bot, ba chủ đề bản đồ, xúc xắc 3D, mua đất, tiền thuê, xây dựng, thế chấp, đấu giá, giao dịch và lưu/tiếp tục ván. Bot sử dụng logic đánh giá chiến thuật; không cần dịch vụ AI hay internet khi chơi.

## Phát triển

Mở `project.godot` bằng **Godot 4.4.1**, nhấn Play. Android là nền tảng chơi chính, màn hình ngang; bản desktop phục vụ phát triển.

```sh
godot --path .
GODOT_BIN=godot python3 scripts/check_game.py
```

Bộ kiểm tra gồm import, smoke (100 mô phỏng), economy và flow. Lỗi Godot/assertion, thiếu dấu xác nhận hoặc quá thời gian đều làm kiểm tra thất bại. Chưa có kiểm chứng hiệu năng hay trải nghiệm trên điện thoại Android thật.

## APK và release

Push lên `main` hoặc chạy Actions thủ công tạo artifact APK ký sẵn. Push tag SemVer như `v1.0.0` tạo GitHub Release kèm APK, SHA256 và thông tin chứng chỉ công khai. Mỗi run dùng `github.run_number` làm Android versionCode; giữ nguyên workflow này để duy trì số build tăng dần. Không dùng lại tag đã phát hành.

CI dùng Godot 4.4.1, JDK 17, SDK platform/build-tools 35 và xuất **arm64-v8a** (`vn.personal.cotyphu`). Trước khi upload, CI xác minh chữ ký bằng apksigner, so chứng chỉ với khóa release và kiểm tra package/version/ABI. SDK/API tối thiểu do template Godot quyết định. APK được cài trực tiếp; đây chưa phải quy trình phát hành Google Play/AAB.

Repository Secrets bắt buộc:

- `ANDROID_KEYSTORE_BASE64`: file keystore PKCS12 được mã hóa base64.
- `ANDROID_KEYSTORE_ALIAS`: alias khóa release.
- `ANDROID_KEYSTORE_PASSWORD`: mật khẩu chung của keystore và private key.

Không có khóa tạm dự phòng. Khóa ký được tạo một lần và sao lưu riêng ngoài repository; phải giữ khóa/mật khẩu này để các bản sau cài đè được. Không commit khóa, mật khẩu hoặc file cấu hình CI đã điền secret. Workflow chỉ ghi cấu hình ký trong bước export và khôi phục sau đó.

## Asset và tài liệu

164 model GLB từ Polyfork được phân phối theo **CC BY 4.0**; xem [credits](assets/polyfork/CREDITS.md), [manifest](assets/polyfork/manifest.json) và [license](https://creativecommons.org/licenses/by/4.0/). Các biến thể màu/miniature được mô tả trong credits. Attribution cũng có trong game. Mã nguồn dự án chưa được cấp license sử dụng lại riêng.

Các tài liệu trong `docs/` ghi lại định hướng, luật, thiết kế bot và lộ trình; một số mô tả prototype cũ cần được đối chiếu với source hiện tại.
