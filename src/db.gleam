import game.{type Game}
import gleam/dynamic/decode

pub type Db {
  Db(games: List(Game), date: String)
}

pub fn get_decoder() {
  let game_decoder = game.get_decoder()
  use date <- decode.field("date", decode.string)
  use games <- decode.field("games", decode.list(game_decoder))
  decode.success(Db(games, date))
}
