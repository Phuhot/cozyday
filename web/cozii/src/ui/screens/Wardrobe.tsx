import { useMemo, useState } from 'react'
import { useGame } from '../../app/game'
import { back } from '../../app/router'
import { itemsIn, PET_SLOTS, SLOT_LABEL, type CatalogItem, type PetSlot } from '../../content/catalog'
import { ECONOMY } from '../../content/economy'
import { affectionLevel, petStage, rankOf } from '../../core/state'
import type { PetAppearance, PetSpecies, FurColor } from '../../content/pet'
import { PetCanvas } from '../PetCanvas'
import { Coins, ItemThumb, ScreenHead, Sheet } from '../kit'
import { sfx } from '../../app/sound'
import { sourceText } from './Decorate'

/** Tủ đồ: mặc thử miễn phí, mua món chưa có, lưu bộ phối yêu thích. Đổi ngoại hình không ảnh hưởng nhu cầu hay phần thưởng. */
export function Wardrobe({ shopOnly }: { shopOnly?: boolean }) {
  const { state, act, toast } = useGame()
  const rank = rankOf(state)
  const [slot, setSlot] = useState<PetSlot>('hat')
  const [trying, setTrying] = useState<Partial<Record<PetSlot, string | null>>>({})
  const [presets, setPresets] = useState(false)

  const base: PetAppearance = { species: state.pet.species, fur: state.pet.fur, stage: petStage(state.pet.affection), ...state.pet.wear }
  const look: PetAppearance = { ...base }
  for (const [k, v] of Object.entries(trying)) {
    if (k === 'species') look.species = (v ?? 'species.cat').split('.')[1] as PetSpecies
    else if (k === 'fur') look.fur = (v ?? 'fur.cream').split('.')[1] as FurColor
    else (look as unknown as Record<string, string | null>)[k] = v ?? null
  }
  const currentId = (s: PetSlot) => (s === 'species' ? 'species.' + state.pet.species : s === 'fur' ? 'fur.' + state.pet.fur : state.pet.wear[s] ?? null)
  const shownId = (s: PetSlot) => (s in trying ? trying[s] ?? null : currentId(s))

  const options = useMemo(() => itemsIn(slot).filter(i => i.rank <= rank + 1 || state.owned.includes(i.id) || i.source !== 'shop'), [slot, rank, state.owned])
  const owned = (id: string) => state.owned.includes(id)
  const tryingNotOwned = Object.entries(trying).filter(([, v]) => v && !owned(v)) as [PetSlot, string][]

  const pick = async (it: CatalogItem) => {
    sfx('tap')
    if (owned(it.id)) {
      const { [slot]: _, ...rest } = trying
      setTrying(rest)
      if (currentId(slot) !== it.id) await act({ type: 'equip', slot, item: it.id })
    } else setTrying({ ...trying, [slot]: it.id })
  }

  const remove = async () => {
    const { [slot]: _, ...rest } = trying
    setTrying(rest)
    if (slot !== 'species' && slot !== 'fur' && state.pet.wear[slot]) await act({ type: 'equip', slot, item: null })
  }

  const buy = async (id: string) => {
    const it = itemsIn(id.split('.')[0] as PetSlot).find(x => x.id === id)!
    const r = await act({ type: 'buyItem', item: id })
    if (!r) return
    sfx('coin')
    toast(`Đã mua ${it.name}!`, 'good')
    await act({ type: 'equip', slot: it.slot as PetSlot, item: id }, { quiet: true })
    const { [it.slot as PetSlot]: _, ...rest } = trying
    setTrying(rest)
  }

  return (
    <div className="wide-2">
      <div className="stack">
        <ScreenHead title={shopOnly ? 'Tiệm May Mây' : 'Tủ đồ'} onBack={() => back(shopOnly ? 'town' : 'home')} right={<button className="btn small" onClick={() => setPresets(true)}>Bộ phối</button>} />
        <div className="card" style={{ display: 'grid', placeItems: 'center', background: 'linear-gradient(#f3e9f7, #fffdf8)' }}>
          <PetCanvas appearance={look} size={220} mood="happy" interactive label={`${state.pet.name} đang thử đồ`} />
          <div className="small muted">Thân thiết bậc {affectionLevel(state.pet.affection)} · {look.stage === 'little' ? 'Nhóc con' : look.stage === 'growing' ? 'Đang lớn' : 'Trưởng thành'}</div>
        </div>
        {tryingNotOwned.length > 0 && (
          <div className="card stack" style={{ gap: 6, borderColor: 'var(--lavender)' }}>
            <div className="bold small">Đang mặc thử (chưa mua)</div>
            {tryingNotOwned.map(([s, id]) => {
              const it = itemsIn(s).find(x => x.id === id)!
              return (
                <div key={id} className="row">
                  <ItemThumb id={id} size={40} />
                  <div style={{ flex: 1 }} className="small"><b>{it.name}</b><div className="muted tiny">{sourceText(it)}</div></div>
                  {it.source === 'shop' && it.rank <= rank && <button className="btn small primary" disabled={state.wallet.coins < it.price} onClick={() => void buy(id)}>Mua <Coins n={it.price} /></button>}
                  {it.source === 'shop' && it.rank > rank && <span className="badge gray">Hạng {it.rank}</span>}
                </div>
              )
            })}
            <button className="btn small ghost" onClick={() => setTrying({})}>Bỏ đồ thử</button>
          </div>
        )}
      </div>
      <div className="stack">
        <div className="pill-tabs">
          {PET_SLOTS.map(s => <button key={s} className="pill" aria-pressed={slot === s} onClick={() => setSlot(s)}>{SLOT_LABEL[s]}</button>)}
        </div>
        {slot !== 'species' && slot !== 'fur' && <button className="btn small" style={{ alignSelf: 'flex-start' }} onClick={() => void remove()}>Tháo {SLOT_LABEL[slot].toLowerCase()}</button>}
        {slot === 'species' && <p className="muted tiny">Loài chỉ là ngoại hình: đổi loài không ảnh hưởng nhu cầu, thân thiết hay điểm số trong game.</p>}
        <div className="grid">
          {options.map(it => {
            const has = owned(it.id)
            const on = shownId(slot) === it.id
            return (
              <button key={it.id} className={'tile' + (!has && it.rank > rank ? ' locked' : '')} aria-pressed={on} onClick={() => void pick(it)}>
                <ItemThumb id={it.id} size={64} label={it.name} />
                <span className="name">{it.name}</span>
                {has ? <span className="tiny muted">{currentId(slot) === it.id ? 'Đang mặc' : 'Đã có'}</span>
                  : it.source === 'shop' ? <Coins n={it.price} /> : <span className="tiny muted">{it.source === 'capsule' ? 'Capsule' : 'Quà bộ'}</span>}
                {!has && it.rank > rank && it.source === 'shop' && <span className="tag badge gray">Hạng {it.rank}</span>}
              </button>
            )
          })}
        </div>
      </div>
      {presets && <OutfitSheet onClose={() => setPresets(false)} />}
    </div>
  )
}

function OutfitSheet({ onClose }: { onClose: () => void }) {
  const { state, act, toast } = useGame()
  return (
    <Sheet title="Bộ phối yêu thích" onClose={onClose}>
      <div className="grid" style={{ gridTemplateColumns: 'repeat(2, 1fr)' }}>
        {Array.from({ length: ECONOMY.presets.outfits }).map((_, i) => {
          const p = state.presets.outfits[i]
          return (
            <div key={i} className="card stack" style={{ alignItems: 'center', gap: 6 }}>
              {p ? <PetCanvas appearance={{ species: p.species, fur: p.fur, stage: petStage(state.pet.affection), ...p.wear }} size={96} animate={false} /> : <div style={{ height: 96, display: 'grid', placeItems: 'center' }} className="muted small">Trống</div>}
              <div className="bold small">{p?.name ?? `Ô ${i + 1}`}</div>
              <div className="row">
                {p && <button className="btn small" onClick={async () => { if (await act({ type: 'applyOutfit', index: i })) { toast('Đã thay đồ!', 'good'); onClose() } }}>Mặc</button>}
                <button className="btn small primary" onClick={async () => { if (await act({ type: 'saveOutfit', index: i, name: `Bộ ${i + 1}` })) toast('Đã lưu bộ đang mặc.', 'good') }}>Lưu</button>
              </div>
            </div>
          )
        })}
      </div>
    </Sheet>
  )
}

export const _unusedSlots: PetSlot[] = PET_SLOTS
