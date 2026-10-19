"""Mốc thời gian chung cho hình (compose.py) và tiếng (audio.py). Đơn vị: giây, 30 khung/giây, 120 BPM."""
FPS = 30
DURATION = 30.0
BPM = 120
BEAT = 60 / BPM

# Cảnh: (bắt đầu, kết thúc)
OPEN = (0.0, 3.0)        # cutscene: thẻ việc rối → xếp gọn
TODAY = (3.0, 7.0)       # giao diện thật: tick hoàn thành, thưởng
WARDROBE = (7.0, 7.9)    # giao diện thật: tủ đồ
MONTAGE = (7.9, 12.0)    # ảnh đại diện thật, 6 bộ phối, đổi theo phách
CARE = (12.0, 17.0)      # giao diện thật: cho ăn, nựng, dọn nhà
GAMES = (17.0, 23.0)     # gameplay thật: Nhảy Mây, Giỏ Quà, Lật Thẻ
CLIMAX = (23.0, 26.0)    # phòng ngủ đẹp nhất, ăn mừng
END = (26.0, 30.0)       # icon + tên + tagline

TAP = 1.45               # vịt "chạm" để xếp thẻ
TICK = 3.8               # khoảnh khắc tick việc trong footage
COIN = 6.45              # đồng xu bay qua khung (object wipe)
OUTFIT_CHANGES = [8.0, 8.5, 9.0, 9.5, 10.0, 10.5]
CARE_CUTS = [12.0, 13.5, 15.3]
GAME_CUTS = [17.0, 19.0, 21.0]
HOPS = [23.55, 24.15, 24.75]
ICON = 26.0

# Tiêu đề: (vào, ra, dòng chữ)
TITLES = [
    (0.45, 1.95, "Ngày hơi rối?"),
    (2.0, 2.85, "Có mình đây!"),
    (4.5, 6.6, "Việc nhỏ. Niềm vui lớn."),
    (8.15, 11.85, "Một bạn nhỏ. Nhiều cá tính."),
    (12.25, 14.9, "Chăm chút mỗi ngày."),
    (17.15, 19.0, "Chơi một chút!"),
]
