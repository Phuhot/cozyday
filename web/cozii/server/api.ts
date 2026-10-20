// Điểm vào hàm máy chủ /api/cozii (Vercel Serverless Function, Node.js). Được đóng gói thành api/cozii.js
// bởi scripts/build-api.mjs. Nhận POST { op, ...tham số } kèm "Authorization: Bearer <access token Supabase>".
import type { IncomingMessage, ServerResponse } from 'node:http'
import { authenticate, HttpError, type AuthUser } from './auth'
import * as ops from './ops'

type Body = Record<string, unknown> & { op?: string }

export async function dispatch(user: AuthUser, b: Body): Promise<unknown> {
  const s = (k: string) => (typeof b[k] === 'string' ? (b[k] as string) : '')
  switch (b.op) {
    case 'state': return ops.opState(user)
    case 'act': return ops.opAct(user, b as never)
    case 'publish': return ops.opPublish(user)
    case 'findByCode': return ops.opFindByCode(user, s('code'))
    case 'sendRequest': return ops.opSendRequest(user, s('code'))
    case 'respondRequest': return ops.opRespondRequest(user, s('id'), b.accept === true)
    case 'listFriends': return ops.opListFriends(user)
    case 'listRequests': return ops.opListRequests(user)
    case 'removeFriend': return ops.opRemoveFriend(user, s('other'))
    case 'block': return ops.opBlock(user, s('other'))
    case 'unblock': return ops.opUnblock(user, s('other'))
    case 'listBlocked': return ops.opListBlocked(user)
    case 'report': return ops.opReport(user, s('other'), s('reason'), s('details'))
    case 'discover': return ops.opDiscover(user, typeof b.cursor === 'string' ? b.cursor : null)
    case 'visit': return ops.opVisit(user, s('host'))
    case 'compliment': return ops.opCompliment(user, s('host'), s('sticker'))
    case 'helpWater': return ops.opHelpWater(user, s('host'), Number(b.plot), s('requestId'))
    case 'inbox': return ops.opInbox(user)
    case 'leaderboard': return ops.opLeaderboard(user, s('game'), s('scope'), typeof b.week === 'string' ? b.week : null)
    case 'collectors': return ops.opCollectors(user)
    case 'claimBadges': return ops.opClaimBadges(user)
    default: throw new HttpError(400, 'op', 'Thao tác không tồn tại.')
  }
}

async function readBody(req: IncomingMessage & { body?: unknown }): Promise<Body> {
  if (req.body && typeof req.body === 'object') return req.body as Body
  if (typeof req.body === 'string') return JSON.parse(req.body)
  const chunks: Buffer[] = []
  let size = 0
  for await (const ch of req) {
    size += (ch as Buffer).length
    if (size > 512_000) throw new HttpError(413, 'size', 'Dữ liệu quá lớn.')
    chunks.push(ch as Buffer)
  }
  const text = Buffer.concat(chunks).toString('utf8')
  return text ? JSON.parse(text) : {}
}

function send(res: ServerResponse, status: number, data: unknown) {
  res.statusCode = status
  res.setHeader('Content-Type', 'application/json; charset=utf-8')
  res.setHeader('Cache-Control', 'no-store')
  res.end(JSON.stringify(data))
}

export default async function handler(req: IncomingMessage & { body?: unknown }, res: ServerResponse) {
  if (req.method !== 'POST') return send(res, 405, { error: { code: 'method', message: 'Chỉ nhận POST.' } })
  try {
    const user = await authenticate(req.headers.authorization)
    const body = await readBody(req)
    const data = await dispatch(user, body)
    send(res, 200, { data })
  } catch (e) {
    if (e instanceof HttpError) return send(res, e.status, { error: { code: e.code, message: e.message } })
    if (e instanceof SyntaxError) return send(res, 400, { error: { code: 'json', message: 'Dữ liệu gửi lên không hợp lệ.' } })
    const pgCode = (e as { code?: string }).code
    if (pgCode === '23514') return send(res, 400, { error: { code: 'constraint', message: 'Thao tác bị từ chối (số dư không đủ).' } })
    if (pgCode === '40P01' || pgCode === '40001') return send(res, 409, { error: { code: 'retry', message: 'Máy chủ đang bận, thử lại nhé.' } })
    console.error('cozii api error', e)
    send(res, 500, { error: { code: 'server', message: 'Máy chủ gặp lỗi. Thử lại sau nhé.' } })
  }
}
