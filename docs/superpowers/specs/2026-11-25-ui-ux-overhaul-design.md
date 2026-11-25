# Thiết kế Cải tổ Toàn diện UI/UX & Bàn cờ 3D — Cờ Tỷ Phú Đa Thế Giới

**Ngày:** 2026-11-25  
**Trạng thái:** Đã duyệt bởi người dùng (Phương án A — Modular 3D Procedural + Polyfork chọn lọc + Custom Vector HUD)

---

## 1. Mục tiêu & Phạm vi

Tái thiết kế toàn bộ giao diện (UI/UX), bố cục bàn cờ 3D, ánh sáng, chồng tiền 4 góc, kích thước nhân vật, hệ thống xúc xắc 3D (nhiều skin + hiệu ứng tung vật lý giữa sân) và nhịp độ diễn hoạt của game **Cờ Tỷ Phú Đa Thế Giới** theo sát phong cách thị giác sáng rõ, sang trọng và hiện đại của bản mẫu đính kèm (*Business Tour* style), đồng thời bảo toàn 100% logic luật chơi trong `src/game.gd` và bộ kiểm thử tự động (`smoke.gd`, `economy.gd`, `flow.gd`, `capture.gd`).

---

## 2. Kiến trúc Module

| File | Trách nhiệm |
| --- | --- |
| `assets/backdrop.gdshader` | Gradient nền hoàng hôn ấm (`#503c53` → `#9b6963` → `#e09b66` → `#f7bd70`) kèm họa tiết ô vuông bo góc xoay mờ tinh tế. |
| `assets/field.gdshader` | Thảm cỏ sân giữa kẻ sọc xanh tươi sáng (`#add262` / `#9fc454`) và đường vạch trắng mảnh kiểu sân cỏ bản mẫu. |
| `src/board_art.gd` | Dựng bàn cờ chuẩn kích thước không chồng lấn (4 ô góc vuông `12×12`, 36 ô cạnh `7.22×12`), quy tắc hướng mặt trước-sau theo camera (nhà/dải màu ở phía xa camera, tên ô ở giữa, dải giá `60K`–`340K` ở phía gần camera), vòng quay Cơ hội cầu vồng, biên lai Thuế, 4 góc biểu tượng và nhà/khách sạn theo màu chủ sở hữu. |
| `src/money_pile.gd` | Dựng và cập nhật động 4 chồng tiền 3D ở 4 cạnh bàn cờ: các xấp tiền xanh lá buộc đai giấy trắng xếp tầng 3D, kèm thỏi bạc, thỏi vàng và xấp thẻ tài sản màu khi người chơi giàu lên. |
| `src/dice_rig.gd` | Mô hình xúc xắc 3D bo cạnh, đầy đủ 6 mặt chấm thật, 4 bộ skin (Obsidian Gold mặc định giống bản mẫu, Royal Ivory, Ruby Vegas, Jade Cyber), quỹ đạo tung parabol từ phía người chơi vào giữa sân, nảy nhiều nhịp kèm hạt hiệu ứng va chạm. |
| `src/character.gd` | Nhân vật 3D phóng lớn (`scale ~ 5.5`), đứng trên đế tròn viền màu người chơi nổi bật, nhún nhảy mượt mà khi đi. |
| `src/player_banner.gd` | Card HUD 4 góc chuẩn bản mẫu: 4 màu đặc trưng (Hồng `#f01e6b`, Xanh dương `#1aa3ec`, Xanh lá `#84bd22`, Vàng `#f2bf18`), bố cục 2 card trên / 2 card dưới đối xứng, khung avatar bóng bẩy có huy hiệu VIP/vương miện, con số tiền định dạng `1 500 000` kèm icon xấp tiền xanh vẽ vector. |
| `src/hud_modals.gd` | Các thành phần UX hiện đại: Bong bóng thoại có đuôi nhọn cạnh nhân vật (`SpeechBubble`), Thẻ Bất Động Sản nổi (`PropertyDeedCard`) khi dẫm vào đất/soi ô, Bảng điểm xúc xắc dưới góc sân vận động, bộ nút tròn bên phải có badge số tài sản, và hộp chọn Skin Xúc xắc. |
| `src/main.gd` | Điều phối camera ổn định (không giật zoom gây chóng mặt), nhịp diễn hoạt khoan thai dễ theo dõi, tích hợp toàn bộ HUD mới, màn hình Trang đầu / Chuẩn bị / Tạm dừng / Tài sản dạng thẻ sáng đẹp và tương thích đầy đủ các thuộc tính test. |

---

## 3. Chi tiết Thiết kế & Quy chuẩn Hiển thị

### 3.1. Hệ màu & Tiền tệ hiển thị
- **4 Màu Người chơi:**
  - Người chơi 0 (Góc Trái-Trên): Hồng Magenta `#f01e6b`
  - Người chơi 1 (Góc Phải-Trên): Xanh Dương `#1aa3ec`
  - Người chơi 2 (Góc Trái-Dưới): Xanh Lá `#84bd22`
  - Người chơi 3 (Góc Phải-Dưới): Vàng Kim `#f2bf18`
- **Quy đổi hiển thị tiền tệ (chỉ ở tầng UI/3D, giữ nguyên số nguyên nội bộ trong `game.gd`):**
  - Tiền mặt trên Card người chơi: `cash * 1000` tách nhóm 3 số bằng khoảng trắng (ví dụ `1500` → `1 500 000`, kèm icon xấp tiền xanh lá).
  - Giá ô đất trên bàn cờ & thẻ đất: `%dK` (ví dụ `60` → `60K`, `200` → `200K`, `340` → `340K`).

### 3.2. Bố cục Bàn cờ Không Che Khuất
- Camera trực giao tại `Vector3(120, 102, 120)` nhìn về `Vector3(0, -1.5, 0)`, `size = 96.0`.
- Trên mọi cạnh bàn cờ, hướng về phía camera (`camera_toward`) là `+Z` cho cạnh 0 & 2, và `+X` cho cạnh 1 & 3:
  - **Phía xa camera (`-camera_toward`):** Dải màu nhóm đất + Mô hình nhà/khách sạn 3D sơn màu người sở hữu (chỉ xuất hiện khi ô đã có chủ).
  - **Chính giữa ô:** Tên ô in hoa chữ đậm sắc nét bằng `Label3D` nằm phẳng theo mặt đá trắng, hành lang đứng của nhân vật.
  - **Phía gần camera (`+camera_toward`):** Dải đá vát hiển thị giá tiền chữ đen đậm cỡ lớn (`60K`..`340K`), không bao giờ bị nhà hay nhân vật che khuất.

### 3.3. Nhịp độ Diễn hoạt & Tương thích Kiểm thử
- Quá trình `animate_roll()` của một lượt gồm:
  1. Hiện bong bóng thoại `"Đang tung xúc xắc..."` tại nhân vật đang đi + quăng 2 xúc xắc từ góc người chơi vào giữa sân, xoay nhiều trục và nảy 3 nhịp (`1.15s`), dừng đọc điểm (`0.30s`) kèm bảng điểm tổng dưới sân vận động.
  2. Nhân vật nhảy từng ô theo cung parabol mềm (`0.18s`/ô cho các bước thường, tự co nhẹ nếu tung 10–12 bước để tổng thời gian luôn `< 2.80s`, đảm bảo vượt qua kiểm thử `tests/flow.gd` với mốc chờ `3.0s`).
  3. Khi đáp xuống ô: hiện bong bóng kết quả (`"+150K"`, `"-100K"`, `"Mua Phố Hoa?"`...) và mở Thẻ Bất Động Sản trực quan nếu là ô đất trống cho người chơi chính.
- Giữa các hành động của Bot có nhịp nghỉ điềm tĩnh `1.15s` giúp người chơi dễ dàng quan sát toàn bộ diễn biến trên bàn.
