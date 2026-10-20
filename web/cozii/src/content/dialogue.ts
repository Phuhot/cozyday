// Câu nói của bạn nhỏ: viết sẵn, chọn theo ngữ cảnh, không bao giờ trách móc hay làm người chơi thấy có lỗi.
import type { PetSpecies } from './pet'

export interface TalkContext {
  hour: number
  playerName: string
  hungry: boolean
  dirty: boolean
  bored: boolean
  readyCrops: number
  growing: number
}

const SPECIES_LINES: Record<PetSpecies, string[]> = {
  cat: ['Meo~ gãi cằm cho mình đi.', 'Mình vừa ngủ một giấc trong nắng đó.'],
  bunny: ['Tai mình vểnh lên vì vui nè!', 'Mình mơ thấy cả một vườn cà rốt.'],
  hamster: ['Má mình đang giấu hạt đó, suỵt!', 'Chạy một vòng cho khỏe nào!'],
  bear: ['Ước gì có một thìa mật ong…', 'Ôm một cái thật to nào!'],
  fox: ['Đuôi mình xù chưa nè?', 'Mình vừa tìm được một chiếc lá đỏ xinh lắm.'],
  puppy: ['Gâu! Đi dạo không, đi dạo không?', 'Đuôi mình vẫy không ngừng được nè!'],
  duck: ['Quạc quạc! Hôm nay có mưa không nhỉ?', 'Mình muốn đi bơi một vòng ghê.'],
  frog: ['Ộp ộp! Lá súng hôm nay mát lắm.', 'Mình tập nhảy xa hơn rồi đó!'],
  capybara: ['Thong thả thôi, không vội gì đâu.', 'Ước gì được ngâm suối nước nóng…'],
  panda: ['Măng hôm nay giòn ghê.', 'Mình lăn một vòng cho bạn xem nè!'],
  penguin: ['Lạch bạch… mình đến đây!', 'Mình để dành một viên sỏi đẹp tặng bạn.'],
}

export function talkLines(c: TalkContext, species: PetSpecies): string[] {
  const name = c.playerName || 'bạn'
  const lines: string[] = []
  if (c.hungry) lines.push('Bụng mình kêu ọc ọc rồi nè.', 'Có gì ăn không nhỉ? Một quả táo thôi cũng được.')
  if (c.dirty) lines.push('Góc nhà hơi bụi rồi, mình dọn cùng nhau nhé?')
  if (c.bored) lines.push('Chơi với mình một ván không?', 'Xoa đầu mình một cái đi mà.')
  if (c.readyCrops > 0) lines.push(c.readyCrops === 1 ? 'Ngoài vườn có một cây chín rồi đó!' : `Ngoài vườn có ${c.readyCrops} cây chín rồi đó!`)
  else if (c.growing > 0) lines.push('Cây ngoài vườn đang lớn từng chút.')
  const h = c.hour
  if (h >= 5 && h < 11) lines.push(`Chào buổi sáng, ${name}!`, 'Nắng sớm đẹp ghê!', 'Vươn vai một cái cho khỏe nào!')
  else if (h >= 11 && h < 13) lines.push('Trưa rồi, nhớ ăn gì đó nhé.', 'Nắng trưa ấm quá, mình muốn nằm phơi.')
  else if (h >= 13 && h < 18) lines.push('Buổi chiều lười biếng ghê…', 'Làm một ngụm trà không?', 'Chiều nay mình ở đây với ' + name + ' nha.')
  else if (h >= 18 && h < 23) lines.push('Tối rồi, thị trấn lên đèn đẹp ghê.', 'Hôm nay có điều gì nhỏ mà vui không?')
  else lines.push('Khuya rồi… đi ngủ sớm nhé.', 'Mình buồn ngủ quá… zzz')
  lines.push(...SPECIES_LINES[species])
  lines.push('Rừ rừ…', 'Mình thích được xoa đầu lắm.', `Mình thương ${name} nhiều lắm.`, `Có ${name} ở đây là vui rồi.`)
  return lines
}

export const PETTED_LINES = [
  'Hihi, nhột quá!', 'Xoa nữa đi, xoa nữa đi!', 'Ui, dễ chịu ghê…', 'Thêm chút nữa thôi mà~', 'Mình thích thế này lắm!',
  'Ấm áp quá đi…', 'Chỗ đó đó, đúng chỗ đó!', 'Lim dim luôn rồi nè…', 'Tay bạn ấm quá à.', 'Ư… buồn ngủ mất thôi.',
]

export const FED_LINES = ['Ngon quá trời!', 'Măm măm, cảm ơn nha!', 'No căng bụng rồi nè.', 'Món này mình thích nhất!']
export const CLEAN_LINES = ['Sạch bong rồi! Thơm ghê.', 'Nhà mình sáng hẳn lên.', 'Cảm ơn bạn đã dọn cùng mình.']
export const CUDDLE_DONE = ['Mình vui lắm luôn!', 'Thêm một cái ôm nữa nha.', 'Tim mình bay lên rồi nè.']

export const VISIT_LOCAL_LINES = ['Chào bạn hàng xóm!', 'Nhà mình xinh không?', 'Bạn ghé chơi vui ghê.', 'Ở lại chơi lâu lâu nha.']
