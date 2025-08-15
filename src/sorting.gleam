import game.{type Game}
import gleam/int
import gleam/list
import gleam/order
import gleam/string

pub type Sorting {
  SortById
  SortByPrice
  SortByTitle
}

pub fn sort_games(games: List(Game), sorting: Sorting) -> List(Game) {
  games
  |> list.sort(fn(a, b) {
    case sorting {
      SortById -> order.reverse(int.compare)(a.id, b.id)
      SortByTitle -> string.compare(a.title, b.title)
      SortByPrice -> int.compare(a.price, b.price)
    }
  })
}

pub fn to_string(sorting: Sorting) -> String {
  case sorting {
    SortById -> "id"
    SortByTitle -> "title"
    SortByPrice -> "price"
  }
}

pub fn from_sorting(str: String) -> Sorting {
  case str {
    "title" -> SortByTitle
    "price" -> SortByPrice
    _ -> SortById
  }
}
