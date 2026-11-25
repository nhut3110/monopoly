# Kiến trúc, bản đồ và nội dung

## Hướng kỹ thuật

Đề xuất Godot 4, GDScript, renderer phù hợp Android được chọn qua prototype. Không khóa phiên bản hay giả định tính năng web/thiết bị cho đến khi kiểm tra thực tế. Xác định cấu hình tối thiểu sau khi đo trên máy mục tiêu.

- **Game core:** state machine, xác thực hành động, xử lý tiền/tài sản, xúc xắc, thẻ, lượt và thắng thua. Không phụ thuộc scene, render hay input.
- **Bot:** nhận quan sát, sinh quyết định qua API cùng luật; mô phỏng trên bản sao trạng thái, không sửa state thật.
- **Content:** map, luật, bộ thẻ, visual theme, profile bot và localization là dữ liệu có phiên bản.
- **Presentation:** bàn cờ 3D, camera, nhân vật, HUD, animation và âm thanh hiển thị theo sự kiện game core. Có thể tắt animation mà luật không thay đổi.
- **Persistence:** lưu phiên bản schema, phiên bản luật/nội dung, state, lượt, deck, RNG, profile bot và lựa chọn của người chơi. Lưu nguyên tử, backup bản trước, kiểm tra hỏng và thông báo rõ. Migration có test; nếu không tương thích, giải thích thay vì tải sai.

State machine gợi ý: thiết lập → bắt đầu lượt → quản lý tài sản → tung/di chuyển → xử lý ô hoặc quyết định bắt buộc → xử lý nợ/đấu giá/giao dịch khi cần → kết thúc lượt → kết thúc ván. Các nhánh phụ cần định nghĩa trạng thái quay lại, quyền hành động và khả năng lưu. Một nguồn RNG riêng cho luật, tạo map, profile và trình bày; log seed cùng phiên bản để tái lập. UI và animation không được tiêu thụ RNG của luật.

## Hợp đồng map

Một map khai báo `id`, phiên bản, thứ tự ô và liên kết đường đi; mỗi ô có loại, tên, nhóm, giá, tiền thuê theo cấp, giá xây/thế chấp, vị trí hiển thị và tham chiếu visual. Cấu hình bao gồm quy tắc di chuyển, ô xuất phát/tù, deck thẻ, số lượng công trình và các modifier đã được engine hỗ trợ. Mọi hiệu ứng dùng tập loại khai báo có kiểm tra, không chạy script tùy ý từ nội dung.

Validator phải kiểm tra ID duy nhất, tham chiếu tồn tại, vòng đi hợp lệ, trạng thái xuất phát/tù, nhóm màu có thể hoàn thành, giá/cấp thuê hợp lệ, deck không rỗng, hiệu ứng được hỗ trợ, tài nguyên hình ảnh tồn tại và các giới hạn cân bằng đã chọn. Lỗi phải giải thích được; map không hợp lệ không được bắt đầu.

## Thế giới và sinh bàn

- Bước 1: thành phố, bàn được thiết kế tay và luật nền ổn định.
- Bước 2: hải tặc dùng cùng core, đổi công trình, nhân vật, tên ô và nội dung thẻ; trước tiên không đổi luật để kiểm chứng tách dữ liệu.
- Bước 3: thử một luật map riêng có kiểm chứng, ví dụ kết nối hai bến tàu. Bot, UI, validator, save và mô phỏng đều cần hỗ trợ trước khi bật.
- Các chủ đề Olympus, huyền ảo và không gian là ý tưởng backlog, không khẳng định asset hay thiết kế đã sẵn sàng.
- Random map dùng seed và ràng buộc được phiên bản hóa. Bắt đầu bằng hoán đổi bố cục trong giới hạn đã kiểm chứng; xác thực trước khi dùng, thử lại hữu hạn rồi báo lỗi/fallback. Lưu cả cấu hình đã sinh, không chỉ seed. Seed cộng phiên bản và cấu hình cần thiết để tái lập; save lưu đầy đủ state và RNG.
- Editor chỉ sau khi format và validator ổn định; import file phải xác thực giới hạn kích thước và nội dung.

## Polyfork và ngân sách asset

Ưu tiên kit đồng bộ thẩm mỹ; xem từng model, kích thước, số tam giác và giấy phép cụ thể trước khi tải/import. Asset low-poly không đồng nghĩa tự động nhẹ trên mobile. Lưu GLB và tài nguyên cần thiết trong bản build để hoạt động offline; không phụ thuộc CDN lúc chạy. Ghi nguồn, URL, phiên bản, giấy phép, credit và mọi chỉnh sửa trong manifest; xác minh quyền phân phối trước khi đưa asset vào repo hoặc bản phát hành. Không giả định mã `.mjs` cùng giấy phép mesh.

Prototype bằng hình khối trước; sau đó thay có chọn lọc. Đo draw calls, tam giác, bộ nhớ, kích thước APK, thời gian tải và FPS trên thiết bị. Instancing, LOD hoặc gộp mesh chỉ áp dụng khi đo cho thấy cần; không bê nguyên cảnh nhiều trăm object vào game mà chưa profiling. Các mốc giới hạn sẽ được chốt sau baseline thiết bị.
