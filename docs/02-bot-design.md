# Thiết kế bot

## Mục tiêu và giới hạn

Bot chơi hợp lệ, đủ mạnh và đa dạng, không biết trước RNG, không xem thông tin ẩn của người khác, không được thưởng tiền hoặc xúc xắc ưu ái. Các phép tính chạy offline, với ngân sách thời gian thích ứng trên thiết bị. Không hứa giống người thật hoặc mạnh hơn người trước khi có bằng chứng.

Tách độ khó khỏi tính cách: độ khó kiểm soát chất lượng đánh giá, số ứng viên và ngân sách tính; tính cách điều chỉnh ưu tiên trong giới hạn hợp lý. Ba bot được lấy profile riêng mỗi ván từ RNG khởi tạo riêng; lưu profile vào save. Có thể dùng tên/model ngẫu nhiên độc lập với profile.

## Pipeline quyết định

1. Nhận quan sát được phép và cấu hình luật; không đọc trạng thái RNG tương lai hay thứ tự thẻ úp.
2. Sinh hành động hợp lệ bằng cùng engine dùng cho người chơi.
3. Chấm điểm nhanh từng ứng viên: tiền dự phòng, nghĩa vụ gần hạn, nhóm đất, giá/cấp xây, khả năng thu thuê, mức đe dọa đối thủ, tài sản thế chấp và giá trị giao dịch.
4. Với quyết định quan trọng, mô phỏng các ứng viên tốt nhất trong số lần/thời gian giới hạn. Lấy mẫu thẻ úp và xúc xắc từ thông tin hợp lệ; hành động tương lai dùng policy xấp xỉ cho cả bốn người.
5. So sánh lợi ích và rủi ro, chọn hành động; tính cách và biến thiên có kiểm soát chỉ phân biệt các lựa chọn gần nhau. Bắt buộc fallback về hành động hợp lệ nếu hết ngân sách.
6. Ghi log giải thích ngắn ở chế độ debug; UI chỉ hiển thị các lý do thích hợp với thông tin công khai.

Mô phỏng ngắn không mặc định suy ra tỷ lệ thắng chính xác. Chỉ báo tỷ lệ thắng khi số mẫu, độ dài và độ tin cậy được đo; những trường hợp khác dùng điểm tương đối và rủi ro ước lượng. Rollout là lựa chọn thử đầu tiên; MCTS chỉ thêm khi benchmark cho thấy lợi ích. Markov cho tần suất dài hạn là tùy chọn, cần phản ánh luật tù và di chuyển đặc biệt; không thay thế phân tích vị trí gần.

## Hành động cần xử lý

- Mua/từ chối và đấu giá: xét giá trị sở hữu, giá trần, nguy cơ thiếu tiền, bộ màu và vị trí.
- Xây/bán/thế chấp: sinh các thay đổi hợp lệ theo luật xây đều và cung ngân hàng; dự phòng cho chi phí tiềm năng, không chỉ tối đa thu nhập kỳ vọng.
- Thương lượng: sinh số lượng giới hạn đề nghị tiền/đất/thẻ; định giá cho cả hai bên và đối chiếu chênh lệch sức mạnh sau giao dịch. Chấp nhận, từ chối hoặc phản đề nghị; đặt giới hạn số lần phản đề nghị để tránh vòng lặp. Ước lượng hành vi đối thủ từ quan sát được, không giả định biết tính cách bí mật.
- Trong tù và khi nợ: so sánh phương án trả phí/dùng thẻ/thử xúc xắc hoặc thanh lý; ưu tiên tránh phá sản khi có phương án khả thi.

## Profile và độ khó

Profile gồm mức chấp nhận rủi ro, tiền dự phòng, ưu tiên hoàn thành nhóm, chủ động giao dịch và chú ý người dẫn đầu. Sinh trong khoảng đã kiểm chứng, có thể tương quan để tránh tổ hợp vô lý. Không cho random lật ngược một hành động rõ ràng vượt trội; mọi profile vẫn cần vượt ngưỡng chất lượng tối thiểu.

- Dễ: policy hợp lệ, đánh giá đơn giản và có sai sót giới hạn; không gian lận.
- Trung bình: đánh giá đầy đủ, thương lượng cơ bản, ngân sách tính nhỏ.
- Khó/chuyên gia: thêm ứng viên, mô phỏng và điều chỉnh rủi ro; chỉ công bố khi benchmark cho thấy mức cao thực sự mạnh hơn.

## Đánh giá thực nghiệm

Tạo baseline: bot mua theo ngưỡng, bot bảo thủ và bot tham lam; thêm đối thủ chuyên khai thác giao dịch. Chạy nhiều seed, luân phiên ghế, dùng chung cấu hình bàn; tách seed phát triển khỏi seed đánh giá. Ghi số ván, tỷ lệ thắng kèm khoảng tin cậy, thời lượng, lợi thế theo ghế, tỷ lệ phá sản, hành động sai luật và độ trễ p50/p95. Một game bốn người có may rủi lớn, nên không suy luận bot mạnh từ vài ván.

Xem lại log các quyết định bất thường, ví dụ bán mảnh cuối giúp người dẫn đầu hoàn thiện nhóm với giá thấp, xây hết tiền trước khu nguy hiểm, hoặc lặp đề nghị vô ích. Kiểm tra khả năng bị người thật khai thác và cảm giác đối đầu qua playtest. Tính cách khác nhau phải thể hiện qua phân phối hành động theo ngữ cảnh, không chỉ khác tên.

Mục tiêu ban đầu: không có hành động sai luật trong bộ test; thời gian suy nghĩ mục tiêu p95 dưới 2 giây cho quyết định thông thường trên thiết bị mục tiêu, với tùy chọn bỏ qua animation. Đây là mục tiêu cần đo, không phải cam kết hiệu năng. So sánh tỷ lệ thắng với baseline trên tập seed độc lập trước khi công bố cấp độ.
