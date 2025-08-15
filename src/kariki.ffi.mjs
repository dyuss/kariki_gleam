import { Ok, Error } from './gleam.mjs'

export async function fetch_db() {
  try {
    const response = await fetch('./db.json')
    const json = await response.json()
    return new Ok(json)
  } catch (e) {
    return new Error(undefined)
  }
}

export function format_date(date) {
  return new Date(date).toLocaleString()
}