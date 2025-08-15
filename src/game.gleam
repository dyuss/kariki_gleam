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
