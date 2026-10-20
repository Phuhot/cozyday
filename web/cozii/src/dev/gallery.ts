import { paintPet, paintItem } from '../art'
import { SPECIES, FURS, NATURAL_FUR, restPose, type PetAppearance } from '../content/pet'

const out = document.getElementById('out')!
const params = new URLSearchParams(location.search)
const mode = params.get('m') ?? 'pets'

function canvas(w: number, h: number) {
  const cv = document.createElement('canvas')
  cv.width = w * 2
  cv.height = h * 2
  cv.style.width = w + 'px'
  cv.style.height = h + 'px'
  out.appendChild(cv)
  const c = cv.getContext('2d')!
  c.scale(2, 2)
  return c
}

if (mode === 'icon') {
  const size = Number(params.get('size') ?? 512)
  const pad = params.get('maskable') ? 0.2 : 0.08
  const cv = document.createElement('canvas')
  cv.width = size
  cv.height = size
  cv.id = 'icon'
  cv.style.border = '0'
  cv.style.borderRadius = '0'
  out.appendChild(cv)
  const c = cv.getContext('2d')!
  const grd = c.createLinearGradient(0, 0, 0, size)
  grd.addColorStop(0, '#ffd9e4')
  grd.addColorStop(1, '#fbe7de')
  c.fillStyle = grd
  c.fillRect(0, 0, size, size)
  c.fillStyle = 'rgba(255,255,255,0.55)'
  c.beginPath(); c.ellipse(size / 2, size * 0.84, size * 0.36, size * 0.07, 0, 0, Math.PI * 2); c.fill()
  const inner = size * (1 - pad * 2)
  paintPet(c, size * pad, size * pad + size * 0.02, inner, { species: 'duck', fur: 'honey', hat: 'hat.cloud', stage: 'little' }, 'happy')
} else if (mode === 'pets') {
  for (const s of SPECIES) {
    const a: PetAppearance = { species: s, fur: NATURAL_FUR[s], stage: 'grown' }
    paintPet(canvas(120, 120), 10, 10, 100, a)
  }
  for (const f of FURS) paintPet(canvas(120, 120), 10, 10, 100, { species: 'cat', fur: f, stage: 'grown' }, 'happy')
  const looks: Partial<PetAppearance>[] = [
    { species: 'capybara', fur: 'cocoa', hat: 'hat.beret', back: 'back.guitar' },
    { species: 'bunny', fur: 'snow', hat: 'hat.halo', back: 'back.wings', outfit: 'outfit.dress' },
    { species: 'penguin', fur: 'midnight', outfit: 'outfit.tux', neck: 'neck.bowtie' },
    { species: 'fox', fur: 'snow', glasses: 'glasses.heart', outfit: 'outfit.raincoat', back: 'back.umbrella' },
    { species: 'duck', fur: 'honey', hat: 'hat.chef', outfit: 'outfit.apron' },
    { species: 'panda', fur: 'snow', glasses: 'glasses.pixel', neck: 'neck.medal' },
    { species: 'frog', fur: 'mint', hat: 'hat.headphones', outfit: 'outfit.hoodie' },
    { species: 'cat', fur: 'midnight', hat: 'hat.wizard', back: 'back.bat' },
  ]
  for (const l of looks) paintPet(canvas(120, 120), 10, 10, 100, { stage: 'grown', ...l } as PetAppearance, 'idle', { ...restPose(), petted: 0 })
} else {
  const ids = (params.get('ids') ?? 'studyTheme.cream,bedroomTheme.lilac,kitchenTheme.mint,bathTheme.aqua,gardenTheme.day').split(',')
  for (const id of ids) {
    const scene = id.includes('Theme')
    const c = canvas(scene ? 250 : 120, scene ? 200 : 120)
    paintItem(c, id, 0, 0, scene ? 250 : 120, scene ? 200 : 120, scene)
  }
}
