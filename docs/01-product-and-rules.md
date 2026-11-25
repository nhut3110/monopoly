# Sản phẩm và luật chơi

## Tầm nhìn

Trải nghiệm cờ tỷ phú quen thuộc trên một bàn cờ 3D thu nhỏ, với ba đối thủ máy biết đầu tư và thương lượng. Mỗi ván khác nhau nhờ xúc xắc, sự kiện, quyết định của người chơi, tính cách bot và tùy chọn tạo bản đồ. Chơi offline và lưu lại để tiếp tục trên Android.

Không đặt trọng tâm vào cốt truyện, minigame hay tiền tệ nâng cấp sức mạnh. Tên và bộ luật hiện là thiết kế gốc của dự án; tránh mặc định sao chép tên riêng, hình ảnh hoặc nội dung độc quyền của trò chơi khác.

## Phạm vi

- Một người và ba bot trong bản đầu; lựa chọn số bot là mở rộng sau khi vòng chơi ổn định.
- Bàn thành phố 40 ô thử nghiệm, 2 xúc xắc sáu mặt, 8 nhóm đất; UI tiếng Việt trước.
- Mua đất, đấu giá, bộ màu, xây/bán công trình, thế chấp, giao dịch, thẻ, thuế, tù, phá sản và lưu/tiếp tục.
- Chế độ chuẩn: người cuối cùng chưa phá sản thắng. Chế độ giới hạn vòng là tùy chọn sau khi có luật định giá và kiểm thử cân bằng.
- Chủ đề đầu chỉ thay hình ảnh/nội dung; các luật riêng có thể bật theo map và phải được bot hỗ trợ.

## Bộ luật prototype đề xuất

Tất cả số dưới đây là dữ liệu cân bằng thử nghiệm, phải hiển thị trong màn hình luật của game. Một bộ cấu hình duy nhất là nguồn sự thật cho cả engine, UI và bot.

- Mỗi người bắt đầu 1.500 tiền; đi qua hoặc dừng tại ô xuất phát nhận 200. Di chuyển do thẻ ghi rõ có nhận tiền hay không.
- Tung 2d6, đi theo chiều bàn cờ. Tung đôi được thêm một lượt sau khi xử lý ô; tung đôi 3 lần liên tiếp thì vào tù ngay, không thực hiện di chuyển lần thứ ba.
- Đất chưa sở hữu: người dừng chọn mua theo giá niêm yết hoặc từ chối. Nếu từ chối, ngân hàng mở đấu giá công khai cho tất cả người chưa phá sản, kể cả người vừa từ chối; giá khởi điểm 1, bước tăng tối thiểu 1, chỉ được trả trong giới hạn tiền mặt. Nếu không ai trả giá, đất vẫn chưa sở hữu. Quy trình đấu giá theo lượt, bỏ lượt là rời phiên đấu giá đó.
- Đất của người khác: thu tiền thuê theo cấu hình ô và cấp công trình; đất đang thế chấp không thu thuê. Nếu nợ, người chơi có cơ hội huy động tiền trước khi phá sản.
- Sở hữu đủ nhóm màu, không có ô trong nhóm bị thế chấp: được xây trong giai đoạn quản lý tài sản. Xây đều: cấp cao nhất và thấp nhất trong nhóm chênh tối đa 1; bán công trình theo nguyên tắc ngược lại. Số cấp tối đa, giá xây, giá thuê và số lượng công trình ngân hàng được khai báo trong bộ luật; prototype dùng 4 nhà rồi 1 công trình cấp cuối, cung hữu hạn 32 nhà và 12 công trình cấp cuối.
- Bán công trình cho ngân hàng với nửa giá mua, làm tròn xuống. Khi đổi cấp cuối thành nhà, ngân hàng phải đủ 4 nhà; nếu không, chỉ được bán cả công trình cấp cuối theo thủ tục xử lý thiếu nhà được quy định và kiểm thử trước khi phát hành.
- Chỉ thế chấp đất khi toàn bộ công trình trong nhóm đã bán. Nhận giá thế chấp theo dữ liệu ô; chuộc bằng giá thế chấp cộng 10%, làm tròn lên. Đất thế chấp vẫn thuộc chủ sở hữu, không thu thuê và không cho xây trong nhóm.
- Giao dịch chỉ diễn ra khi không có hành động bắt buộc đang chờ xử lý; người chủ động đưa đề nghị một lần, người nhận chấp nhận, từ chối hoặc phản đề nghị. Gồm tiền mặt, đất không có công trình trong nhóm và thẻ ra tù có thể chuyển nhượng; không có khoản vay hay lời hứa tương lai. Đất thế chấp được phép chuyển, chủ mới trả phí chuyển 10% giá thế chấp ngay; muốn chuộc trả thêm giá thế chấp cộng 10% tại thời điểm chuộc. Không đủ khả năng trả phí thì giao dịch không hợp lệ.
- Vào tù: chuyển trực tiếp đến ô tù, không nhận tiền qua xuất phát. Ra tù bằng trả 50 trước khi tung, dùng thẻ, hoặc tung đôi; có tối đa 3 lượt thử. Nếu lần thứ 3 không tung đôi, phải trả 50 rồi di chuyển theo kết quả đã tung. Tung đôi để ra tù không được thêm lượt. Trong tù vẫn sở hữu, thu tiền thuê và giao dịch hợp lệ.
- Thẻ sự kiện được xào bằng RNG của ván, rút lần lượt và đưa về cuối bộ sau khi xử lý; thẻ ra tù giữ ngoài bộ cho đến khi dùng hoặc chuyển trả ngân hàng. Mỗi thẻ có hiệu ứng khai báo rõ, không chạy mã tùy ý.
- Khi nợ: cho phép bán công trình, thế chấp và giao dịch. Nếu không thể hoặc chọn không huy động đủ, phá sản. Nợ người chơi: tài sản còn lại và thẻ chuyển cho chủ nợ, áp dụng phí chuyển thế chấp như trên; nếu không trả nổi phí, xử lý theo quy tắc phá sản dây chuyền trước khi tiếp tục. Nợ ngân hàng: trả tài sản về ngân hàng, đất được đấu giá từng ô. Tiền và công trình xử lý nhất quán theo thứ tự quy định trong engine; không tạo tiền hoặc tài sản trùng.

Các tình huống cung công trình thiếu, đấu giá đồng thời, phá sản dây chuyền và thứ tự thanh toán phải được mô tả thành ví dụ thực thi và khóa bằng test trước khi coi luật là ổn định. Không quảng bá là bản sao chính xác của một ấn bản thương mại.

## Giao diện và trải nghiệm

Chân dung hay ngang màn hình chưa chốt: phase nguyên mẫu so sánh hai phương án trên điện thoại. Bàn cờ đọc được trạng thái sở hữu, nhóm màu, cấp nhà và thế chấp mà không phụ thuộc duy nhất vào màu sắc. Có camera tổng quan, chọn ô để xem chi tiết và log hành động. Thao tác quan trọng cần xác nhận rõ; có điều khiển tốc độ bot và bỏ qua animation. Không giới hạn thời gian lượt.

## Dữ liệu cần chốt qua thử nghiệm

Thời lượng ván, số ô, bảng giá và thuê, lượng sự kiện tích cực/tiêu cực, cách tính điểm ván ngắn, giao diện thương lượng, mức giải thích của bot và luật riêng từng thế giới. Không coi một giá trị thử nghiệm là cân bằng chỉ vì luật hợp lệ.
