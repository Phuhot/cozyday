// Danh mục đồ của Cozii! — dựa trên danh mục gốc của Cozyday (ID, tên, hình vẽ giữ nguyên).
// Giá trong bảng là giá gốc của bản iOS; giá bán trong Cozii = giá gốc × ECONOMY.priceMultiplier (xem economy.ts).
import { ECONOMY } from './economy'

export type RoomId = 'study' | 'bedroom' | 'kitchen' | 'bath' | 'garden'
export type PetSlot = 'species' | 'fur' | 'hat' | 'glasses' | 'neck' | 'outfit' | 'back'
export type ItemSlot =
  | 'wall' | 'lamp' | 'desk' | 'plant' | 'seat' | 'studyTheme'
  | 'bedroomTheme' | 'bed' | 'nightstand' | 'bedroomWall' | 'closet' | 'bedroomRug' | 'plush'
  | 'kitchenTheme' | 'stove' | 'fridge' | 'dining' | 'kitchenWall' | 'treat'
  | 'bathTheme' | 'tub' | 'sink' | 'bathShelf' | 'bathMat' | 'bathToy'
  | 'gardenTheme' | 'tree' | 'flowerBed' | 'gardenSeat' | 'pond' | 'gardenDeco'
  | PetSlot

export type Source = 'starter' | 'shop' | 'capsule' | 'reward'

export interface CatalogItem {
  id: string
  slot: ItemSlot
  name: string
  /** Giá xu (0 = quà khởi đầu / phần thưởng, không bán). */
  price: number
  /** Hạng thị trấn cần đạt để mua (1–6). */
  rank: number
  blurb: string
  source: Source
}

// [id, slot, tên, giá gốc iOS, cấp gốc iOS, mô tả]
type Row = [string, ItemSlot, string, number, number, string]
const ROWS: Row[] = [
  ['desk.pine', 'desk', "Bàn gỗ thông", 0, 1, "Mộc mạc, vừa đủ cho một cuốn sổ."],
  ['desk.lavender', 'desk', "Bàn lavender", 40, 1, "Màu tím nhạt dịu mắt."],
  ['desk.sage', 'desk', "Bàn viết xanh sage", 70, 1, "Rộng rãi, có ngăn kéo nhỏ."],
  ['seat.rug', 'seat', "Thảm tròn kem", 0, 1, "Chỗ nằm yêu thích của mèo."],
  ['seat.cushion', 'seat', "Đệm ngồi tím", 30, 1, "Êm như mây."],
  ['seat.armchair', 'seat', "Ghế bành nhỏ", 90, 1, "Hợp để đọc sách buổi tối."],
  ['plant.cactus', 'plant', "Xương rồng mini", 0, 1, "Không cần tưới nhiều."],
  ['plant.monstera', 'plant', "Cây lá xẻ", 35, 1, "Lá to, xanh mát."],
  ['plant.tulip', 'plant', "Chậu tulip", 55, 1, "Ba bông hoa nhỏ."],
  ['lamp.candle', 'lamp', "Nến thơm", 20, 1, "Ánh sáng ấm, mùi vani."],
  ['lamp.desk', 'lamp', "Đèn bàn tròn", 45, 1, "Đủ sáng cho buổi học muộn."],
  ['lamp.paper', 'lamp', "Đèn giấy", 75, 1, "Tròn và mềm như mặt trăng."],
  ['wall.clock', 'wall', "Đồng hồ tròn", 25, 1, "Nhắc nhẹ rằng thời gian vẫn trôi."],
  ['wall.poster', 'wall', "Tranh đồi xanh", 35, 1, "Một buổi sáng yên tĩnh."],
  ['wall.shelf', 'wall', "Kệ sách nhỏ", 60, 1, "Ba cuốn sách và một chậu cây."],
  ['wall.corkboard', 'wall', "Bảng ghim ảnh", 45, 1, "Ảnh kỷ niệm và vài tờ giấy nhớ."],
  ['lamp.mushroom', 'lamp', "Đèn nấm", 55, 1, "Chiếc nấm đỏ chấm bi tỏa sáng."],
  ['desk.computer', 'desk', "Bàn có máy tính", 110, 4, "Màn hình nhỏ dán đầy sticker."],
  ['plant.bonsai', 'plant', "Cây bonsai", 80, 3, "Kiên nhẫn từng chút một."],
  ['seat.beanbag', 'seat', "Ghế lười", 65, 1, "Ngồi xuống là không muốn dậy."],
  ['studyTheme.cream', 'studyTheme', "Kem ấm", 0, 1, "Tường tím nhạt, sàn gỗ sáng."],
  ['studyTheme.mint', 'studyTheme', "Sọc bạc hà", 40, 1, "Tường sọc xanh mát, sàn gỗ."],
  ['studyTheme.night', 'studyTheme', "Đêm sao", 70, 3, "Tường xanh đêm điểm sao, cửa sổ có trăng."],
  ['studyTheme.sakura', 'studyTheme', "Hoa anh đào", 90, 5, "Cánh hoa hồng bay ngoài cửa sổ."],
  ['bedroomTheme.lilac', 'bedroomTheme', "Tím oải hương", 0, 1, "Dịu nhẹ cho giấc ngủ."],
  ['bedroomTheme.cloud', 'bedroomTheme', "Mây xanh", 40, 1, "Tường xanh trời có mây trắng."],
  ['bedroomTheme.candy', 'bedroomTheme', "Sọc kẹo ngọt", 50, 1, "Sọc hồng trắng như kẹo."],
  ['bedroomTheme.galaxy', 'bedroomTheme', "Thiên hà", 100, 5, "Ngủ giữa những vì sao."],
  ['bed.mat', 'bed', "Nệm đơn", 0, 1, "Nệm mỏng, gối tròn."],
  ['bed.wood', 'bed', "Giường gỗ", 60, 1, "Chăn kẻ ô ấm áp."],
  ['bed.canopy', 'bed', "Giường rèm", 120, 4, "Rèm voan như trong truyện cổ tích."],
  ['bed.cloud', 'bed', "Giường đám mây", 150, 7, "Mềm như đang bay."],
  ['nightstand.crate', 'nightstand', "Thùng gỗ", 0, 1, "Đặt cốc nước và cuốn sách."],
  ['nightstand.lamp', 'nightstand', "Tủ & đèn ngủ", 40, 1, "Chụp đèn vàng dịu."],
  ['nightstand.radio', 'nightstand', "Radio cổ", 55, 1, "Phát nhạc nhẹ trước khi ngủ."],
  ['nightstand.moon', 'nightstand', "Đèn mặt trăng", 70, 3, "Một vầng trăng nhỏ bên gối."],
  ['bedroomWall.garland', 'bedroomWall', "Dây cờ", 25, 1, "Cờ tam giác nhiều màu."],
  ['bedroomWall.fairy', 'bedroomWall', "Dây đèn đom đóm", 45, 1, "Lấp lánh mỗi tối."],
  ['bedroomWall.moon', 'bedroomWall', "Tranh trăng sao", 50, 1, "Trăng khuyết ngủ trên mây."],
  ['bedroomWall.dreamcatcher', 'bedroomWall', "Lưới bắt giấc mơ", 65, 3, "Giữ lại những giấc mơ đẹp."],
  ['closet.dresser', 'closet', "Tủ ngăn kéo", 50, 1, "Ba ngăn tay nắm tròn."],
  ['closet.mirror', 'closet', "Gương đứng", 60, 1, "Ngắm bộ đồ mới."],
  ['closet.wardrobe', 'closet', "Tủ quần áo", 80, 1, "Hai cánh, có móc treo khăn."],
  ['closet.vanity', 'closet', "Bàn trang điểm", 95, 4, "Gương tròn viền đèn."],
  ['bedroomRug.round', 'bedroomRug', "Thảm tròn", 0, 1, "Thảm len mềm."],
  ['bedroomRug.heart', 'bedroomRug', "Thảm trái tim", 35, 1, "Hồng và lông xù."],
  ['bedroomRug.cloud', 'bedroomRug', "Thảm mây", 45, 1, "Bước chân lên mây."],
  ['bedroomRug.rainbow', 'bedroomRug', "Thảm cầu vồng", 70, 3, "Bảy sắc dưới chân."],
  ['plush.yarn', 'plush', "Cuộn len", 15, 1, "Đồ chơi yêu thích muôn thuở."],
  ['plush.ball', 'plush', "Bóng sọc", 20, 1, "Lăn lông lốc khắp phòng."],
  ['plush.teddy', 'plush', "Gấu bông", 40, 1, "Bạn ngủ cùng mỗi đêm."],
  ['plush.dino', 'plush', "Khủng long bông", 60, 3, "Hung dữ… một chút xíu."],
  ['kitchenTheme.mint', 'kitchenTheme', "Gạch bạc hà", 0, 2, "Gạch men xanh nhạt."],
  ['kitchenTheme.gingham', 'kitchenTheme', "Ca rô đỏ", 45, 2, "Như một buổi dã ngoại."],
  ['kitchenTheme.lemon', 'kitchenTheme', "Chanh vàng", 55, 2, "Tường vàng chanh tươi sáng."],
  ['kitchenTheme.wood', 'kitchenTheme', "Gỗ ấm", 75, 3, "Ốp gỗ kiểu nhà gỗ trên núi."],
  ['stove.basic', 'stove', "Bếp nhỏ", 0, 2, "Hai bếp và một chiếc nồi."],
  ['stove.retro', 'stove', "Bếp cổ điển", 70, 2, "Màu kem, núm xoay tròn."],
  ['stove.oven', 'stove', "Lò nướng bánh", 90, 4, "Mùi bánh quy thơm lừng."],
  ['stove.hearth', 'stove', "Bếp củi", 110, 6, "Lửa reo tí tách."],
  ['fridge.mini', 'fridge', "Tủ lạnh mini", 30, 2, "Vừa đủ sữa và trái cây."],
  ['fridge.retro', 'fridge', "Tủ lạnh retro", 70, 2, "Bo tròn màu xanh ngọc."],
  ['fridge.pink', 'fridge', "Tủ lạnh hồng", 80, 3, "Màu hồng sữa dâu."],
  ['fridge.magnets', 'fridge', "Tủ lạnh nam châm", 95, 4, "Dán đầy nam châm và tranh vẽ."],
  ['dining.stool', 'dining', "Bàn đẩu", 0, 2, "Bàn thấp và một chiếc đẩu."],
  ['dining.round', 'dining', "Bàn tròn", 50, 2, "Hai ghế tựa nhỏ."],
  ['dining.picnic', 'dining', "Bàn khăn ca rô", 65, 3, "Khăn trải bàn đỏ trắng."],
  ['dining.long', 'dining', "Bàn dài có nến", 100, 5, "Cho những bữa tối thật đặc biệt."],
  ['kitchenWall.clock', 'kitchenWall', "Đồng hồ trái chanh", 30, 2, "Tích tắc vị chua."],
  ['kitchenWall.pans', 'kitchenWall', "Giá treo nồi", 35, 2, "Chảo, muôi, xẻng đủ cả."],
  ['kitchenWall.fruit', 'kitchenWall', "Tranh trái cây", 40, 2, "Lê, táo và chùm nho."],
  ['kitchenWall.jars', 'kitchenWall', "Kệ hũ gia vị", 45, 3, "Hũ kẹo, hũ bánh, hũ trà."],
  ['treat.tea', 'treat', "Ấm trà", 15, 2, "Trà nóng và một chiếc tách."],
  ['treat.bread', 'treat', "Giỏ bánh mì", 25, 2, "Bánh mì mới ra lò."],
  ['treat.ramen', 'treat', "Bát mì", 30, 2, "Có trứng và hành lá."],
  ['treat.pizza', 'treat', "Pizza", 35, 3, "Một lát đã bị ăn mất."],
  ['treat.cake', 'treat', "Bánh kem dâu", 40, 3, "Mừng một ngày làm việc tốt."],
  ['bathTheme.aqua', 'bathTheme', "Gạch xanh nước", 0, 3, "Mát và sạch sẽ."],
  ['bathTheme.pink', 'bathTheme', "Gạch hồng", 40, 3, "Hồng phấn dễ thương."],
  ['bathTheme.ocean', 'bathTheme', "Đại dương", 70, 4, "Sóng và bong bóng trên tường."],
  ['bathTheme.marble', 'bathTheme', "Đá cẩm thạch", 90, 5, "Sang trọng như spa."],
  ['tub.basin', 'tub', "Chậu tắm gỗ", 0, 3, "Chậu tròn kiểu suối nước nóng."],
  ['tub.shower', 'tub', "Vòi sen", 60, 3, "Rèm tắm chấm bi."],
  ['tub.claw', 'tub', "Bồn tắm chân", 80, 3, "Bồn sứ trắng có chân."],
  ['tub.bubble', 'tub', "Bồn đầy bọt", 100, 5, "Bọt xà phòng tràn ra ngoài."],
  ['sink.basic', 'sink', "Bồn rửa", 0, 3, "Bồn rửa tay và cốc bàn chải."],
  ['sink.mirror', 'sink', "Bồn rửa & gương", 45, 3, "Gương tròn viền gỗ."],
  ['sink.shell', 'sink', "Gương vỏ sò", 75, 4, "Như nàng tiên cá."],
  ['bathShelf.towels', 'bathShelf', "Kệ khăn", 25, 3, "Khăn gấp gọn ba màu."],
  ['bathShelf.bottles', 'bathShelf', "Kệ chai lọ", 35, 3, "Dầu gội, sữa tắm, nến thơm."],
  ['bathShelf.fern', 'bathShelf', "Kệ dương xỉ", 45, 4, "Cây thích hơi ẩm."],
  ['bathMat.basic', 'bathMat', "Thảm chân", 0, 3, "Thảm bông hút nước."],
  ['bathMat.duck', 'bathMat', "Thảm vịt vàng", 30, 3, "Hình chú vịt nhỏ."],
  ['bathMat.wave', 'bathMat', "Thảm sóng", 40, 4, "Xanh như biển."],
  ['bathToy.duck', 'bathToy', "Vịt cao su", 10, 3, "Kêu chít chít."],
  ['bathToy.boat', 'bathToy', "Thuyền giấy", 20, 3, "Ra khơi trong bồn tắm."],
  ['bathToy.bubbles', 'bathToy', "Bong bóng xà phòng", 25, 3, "Bay lơ lửng khắp phòng."],
  ['bathToy.whale', 'bathToy', "Cá voi phun nước", 45, 4, "Phun một tia nước nhỏ."],
  ['gardenTheme.day', 'gardenTheme', "Ngày nắng", 0, 4, "Trời xanh, mây trắng, cỏ non."],
  ['gardenTheme.sunset', 'gardenTheme', "Hoàng hôn", 50, 4, "Trời cam hồng cuối ngày."],
  ['gardenTheme.night', 'gardenTheme', "Đêm đom đóm", 80, 5, "Trăng tròn và đom đóm."],
  ['gardenTheme.snow', 'gardenTheme', "Mùa đông", 100, 6, "Tuyết phủ trắng khu vườn."],
  ['tree.sapling', 'tree', "Cây non", 0, 4, "Rồi sẽ lớn, như bạn."],
  ['tree.apple', 'tree', "Cây táo", 60, 4, "Táo đỏ chín mọng."],
  ['tree.pine', 'tree', "Cây thông", 70, 5, "Xanh quanh năm."],
  ['tree.sakura', 'tree', "Cây anh đào", 100, 6, "Hoa hồng phủ kín cành."],
  ['flowerBed.daisy', 'flowerBed', "Hoa cúc", 0, 4, "Cúc trắng nhụy vàng."],
  ['flowerBed.tulip', 'flowerBed', "Luống tulip", 40, 4, "Đỏ, vàng và hồng."],
  ['flowerBed.mushroom', 'flowerBed', "Nấm đỏ", 45, 4, "Nấm chấm bi mọc sau mưa."],
  ['flowerBed.sunflower', 'flowerBed', "Hướng dương", 55, 5, "Luôn quay về phía mặt trời."],
  ['gardenSeat.stump', 'gardenSeat', "Gốc cây", 0, 4, "Ghế tự nhiên."],
  ['gardenSeat.bench', 'gardenSeat', "Ghế băng", 50, 4, "Ngồi ngắm mây trôi."],
  ['gardenSeat.swing', 'gardenSeat', "Xích đu", 85, 5, "Đung đưa nhè nhẹ."],
  ['gardenSeat.hammock', 'gardenSeat', "Võng", 95, 6, "Ngủ trưa giữa vườn."],
  ['pond.puddle', 'pond', "Vũng nước", 0, 4, "Để nhảy vào sau cơn mưa."],
  ['pond.lily', 'pond', "Hồ hoa súng", 60, 4, "Có một chú ếch ngồi chơi."],
  ['pond.koi', 'pond', "Hồ cá koi", 90, 5, "Hai chú cá đỏ trắng."],
  ['pond.fountain', 'pond', "Đài phun nước", 110, 6, "Nước reo róc rách."],
  ['gardenDeco.fence', 'gardenDeco', "Hàng rào gỗ", 20, 4, "Rào trắng nhỏ xinh."],
  ['gardenDeco.mailbox', 'gardenDeco', "Hộp thư", 30, 4, "Chờ thư từ bạn bè."],
  ['gardenDeco.birdhouse', 'gardenDeco', "Nhà chim", 40, 4, "Có chú chim vàng ghé thăm."],
  ['gardenDeco.lantern', 'gardenDeco', "Đèn lồng giấy", 50, 5, "Sáng dịu khi trời tối."],
  ['gardenDeco.tent', 'gardenDeco', "Lều cắm trại", 120, 7, "Cắm trại ngay trong vườn."],
  ['species.cat', 'species', "Mèo", 0, 1, "Tai nhọn, đuôi cong, thích nằm thảm."],
  ['species.bunny', 'species', "Thỏ", 60, 2, "Tai dài, đuôi bông, nhảy lò cò khi vui."],
  ['species.hamster', 'species', "Hamster", 70, 3, "Má phúng phính, giấu hạt trong má."],
  ['species.bear', 'species', "Gấu nhỏ", 80, 4, "Tai tròn, mõm sáng màu, rất thích mật ong."],
  ['species.fox', 'species', "Cáo", 100, 6, "Đuôi xù chóp trắng, tò mò mọi thứ."],
  ['species.puppy', 'species', "Cún con", 80, 2, "Tai cụp, đuôi ngoáy tít khi gặp bạn."],
  ['species.duck', 'species', "Vịt con", 60, 2, "Mỏ cam, lạch bạch theo bạn khắp nhà."],
  ['species.frog', 'species', "Ếch xanh", 70, 3, "Ộp ộp, thích ngồi trên lá súng."],
  ['species.capybara', 'species', "Capybara", 90, 3, "Bình thản trước mọi chuyện, mê tắm suối nước nóng."],
  ['species.panda', 'species', "Gấu trúc", 110, 5, "Mắt quầng tròn, mê măng tre."],
  ['species.penguin', 'species', "Chim cánh cụt", 100, 5, "Bụng tròn, đi lạch bạch."],
  ['fur.cream', 'fur', "Kem sữa", 0, 1, "Màu lông nguyên bản."],
  ['fur.snow', 'fur', "Trắng tuyết", 25, 1, "Trắng mịn như bông."],
  ['fur.ginger', 'fur', "Cam gừng", 30, 1, "Ấm áp như nắng chiều."],
  ['fur.smoke', 'fur', "Xám khói", 30, 1, "Dịu dàng, hơi bí ẩn."],
  ['fur.cocoa', 'fur', "Nâu cacao", 35, 1, "Như một cốc cacao nóng."],
  ['fur.peach', 'fur', "Hồng đào", 40, 2, "Ngọt ngào và vui tươi."],
  ['fur.midnight', 'fur', "Đen nửa đêm", 45, 3, "Lông đen, mắt vàng như trăng."],
  ['fur.lilac', 'fur', "Tím lilac", 55, 5, "Hiếm có, như hoa tử đinh hương."],
  ['fur.honey', 'fur', "Vàng mật ong", 35, 1, "Vàng ươm như nắng sớm."],
  ['fur.mint', 'fur', "Xanh bạc hà", 45, 3, "Mát lạnh, hợp với ếch và vịt."],
  ['fur.sky', 'fur', "Xanh da trời", 50, 4, "Như một buổi trưa không mây."],
  ['hat.sprout', 'hat', "Mầm lá", 0, 1, "Chiếc lá nhỏ mọc trên đầu."],
  ['hat.bow', 'hat', "Nơ hồng", 20, 1, "Nhỏ xinh, cài một bên tai."],
  ['hat.party', 'hat', "Mũ tiệc", 25, 1, "Mỗi ngày đều đáng ăn mừng."],
  ['hat.beanie', 'hat', "Mũ len", 30, 1, "Có quả bông trên chóp."],
  ['hat.flower', 'hat', "Vòng hoa", 35, 1, "Hoa cúc trắng và vàng."],
  ['hat.straw', 'hat', "Mũ cói", 40, 2, "Cho những buổi dã ngoại."],
  ['hat.wizard', 'hat', "Mũ phù thủy", 90, 6, "Đầy sao, hơi to so với đầu."],
  ['hat.crown', 'hat', "Vương miện", 120, 8, "Dành cho người chăm chỉ lâu ngày."],
  ['hat.catears', 'hat', "Bờm tai mèo", 30, 1, "Thêm một đôi tai nữa."],
  ['hat.cap', 'hat', "Mũ lưỡi trai", 30, 1, "Đội ngược cho ngầu."],
  ['hat.beret', 'hat', "Mũ nồi", 35, 1, "Nghệ sĩ Paris."],
  ['hat.santa', 'hat', "Mũ Noel", 40, 1, "Ho ho ho!"],
  ['hat.antlers', 'hat', "Gạc tuần lộc", 40, 1, "Kéo xe trượt tuyết giúp ông già Noel."],
  ['hat.chef', 'hat', "Mũ đầu bếp", 45, 2, "Hôm nay nấu món gì nhỉ?"],
  ['hat.pumpkin', 'hat', "Mũ bí ngô", 45, 2, "Cho mùa lễ hội hóa trang."],
  ['hat.frog', 'hat', "Mũ ếch", 50, 3, "Hai con mắt lồi trên đỉnh."],
  ['hat.headphones', 'hat', "Tai nghe", 55, 3, "Nghe lo-fi khi tập trung."],
  ['hat.cowboy', 'hat', "Mũ cao bồi", 60, 4, "Yee-haw!"],
  ['hat.cloud', 'hat', "Đám mây nhỏ", 65, 4, "Một đám mây đi theo trên đầu."],
  ['hat.halo', 'hat', "Vòng thiên thần", 70, 5, "Ngoan cả tuần rồi đó."],
  ['hat.tiara', 'hat', "Vương miện pha lê", 80, 5, "Lấp lánh như công chúa."],
  ['glasses.round', 'glasses', "Kính tròn", 30, 1, "Trông thật thông thái."],
  ['glasses.sun', 'glasses', "Kính râm", 40, 1, "Ngầu một chút cũng được."],
  ['glasses.heart', 'glasses', "Kính trái tim", 45, 3, "Nhìn đâu cũng thấy dễ thương."],
  ['glasses.monocle', 'glasses', "Kính một mắt", 60, 5, "Quý ông, quý cô lịch lãm."],
  ['glasses.nerd', 'glasses', "Kính gọng vuông", 30, 1, "Mọt sách chính hiệu."],
  ['glasses.goggles', 'glasses', "Kính bơi", 35, 1, "Sẵn sàng lặn xuống hồ."],
  ['glasses.star', 'glasses', "Kính ngôi sao", 40, 2, "Ngôi sao của buổi tiệc."],
  ['glasses.aviator', 'glasses', "Kính phi công", 55, 4, "Bay lên nào!"],
  ['glasses.pixel', 'glasses', "Kính pixel", 65, 5, "Deal with it."],
  ['neck.bowtie', 'neck', "Nơ cổ", 20, 1, "Chỉn chu cho ngày làm việc."],
  ['neck.scarf', 'neck', "Khăn len", 25, 1, "Ấm cổ những ngày se lạnh."],
  ['neck.bandana', 'neck', "Khăn bandana", 25, 1, "Họa tiết chấm bi."],
  ['neck.bell', 'neck', "Vòng chuông", 30, 1, "Leng keng mỗi bước đi."],
  ['neck.lei', 'neck', "Vòng hoa cổ", 35, 3, "Như vừa đi nghỉ biển về."],
  ['neck.collar', 'neck', "Vòng cổ thẻ tên", 20, 1, "Thẻ tên hình trái tim."],
  ['neck.tie', 'neck', "Cà vạt", 30, 1, "Họp hành nghiêm túc."],
  ['neck.ruff', 'neck', "Cổ áo bèo", 40, 2, "Bèo nhún trắng tinh."],
  ['neck.pearls', 'neck', "Chuỗi ngọc trai", 60, 4, "Quý phái nhẹ nhàng."],
  ['neck.medal', 'neck', "Huy chương vàng", 80, 6, "Quán quân chăm chỉ."],
  ['outfit.sweater', 'outfit', "Áo len", 50, 1, "Áo len sọc, mềm và ấm."],
  ['outfit.overalls', 'outfit', "Yếm jean", 55, 2, "Có túi nhỏ đựng bút chì."],
  ['outfit.raincoat', 'outfit', "Áo mưa vàng", 60, 3, "Sẵn sàng cho ngày mưa."],
  ['outfit.cape', 'outfit', "Áo choàng", 90, 6, "Áo choàng siêu anh hùng."],
  ['outfit.apron', 'outfit', "Tạp dề", 40, 1, "Có túi nhỏ hình trái tim."],
  ['outfit.pajamas', 'outfit', "Đồ ngủ sao", 50, 1, "Xanh đêm in sao vàng."],
  ['outfit.hoodie', 'outfit', "Áo hoodie", 55, 1, "Rộng rãi, có dây rút."],
  ['outfit.dress', 'outfit', "Váy hoa", 60, 2, "Hoa nhí trên nền vàng."],
  ['outfit.tutu', 'outfit', "Váy tutu", 65, 3, "Xoay một vòng nào."],
  ['outfit.sailor', 'outfit', "Áo thủy thủ", 70, 4, "Cổ xanh, nơ đỏ."],
  ['outfit.yukata', 'outfit', "Áo yukata", 85, 5, "Đi xem pháo hoa mùa hè."],
  ['outfit.tux', 'outfit', "Áo vest", 90, 6, "Bảnh bao dự tiệc."],
  ['outfit.astronaut', 'outfit', "Đồ phi hành gia", 130, 8, "Mục tiêu: mặt trăng."],
  ['back.lollipop', 'back', "Kẹo mút", 20, 1, "Kẹo cầu vồng xoắn ốc."],
  ['back.balloon', 'back', "Bóng bay", 25, 1, "Bóng bay hình trái tim."],
  ['back.backpack', 'back', "Ba lô nhỏ", 40, 1, "Đựng bút, sổ và đồ ăn vặt."],
  ['back.umbrella', 'back', "Ô che nắng", 45, 2, "Ô giấy kiểu cổ điển."],
  ['back.bat', 'back', "Cánh dơi", 60, 3, "Hơi tinh nghịch một chút."],
  ['back.guitar', 'back', "Đàn ghi-ta", 75, 4, "Hát một bài cho bạn nghe."],
  ['back.fairy', 'back', "Cánh tiên", 80, 4, "Trong suốt, lấp lánh."],
  ['back.wings', 'back', "Cánh thiên thần", 90, 5, "Lông vũ trắng muốt."],]

/** Đồ chỉ có trong máy capsule (và phần thưởng hoàn thành bộ). */
export const CAPSULE_ONLY = new Set<string>([
  'bedroomWall.moon', 'nightstand.moon', 'glasses.star', 'outfit.pajamas', 'hat.cloud', 'back.bat', 'bedroomTheme.galaxy', 'hat.wizard',
  'bathMat.wave', 'bathToy.whale', 'glasses.goggles', 'neck.lei', 'bathToy.boat', 'outfit.sailor', 'sink.shell', 'bathTheme.ocean',
  'hat.flower', 'flowerBed.sunflower', 'gardenSeat.swing', 'outfit.dress', 'plant.tulip', 'back.fairy', 'tree.sakura', 'hat.tiara',
  'hat.party', 'back.balloon', 'back.lollipop', 'gardenDeco.lantern', 'hat.pumpkin', 'outfit.yukata', 'hat.antlers', 'neck.medal',
])
/** Phần thưởng khi hoàn thành một bộ capsule (không bán, không quay ra). */
export const SERIES_REWARD_ITEMS = new Set<string>(['studyTheme.night', 'pond.koi', 'studyTheme.sakura', 'gardenDeco.tent'])

/** Mô tả mới cho vài món mang không khí "năng suất" của bản cũ. */
const BLURB_OVERRIDE: Record<string, string> = {
  'treat.cake': 'Mừng một ngày thật vui.',
  'hat.crown': 'Dành cho người đã ở Cozii lâu ngày.',
  'neck.medal': 'Quán quân của ngày hội.',
  'neck.bowtie': 'Chỉn chu cho một buổi hẹn.',
  'neck.tie': 'Nghiêm túc… được năm phút.',
  'hat.headphones': 'Nghe lo-fi khi thư giãn.',
  'desk.lavender': 'Màu tím nhạt dịu mắt.',
  'lamp.desk': 'Đủ sáng cho buổi đọc truyện muộn.',
  'desk.computer': 'Màn hình nhỏ dán đầy sticker.',
  'wall.clock': 'Tích tắc, chẳng ai vội cả.',
  'plant.bonsai': 'Kiên nhẫn từng chút một.',
  'seat.armchair': 'Hợp để đọc sách buổi tối.',
  'gardenDeco.mailbox': 'Chờ thư từ bạn bè.',
}

/** Món có sẵn khi mở phòng (giá gốc 0) — tặng miễn phí, không ghi vào cửa hàng. */
function rankFor(level: number): number {
  if (level <= 2) return 1
  if (level <= 4) return 2
  if (level === 5) return 3
  if (level === 6) return 4
  return 5
}

function round5(n: number) {
  return Math.max(5, Math.round(n / 5) * 5)
}

export const ITEMS: CatalogItem[] = ROWS.map(([id, slot, name, base, level, blurb]) => {
  const source: Source = SERIES_REWARD_ITEMS.has(id) ? 'reward' : CAPSULE_ONLY.has(id) ? 'capsule' : base === 0 ? 'starter' : 'shop'
  const mult = slot === 'species' ? ECONOMY.speciesPriceMultiplier : ECONOMY.priceMultiplier
  return {
    id, slot, name,
    price: source === 'shop' ? round5(base * mult) : 0,
    rank: rankFor(level),
    blurb: BLURB_OVERRIDE[id] ?? blurb,
    source,
  }
})

const BY_ID = new Map(ITEMS.map(i => [i.id, i]))
export function item(id: string): CatalogItem | undefined {
  return BY_ID.get(id)
}
export function itemsIn(slot: ItemSlot): CatalogItem[] {
  return ITEMS.filter(i => i.slot === slot)
}

export const PET_SLOTS: PetSlot[] = ['species', 'fur', 'hat', 'glasses', 'neck', 'outfit', 'back']
export const WEAR_SLOTS = ['hat', 'glasses', 'neck', 'outfit', 'back'] as const
export function isPetSlot(s: ItemSlot): s is PetSlot {
  return (PET_SLOTS as string[]).includes(s)
}

export const SLOT_LABEL: Record<ItemSlot, string> = {
  wall: 'Đồ treo tường', lamp: 'Đèn', desk: 'Bàn', plant: 'Cây', seat: 'Ghế / thảm', studyTheme: 'Tường & sàn',
  bedroomTheme: 'Tường & sàn', bed: 'Giường', nightstand: 'Đầu giường', bedroomWall: 'Trang trí tường', closet: 'Tủ',
  bedroomRug: 'Thảm', plush: 'Đồ chơi', kitchenTheme: 'Tường & sàn', stove: 'Bếp', fridge: 'Tủ lạnh', dining: 'Bàn ăn',
  kitchenWall: 'Kệ & tường', treat: 'Món ăn trang trí', bathTheme: 'Tường & sàn', tub: 'Bồn tắm', sink: 'Bồn rửa',
  bathShelf: 'Kệ', bathMat: 'Thảm', bathToy: 'Đồ chơi', gardenTheme: 'Bầu trời', tree: 'Cây lớn', flowerBed: 'Luống hoa',
  gardenSeat: 'Chỗ ngồi', pond: 'Hồ nước', gardenDeco: 'Trang trí',
  species: 'Loài', fur: 'Màu lông', hat: 'Mũ', glasses: 'Kính', neck: 'Cổ', outfit: 'Áo', back: 'Phụ kiện',
}

export interface RoomDef {
  id: RoomId
  name: string
  themeSlot: ItemSlot
  slots: ItemSlot[]
  /** Hạng thị trấn mở phòng. */
  rank: number
  defaultTheme: string
  /** Chỗ đứng mặc định của pet (tỉ lệ bề rộng phòng). */
  petHome: number
}

export const ROOMS: RoomDef[] = [
  { id: 'study', name: 'Phòng chính', themeSlot: 'studyTheme', slots: ['wall', 'lamp', 'desk', 'plant', 'seat'], rank: 1, defaultTheme: 'studyTheme.cream', petHome: 0.2 },
  { id: 'bedroom', name: 'Phòng ngủ', themeSlot: 'bedroomTheme', slots: ['bed', 'nightstand', 'bedroomWall', 'closet', 'bedroomRug', 'plush'], rank: 2, defaultTheme: 'bedroomTheme.lilac', petHome: 0.22 },
  { id: 'kitchen', name: 'Bếp nhỏ', themeSlot: 'kitchenTheme', slots: ['stove', 'fridge', 'dining', 'kitchenWall', 'treat'], rank: 3, defaultTheme: 'kitchenTheme.mint', petHome: 0.42 },
  { id: 'bath', name: 'Phòng tắm', themeSlot: 'bathTheme', slots: ['tub', 'sink', 'bathShelf', 'bathMat', 'bathToy'], rank: 4, defaultTheme: 'bathTheme.aqua', petHome: 0.26 },
  { id: 'garden', name: 'Sân trước', themeSlot: 'gardenTheme', slots: ['tree', 'flowerBed', 'gardenSeat', 'pond', 'gardenDeco'], rank: 5, defaultTheme: 'gardenTheme.day', petHome: 0.34 },
]
export function room(id: RoomId): RoomDef {
  return ROOMS.find(r => r.id === id)!
}
export function roomOfSlot(slot: ItemSlot): RoomDef | undefined {
  return ROOMS.find(r => r.themeSlot === slot || r.slots.includes(slot))
}
export function isThemeSlot(slot: ItemSlot): boolean {
  return ROOMS.some(r => r.themeSlot === slot)
}

/** Vị trí đặt đồ trong phòng (hệ 125×100, tường ở trên y = 62). Mỗi món là ô vuông size×size. */
export interface Spot { x: number; y: number; size: number }
export const SPOTS: Partial<Record<ItemSlot, Spot>> = {
  wall: { x: 10, y: 6, size: 32 }, lamp: { x: 90, y: 30, size: 34 }, desk: { x: 62, y: 34, size: 40 },
  plant: { x: 2, y: 50, size: 28 }, seat: { x: 22, y: 52, size: 46 },
  closet: { x: 2, y: 20, size: 42 }, bedroomWall: { x: 72, y: 4, size: 34 }, bed: { x: 64, y: 38, size: 58 },
  nightstand: { x: 44, y: 42, size: 26 }, bedroomRug: { x: 20, y: 54, size: 48 }, plush: { x: 4, y: 72, size: 24 },
  kitchenWall: { x: 8, y: 6, size: 32 }, fridge: { x: 80, y: 12, size: 56 }, stove: { x: 54, y: 30, size: 40 },
  dining: { x: 4, y: 40, size: 46 }, treat: { x: 16, y: 39, size: 22 },
  bathShelf: { x: 8, y: 6, size: 30 }, sink: { x: 2, y: 26, size: 44 }, tub: { x: 62, y: 30, size: 60 },
  bathMat: { x: 28, y: 56, size: 40 }, bathToy: { x: 100, y: 76, size: 20 },
  tree: { x: 0, y: 2, size: 60 }, gardenSeat: { x: 48, y: 28, size: 38 }, gardenDeco: { x: 88, y: 26, size: 38 },
  flowerBed: { x: 2, y: 66, size: 32 }, pond: { x: 78, y: 56, size: 46 },
}
/** Dịch ngang tối đa (đơn vị phòng) khi chỉnh vị trí một món — đủ nhỏ để đồ không xuyên nhau. */
export const MAX_NUDGE = 6

export function drawOrder(r: RoomDef): ItemSlot[] {
  return [...r.slots].sort((a, b) => {
    const A = SPOTS[a]!, B = SPOTS[b]!
    return A.y + A.size - (B.y + B.size)
  })
}

export function defaultOwned(): string[] {
  return ITEMS.filter(i => i.source === 'starter').map(i => i.id)
}
