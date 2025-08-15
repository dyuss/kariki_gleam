import game.{type Game, type GameCondition}
import gleam/list
import gleam/string

pub type Filters {
  Filters(
    title: String,
    statuses: List(String),
    available_statuses: List(String),
    conditions: List(GameCondition),
  )
}

pub fn filter_games(games: List(Game), filters: Filters) -> List(Game) {
  games
  |> list.filter(fn(game) {
    let is_title = case string.length(filters.title) {
      0 -> True
      _ ->
        game.title
        |> string.lowercase
        |> string.contains(string.lowercase(filters.title))
    }

    let is_status = case list.length(filters.statuses) {
      0 -> True
      _ -> filters.statuses |> list.contains(game.status)
    }

    let is_condition = case list.length(filters.conditions) {
      0 -> True
      _ -> filters.conditions |> list.contains(game.condition)
    }

    is_title && is_status && is_condition
  })
}
