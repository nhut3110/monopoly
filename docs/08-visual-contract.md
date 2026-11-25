# Bố cục bàn cờ theo ảnh tham khảo

## Thứ bậc thông tin

1. Bàn cờ ở giữa, bốn bảng người chơi ở bốn góc.
2. Mỗi ô có phần kiến trúc thu nhỏ phía ngoài, tên ở giữa và giá phía trong; vạch ô và dải màu sở hữu tách biệt.
3. Chữ nghiêng nhẹ, đủ đậm, xoay theo cạnh và luôn đọc thuận chiều từ camera. Không có hộp giá nổi.
4. Nhân vật là quân cờ lớn hơn tỷ lệ kiến trúc, có đế màu và dấu chỉ lượt; camera bám khi di chuyển.
5. Xúc xắc và thao tác chính ở lòng bàn. Tài sản, tạm nghỉ, âm thanh là icon ở góc phải dưới.
6. Bốn ô góc dùng nền màu và điểm nhấn theo chủ đề; ô sự kiện có biểu tượng riêng; các chồng tiền ngoài bàn phản ánh tiền mặt.

## Quy ước mô hình

Đây là diorama bàn cờ: công trình được thu đồng đều theo bounding box, giới hạn footprint 4,8 đơn vị và chiều cao 5,5; quân cờ nhân vật phóng đồng đều 2,8 lần. Đây là lựa chọn mỹ thuật phục vụ yêu cầu tỷ lệ trong game, không phải mô phỏng kích thước kiến trúc thực. Không thay đổi mesh nguồn. Ghi nhận nguồn và biến đổi trong CREDITS.

Phố Hội dùng 28 model kiến trúc khác nhau cho 28 ô có thể mua. Đạo cụ trang trí có thể lặp lại (cây, đèn). Hai map còn lại vẫn cần thêm nội dung để giảm việc lặp công trình.

## Kiểm tra

Render `tests/capture.gd` tạo ảnh welcome, setup ba map, toàn bàn, chọn ô và lúc nhân vật di chuyển. Xem toàn bàn ở 1280×720, kiểm tra giá ở cả bốn cạnh và vùng nút không đè lên đường đi. Xác nhận bằng mắt, không suy ra chất lượng hình ảnh từ test luật. Android vẫn cần kiểm tra trên thiết bị thật.
