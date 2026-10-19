// Bộ sinh số ngẫu nhiên có seed, chỉ dùng phép tính số nguyên chính xác (< 2^53) để máy chủ (Postgres bigint)
// tái tạo đúng từng con số: Park–Miller "minimal standard" (x = x·48271 mod 2^31−1).

export const RNG_MOD = 2147483647

export class Lcg {
  state: number
  constructor(seed: number) {
    let s = Math.floor(Math.abs(seed)) % RNG_MOD
    if (s <= 0) s = 1
    this.state = s
  }
  next(): number {
    this.state = (this.state * 48271) % RNG_MOD
    return this.state
  }
  /** Số nguyên trong [lo, hi] (hai đầu đều lấy). */
  int(lo: number, hi: number): number {
    if (hi <= lo) {
      this.next()
      return lo
    }
    return lo + (this.next() % (hi - lo + 1))
  }
  /** Xác suất theo phần nghìn: true với xác suất p/1000. */
  chance(permille: number): boolean {
    return this.next() % 1000 < permille
  }
  /** Số thực [0,1) — chỉ dùng cho phần không cần tái tạo trên máy chủ (hiệu ứng, xếp thẻ). */
  float(): number {
    return (this.next() - 1) / (RNG_MOD - 1)
  }
}

/** Sóng tam giác số nguyên: trả về −1024…1024 cho pha k trên chu kỳ p (p > 0). */
export function tri(k: number, p: number): number {
  const m = ((k % p) + p) % p
  const u = Math.trunc((m * 4096) / p)
  return u < 1024 ? u : u < 3072 ? 2048 - u : u - 4096
}

export function isqrt(n: number): number {
  return n <= 0 ? 0 : Math.floor(Math.sqrt(n))
}

/** Chia lấy phần nguyên làm tròn về 0 (giống phép chia số nguyên của Postgres). */
export function idiv(a: number, b: number): number {
  return Math.trunc(a / b)
}
