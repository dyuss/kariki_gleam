import gleam/dynamic/decode

pub type Game {
  Game(
    title: String,
    id: Int,
    link: String,
    price: Int,
    status: String,
    condition: GameCondition,
  )
}

pub type GameCondition {
  NewCondition
  UsedCondition
}

pub fn condition_to_string(condition: GameCondition) -> String {
  case condition {
    NewCondition -> "Новый"
    UsedCondition -> "Б/У"
  }
}

pub fn get_decoder() {
  use title <- decode.field("title", decode.string)
  use id <- decode.field("id", decode.int)
  use link <- decode.field("link", decode.string)
  use status <- decode.field("status", decode.string)
  use price <- decode.field("price", decode.int)
  use game_condition <- decode.field("condition", decode.string)
  let condition = case game_condition {
    "new" -> NewCondition
    _ -> UsedCondition
  }
  decode.success(Game(title:, id:, link:, price:, condition:, status:))
}
