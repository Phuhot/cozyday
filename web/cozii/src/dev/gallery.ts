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

if (mode === 'pets') {
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
