# Kiểm thử và Android

## Ma trận kiểm thử

| Lớp | Cần xác minh | Cách thực hiện |
| --- | --- | --- |
| Luật | Tung đôi, 3 lần đôi, qua xuất phát, tù, đấu giá, thuê, xây đều, thiếu nhà, thế chấp, giao dịch, phá sản và chiến thắng | Test tự động theo ví dụ và tình huống biên; kiểm tra tổng tiền/tài sản theo giao dịch, không có hành động trái luật |
| State/save | Lưu ở lượt thường, chờ giao dịch/đấu giá/nợ, trong tù và sau khôi phục | So sánh state và các bước tiếp theo có cùng RNG; thử file thiếu/hỏng và schema khác |
| Bot | Mọi lựa chọn hợp lệ; không lặp, không biết thông tin ẩn, không gian lận | Unit test, ván tự đấu headless, đối thủ khai thác và log tái lập bằng seed |
| Map | Dữ liệu và luật riêng hợp lệ | Test validator, nhiều seed tạo map, snapshot cấu hình và test bot theo từng luật map |
| UI | Đọc được thông tin, chọn ô, mua/bán, đàm phán, điều hướng, màn hình nhỏ | Chạy desktop ở nhiều tỷ lệ, test thao tác và xem ảnh; đo touch target trên thiết bị |
| Android | Cài, mở, tiếp tục, cảm ứng, vòng đời ứng dụng, hiệu năng | Máy thật: xoay/chuyển app/khóa màn hình, thiếu bộ nhớ nếu tái hiện được, airplane mode, profile và đo pin trong phiên thực tế |

Ván tự đấu cần timeout và lưu seed, phiên bản, lượt cuối cùng khi lỗi. Kiểm tra quy luật bảo toàn trong phạm vi ngân hàng: chuyển tiền không tự tạo/mất tiền ngoài các khoản ngân hàng được định nghĩa; mỗi tài sản có tối đa một chủ; công trình và thẻ được hạch toán đúng. Test bất biến không thay thế test kết quả luật cụ thể.

## Vòng lặp phát triển

1. Chạy unit test core và ván headless trên Mac sau mỗi thay đổi liên quan.
2. Mở bản desktop để xem bàn cờ, thao tác và kiểm tra bố cục; chụp ảnh khi cần đánh giá trực quan.
3. Cài bản Android nội bộ ở từng milestone, đo hành vi và hiệu năng trên điện thoại thật. Emulator là bổ sung, không thay thế cảm ứng/hardware thật.
4. Đóng game, bật chế độ máy bay, mở lại, tải save và chơi tiếp. Xác minh không tải asset hoặc yêu cầu dịch vụ mạng khi chạy.
5. Playtest nhiều người, ghi thời gian ván, các lỗi hiểu luật, cảm giác công bằng và các quyết định bot gây bất ngờ hoặc vô lý.

Web export là thử nghiệm tùy chọn, không phải điều kiện thành công Android. Nếu thử phải kiểm tra renderer, đầu vào, âm thanh và hiệu năng trên trình duyệt; không suy diễn kết quả Android từ web.

## Thiết lập Android cần xác nhận

Kiểm tra phiên bản Godot, export templates, JDK và Android SDK tương thích theo tài liệu chính thức của phiên bản chọn; cài khi bắt đầu triển khai, không mặc định đã có. Bật USB debugging khi dùng thiết bị thật và xác nhận được nhận diện. Debug build cho thử nghiệm; bản phát hành cần package name cố định và khóa ký được lưu an toàn, sao lưu riêng. Cài đè chỉ giữ dữ liệu khi package và chữ ký tương thích; không xóa app hoặc dữ liệu người dùng để xử lý lỗi khi chưa được đồng ý.

Hiện tại chỉ xác nhận `java` có trong PATH; chưa xác nhận Godot, Android SDK, adb, thiết bị hay bản build. Cần kiểm tra lại khi triển khai.
