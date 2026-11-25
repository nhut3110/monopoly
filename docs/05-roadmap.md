# Roadmap và tiêu chí nghiệm thu

Các phase là thứ tự phụ thuộc, không phải lịch cam kết. Mỗi phase hoàn thành khi có bằng chứng tương ứng; ưu tiên kiểm chứng trò chơi và bot trước khi tăng nội dung.

## Phase 0 — Chốt nền tảng

- Chọn phiên bản Godot, xác nhận renderer, cài export templates/SDK theo hướng dẫn chính thức và xác nhận thiết bị Android mục tiêu.
- Dựng project tối thiểu, chạy desktop và xuất/cài APK thử nghiệm. Xác nhận input, lưu tệp, airplane mode và quy trình cài đè.
- Chốt bộ luật prototype và các ví dụ còn thiếu; chọn màn hình dọc/ngang qua thử nghiệm thô.
- **Nghiệm thu:** có bản thử chạy được trên Mac và thiết bị Android hoặc ghi rõ thiết bị chưa sẵn sàng; các quyết định môi trường và rủi ro được ghi lại.

## Phase 1 — Luật có thể chơi headless

- Xây core state machine, dữ liệu bàn 40 ô, RNG tách biệt, xử lý toàn bộ luật prototype và save/version.
- Tạo test các tình huống luật, test bất biến và replay lỗi bằng seed. Thêm CLI/headless runner để giả lập ván.
- **Nghiệm thu:** hoàn thành ván bốn người bằng các hành động lập trình; các tình huống quan trọng và lưu/khôi phục qua test. Luật biên chưa rõ phải đóng trước khi đánh dấu hoàn thành.

## Phase 2 — Bot cơ sở

- Sinh hành động hợp lệ, baseline mua/xây/đấu giá/giao dịch/nợ; profile ngẫu nhiên được lưu.
- Chạy ván tự đấu, log quyết định và đo seed/ghế. Sửa sai luật, bế tắc và quyết định tệ rõ ràng.
- **Nghiệm thu:** suite headless không phát hiện hành động sai luật hoặc bế tắc trong bộ chạy đã công bố; có báo cáo mẫu, số ván, seed và giới hạn. Chưa gọi bot là thông minh chỉ từ kết quả này.

## Phase 3 — Ván chơi 3D hoàn chỉnh

- Dựng một bàn thành phố bằng asset tạm; HUD, camera, tung xúc xắc, thông tin ô, mua/bán, đấu giá, nhà tù, thương lượng, nợ, kết thúc và lưu tiếp.
- Thử một người với ba bot trên Mac và Android; animation có thể tăng tốc hoặc bỏ qua.
- **Nghiệm thu:** chơi trọn ván, đóng/mở tiếp tục, đọc được trạng thái và hoàn thành mọi quyết định bằng cảm ứng; ghi lỗi và kết quả playtest trên máy thật.

## Phase 4 — Bot chiến thuật

- Thêm định giá theo vị trí và xác suất, policy thương lượng, mô phỏng rollout có ngân sách và profile khác biệt; benchmark với baseline.
- Kiểm thử đối thủ khai thác, so sánh theo seed/ghế, đo p50/p95 và chất lượng trên Android. Thử MCTS hoặc tối ưu tham số chỉ nếu số liệu chứng minh cần.
- **Nghiệm thu:** không gian lận hay vi phạm luật; báo cáo tỷ lệ thắng kèm độ bất định, ví dụ quyết định, thời gian và so sánh baseline. Mức khó được đặt tên theo bằng chứng, không theo kỳ vọng.

## Phase 5 — Thế giới thứ hai và dữ liệu hóa

- Thay asset chọn lọc có giấy phép/credit, thêm hải tặc qua cùng schema. Kiểm tra dễ đọc, hiệu năng và tính toàn vẹn asset offline.
- Thử một luật riêng sau khi core, bot và UI hỗ trợ; có thể lùi luật riêng nếu benchmark không đạt.
- **Nghiệm thu:** hai thế giới chạy cùng core, mỗi thế giới có test, save và bot tương ứng; không cần sửa code chỉ để đổi visual/nội dung nằm trong schema.

## Phase 6 — Bàn ngẫu nhiên và khả năng chơi lại

- Thiết kế generator có ràng buộc, seed/version, validator và test nhiều bàn. Tùy chọn ván ngắn sau khi chốt quy tắc định giá; album/thống kê và mở khóa trang trí nếu vòng chơi đủ mạnh.
- **Nghiệm thu:** tái lập được bàn trong cùng phiên bản, không sinh bàn không hợp lệ trong bộ kiểm thử công bố, bot xử lý được các luật và ván tạo ra được playtest.

## Phase 7 — Hoàn thiện và phát hành cá nhân

- Tối ưu theo profiling, hỗ trợ accessibility cơ bản, xử lý gián đoạn, migration save, crash và giấy phép/attribution. Kiểm tra ký APK và sao lưu khóa.
- **Nghiệm thu:** checklist Android thật, thử airplane mode, cài đè và tiếp tục save, báo cáo hiệu năng/giới hạn; chỉ phát hành hoặc chia sẻ khi được yêu cầu.

## Backlog sau đó

Editor, chia sẻ map, nhiều khu mới, thống kê nâng cao và học máy chỉ được ưu tiên sau khi bot và vòng chơi đã chứng minh hấp dẫn. Không có deadline, con số hiệu năng hay số map được xem là cam kết tại thời điểm này.
