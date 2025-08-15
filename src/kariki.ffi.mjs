export async function fetch_db() {
  const response = await fetch('/db.json')
  return response.json()
}

export function format_date(date) {
  return new Date(date).toLocaleString()
}