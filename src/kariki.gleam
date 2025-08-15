import db.{type Db}
import filters.{type Filters}
import game.{type Game, type GameCondition, NewCondition, UsedCondition}
import gleam/dynamic.{type Dynamic}
import gleam/dynamic/decode
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/list
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/event
import sorting.{type Sorting, SortById}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model {
  Loading
  AppError(String)
  Loaded(AppData)
}

type AppData {
  AppData(db: Db, visible_games: List(Game), sorting: Sorting, filters: Filters)
}

fn init(_) -> #(Model, Effect(Msg)) {
  let model = Loading
  let effect = fetch_db()

  #(model, effect)
}

fn fetch_db() -> Effect(Msg) {
  effect.from(fn(dispatch) {
    do_fetch_db()
    |> promise.map(fn(response) {
      case response {
        Ok(r) -> {
          case decode.run(r, db.get_decoder()) {
            Ok(db) -> AppLoadedDbJson(Ok(db))
            _ -> AppLoadedDbJson(Error("error parsing db"))
          }
        }
        _ -> {
          AppLoadedDbJson(Error("error getting db"))
        }
      }
    })
    |> promise.tap(dispatch)

    Nil
  })
}

type Msg {
  AppLoadedDbJson(Result(Db, String))
  UserChangedSorting(Sorting)
  UserChangedTitleFilter(String)
  UserChangedStatusFilter(String)
  UserChangedConditionFilter(GameCondition)
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    AppLoadedDbJson(db) -> {
      let model = case db {
        Ok(db) -> {
          let next_sorting = SortById
          let next_filters =
            filters.Filters(
              title: "",
              statuses: [],
              available_statuses: db.games
                |> list.map(fn(game) { game.status })
                |> list.unique,
              conditions: [],
            )
          Loaded(AppData(
            db,
            visible_games: prepare_visible_games(
              db.games,
              next_sorting,
              next_filters,
            ),
            sorting: next_sorting,
            filters: next_filters,
          ))
        }
        Error(error) -> AppError(error)
      }
      #(model, effect.none())
    }
    UserChangedSorting(sorting) -> {
      let model = case model {
        Loaded(data) -> {
          Loaded(
            AppData(
              ..data,
              sorting:,
              visible_games: prepare_visible_games(
                data.db.games,
                sorting,
                data.filters,
              ),
            ),
          )
        }
        _ -> model
      }
      #(model, effect.none())
    }
    UserChangedTitleFilter(title) -> {
      let model = case model {
        Loaded(data) -> {
          let next_filters = filters.Filters(..data.filters, title:)
          Loaded(
            AppData(
              ..data,
              filters: next_filters,
              visible_games: prepare_visible_games(
                data.db.games,
                data.sorting,
                next_filters,
              ),
            ),
          )
        }
        _ -> model
      }
      #(model, effect.none())
    }
    UserChangedStatusFilter(status) -> {
      let model = case model {
        Loaded(data) -> {
          let next_statuses = case
            list.contains(data.filters.statuses, status)
          {
            True ->
              data.filters.statuses
              |> list.filter(fn(s) { s != status })
            False -> data.filters.statuses |> list.append([status])
          }
          let next_filters =
            filters.Filters(..data.filters, statuses: next_statuses)
          Loaded(
            AppData(
              ..data,
              filters: next_filters,
              visible_games: prepare_visible_games(
                data.db.games,
                data.sorting,
                next_filters,
              ),
            ),
          )
        }
        _ -> model
      }
      #(model, effect.none())
    }
    UserChangedConditionFilter(condition) -> {
      let model = case model {
        Loaded(data) -> {
          let next_conditions = case
            list.contains(data.filters.conditions, condition)
          {
            True ->
              data.filters.conditions
              |> list.filter(fn(c) { c != condition })
            False -> data.filters.conditions |> list.append([condition])
          }
          let next_filters =
            filters.Filters(..data.filters, conditions: next_conditions)
          Loaded(
            AppData(
              ..data,
              filters: next_filters,
              visible_games: prepare_visible_games(
                data.db.games,
                data.sorting,
                next_filters,
              ),
            ),
          )
        }
        _ -> model
      }
      #(model, effect.none())
    }
  }
}

fn prepare_visible_games(
  games: List(Game),
  sorting: Sorting,
  filters: Filters,
) -> List(Game) {
  games |> filters.filter_games(filters) |> sorting.sort_games(sorting)
}

fn view(model: Model) -> Element(Msg) {
  case model {
    Loading -> html.div([], [html.text("loading...")])
    AppError(error) -> html.div([], [html.text(error)])
    Loaded(data) -> {
      html.div([attribute.class("main-page")], [
        view_filters(data),
        view_list(data),
      ])
    }
  }
}

fn view_filters(data: AppData) -> Element(Msg) {
  html.div([attribute.class("filters")], [
    view_sorting(data),
    view_title_filter(data),
    view_status_filter(data),
    view_condition_filter(data),
  ])
}

fn view_sorting(data: AppData) -> Element(Msg) {
  html.div([attribute.class("title-filter headings")], [
    html.h6([], [html.text("Сортировка")]),
    html.select(
      [
        attribute.value(sorting.to_string(data.sorting)),
        event.on_change(fn(str) {
          UserChangedSorting(sorting.from_sorting(str))
        }),
      ],
      [
        html.option([attribute.value("id")], "По обновлению"),
        html.option([attribute.value("price")], "По цене"),
        html.option([attribute.value("title")], "По названию"),
      ],
    ),
  ])
}

fn view_title_filter(data: AppData) -> Element(Msg) {
  html.div([attribute.class("title-filter headings")], [
    html.h6([], [html.text("Название")]),
    html.input([
      attribute.style("margin-bottom", "0"),
      attribute.value(data.filters.title),
      event.on_input(UserChangedTitleFilter),
    ]),
  ])
}

fn view_status_filter(data: AppData) -> Element(Msg) {
  html.div([attribute.class("status-filter headings")], [
    html.h6([], [html.text("Статус")]),
    ..{
      data.filters.available_statuses
      |> list.map(fn(status) {
        view_status_checkbox(status, data.filters.statuses)
      })
    }
  ])
}

fn view_status_checkbox(status: String, statuses: List(String)) -> Element(Msg) {
  html.label([attribute.for(status)], [
    html.input([
      attribute.type_("checkbox"),
      attribute.id(status),
      attribute.checked(statuses |> list.contains(status)),
      event.on_change(fn(_) { UserChangedStatusFilter(status) }),
    ]),
    html.span([attribute.class("checkable")], [html.text(status)]),
  ])
}

fn view_condition_filter(data: AppData) -> Element(Msg) {
  html.div([attribute.class("condition-filter headings")], [
    html.h6([], [html.text("Состояние")]),
    ..{
      [NewCondition, UsedCondition]
      |> list.map(fn(condition) {
        view_condition_checkbox(condition, data.filters.conditions)
      })
    }
  ])
}

fn view_condition_checkbox(
  condition: GameCondition,
  conditions: List(GameCondition),
) -> Element(Msg) {
  html.label([attribute.for(game.condition_to_string(condition))], [
    html.input([
      attribute.type_("checkbox"),
      attribute.id(game.condition_to_string(condition)),
      attribute.checked(conditions |> list.contains(condition)),
      event.on_change(fn(_) { UserChangedConditionFilter(condition) }),
    ]),
    html.span([attribute.class("checkable")], [
      html.text(game.condition_to_string(condition)),
    ]),
  ])
}

fn view_list(data: AppData) -> Element(Msg) {
  html.div([attribute.class("games-list")], [
    html.div([attribute.class("games-list__header")], [
      view_games_count(data),
      view_db_date(data.db),
    ]),
    view_games_list(data),
  ])
}

fn view_games_count(data: AppData) -> Element(Msg) {
  let count = fn(l: List(a)) { l |> list.length |> int.to_string }
  html.div([attribute.class("games-list__count")], [
    html.text(
      "Найдено: " <> count(data.visible_games) <> "/" <> count(data.db.games),
    ),
  ])
}

fn view_db_date(db: Db) -> Element(Msg) {
  html.div([attribute.class("games-list__date")], [
    html.text("Обновление: " <> format_date(db.date)),
  ])
}

fn view_games_list(data: AppData) -> Element(Msg) {
  html.table([attribute.role("grid")], [
    keyed.tbody([], {
      list.map(data.visible_games, fn(game) {
        #(int.to_string(game.id), view_games_list_item(game))
      })
    }),
  ])
}

fn view_games_list_item(game: Game) -> Element(Msg) {
  html.tr([], [
    html.td([attribute.class("game_title")], [
      html.a(
        [
          attribute.href(game.link),
          attribute.target("_blank"),
          attribute.rel("noreferrer"),
        ],
        [html.text(game.title)],
      ),
    ]),
    html.td([attribute.class("game_condition")], [
      html.text(game.condition_to_string(game.condition)),
    ]),
    html.td([attribute.class("game_status")], [
      html.text(game.status),
    ]),
    html.td([attribute.class("game_price")], [
      html.text(int.to_string(game.price)),
    ]),
  ])
}

@external(javascript, "./kariki.ffi.mjs", "format_date")
fn format_date(date: String) -> String

@external(javascript, "./kariki.ffi.mjs", "fetch_db")
fn do_fetch_db() -> Promise(Result(Dynamic, Nil))
