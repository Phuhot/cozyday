// Loài, màu lông và ngoại hình thú cưng — giữ nguyên ID của Cozyday (bản iOS).

export const SPECIES = [
  'cat', 'bunny', 'hamster', 'bear', 'fox', 'puppy', 'duck', 'frog', 'capybara', 'panda', 'penguin',
] as const
export type PetSpecies = (typeof SPECIES)[number]

export const SPECIES_NAME: Record<PetSpecies, string> = {
  cat: 'Mèo', bunny: 'Thỏ', hamster: 'Hamster', bear: 'Gấu nhỏ', fox: 'Cáo', puppy: 'Cún con', duck: 'Vịt con',
  frog: 'Ếch xanh', capybara: 'Capybara', panda: 'Gấu trúc', penguin: 'Chim cánh cụt',
}

export const SPECIES_BLURB: Record<PetSpecies, string> = {
  cat: 'Tai nhọn, đuôi cong, thích nằm thảm.',
  bunny: 'Tai dài, đuôi bông, nhảy lò cò khi vui.',
  hamster: 'Má phúng phính, giấu hạt trong má.',
  bear: 'Tai tròn, mõm sáng màu, rất thích mật ong.',
  fox: 'Đuôi xù chóp trắng, tò mò mọi thứ.',
  puppy: 'Tai cụp, đuôi ngoáy tít khi gặp bạn.',
  duck: 'Mỏ cam, lạch bạch theo bạn khắp nơi.',
  frog: 'Ộp ộp, thích ngồi trên lá súng.',
  capybara: 'Bình thản trước mọi chuyện, mê tắm suối nước nóng.',
  panda: 'Mắt quầng tròn, mê măng tre.',
  penguin: 'Bụng tròn, đi lạch bạch.',
}

export const FURS = ['cream', 'snow', 'ginger', 'smoke', 'cocoa', 'peach', 'midnight', 'lilac', 'honey', 'mint', 'sky'] as const
export type FurColor = (typeof FURS)[number]

export const NATURAL_FUR: Record<PetSpecies, FurColor> = {
  cat: 'cream', hamster: 'cream', bunny: 'snow', panda: 'snow', bear: 'cocoa', capybara: 'cocoa', fox: 'ginger',
  puppy: 'honey', duck: 'honey', frog: 'mint', penguin: 'midnight',
}

export type PetStage = 'little' | 'growing' | 'grown'

export type PetMood = 'idle' | 'happy' | 'focus' | 'rest' | 'low'

/** Toàn bộ ngoại hình — ID món đồ theo từng vị trí trên người. */
export interface PetAppearance {
  species: PetSpecies
  fur: FurColor
  hat?: string | null
  glasses?: string | null
  neck?: string | null
  outfit?: string | null
  back?: string | null
  stage: PetStage
}

export const PET_WEAR_SLOTS = ['hat', 'glasses', 'neck', 'outfit', 'back'] as const
export type PetWearSlot = (typeof PET_WEAR_SLOTS)[number]

/** Tư thế tại một thời điểm (tính theo thời gian ở lớp giao diện). */
export interface PetPose {
  breath: number
  blink: boolean
  tail: number
  ear: number
  hop: number
  tilt: number
  look: number
  walk: number | null
  hearts: number | null
  z: number
  petted: number
  lifted: boolean
}

export function restPose(): PetPose {
  return { breath: 0, blink: false, tail: 0, ear: 0, hop: 0, tilt: 0, look: 0, walk: null, hearts: null, z: 0, petted: 0, lifted: false }
}

export function appearanceKey(a: PetAppearance): string {
  return [a.species, a.fur, a.hat ?? '', a.glasses ?? '', a.neck ?? '', a.outfit ?? '', a.back ?? '', a.stage].join('|')
}
