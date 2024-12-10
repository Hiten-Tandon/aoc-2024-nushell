import gleam/int
import gleam/io
import gleam/iterator
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import glearray.{type Array}
import utility.{get_input}

type Direction {
  North
  South
  East
  West
}

type Cell {
  Empty
  Obstruction
  Player
}

fn rotate(dir: Direction) -> Direction {
  case dir {
    East -> South
    North -> East
    South -> West
    West -> North
  }
}

fn walk_graph(
  grid: Array(Array(Cell)),
  position: #(Int, Int),
  direction: Direction,
  visited: Set(#(Int, Int)),
) -> Set(#(Int, Int)) {
  let #(r, c) = position
  let #(dr, dc) = case direction {
    East -> #(0, 1)
    North -> #(-1, 0)
    South -> #(1, 0)
    West -> #(0, -1)
  }

  let #(nr, nc) = #(r + dr, c + dc)
  let visited = set.insert(visited, #(r, c))
  case grid |> glearray.get(nr) |> result.then(fn(x) { glearray.get(x, nc) }) {
    Ok(e) -> {
      visited
      |> set.union(case e {
        Player | Empty -> walk_graph(grid, #(nr, nc), direction, visited)
        Obstruction -> walk_graph(grid, #(r, c), rotate(direction), visited)
      })
    }
    Error(_) -> visited
  }
}

fn find_marker(grid: Array(Array(Cell))) -> #(Int, Int) {
  let assert Ok(x) =
    grid
    |> glearray.iterate
    |> iterator.index
    |> iterator.find_map(fn(x) {
      let #(row, ri) = x
      use y <- iterator.find_map(row |> glearray.iterate |> iterator.index)
      let #(ele, ci) = y
      case ele == Player {
        True -> Ok(#(ri, ci))
        False -> Error(Nil)
      }
    })
  x
}

fn has_cycle(
  grid: Array(Array(Cell)),
  position: #(Int, Int),
  direction: Direction,
  visited: Set(#(Int, Int, Direction)),
) -> Bool {
  let #(r, c) = position
  let #(dr, dc) = case direction {
    East -> #(0, 1)
    North -> #(-1, 0)
    South -> #(1, 0)
    West -> #(0, -1)
  }

  let #(nr, nc) = #(r + dr, c + dc)
  case set.contains(visited, #(r, c, direction)) {
    True -> True
    False -> {
      let visited = set.insert(visited, #(r, c, direction))
      case
        grid |> glearray.get(nr) |> result.then(fn(x) { glearray.get(x, nc) })
      {
        Ok(e) -> {
          case e {
            Player | Empty -> has_cycle(grid, #(nr, nc), direction, visited)
            Obstruction -> has_cycle(grid, #(r, c), rotate(direction), visited)
          }
        }
        Error(_) -> False
      }
    }
  }
}

pub fn main() {
  use data <- result.try(get_input(6))
  let grid =
    data
    |> string.split("\n")
    |> list.map(string.to_graphemes)
    |> list.map(fn(x) {
      use x <- list.map(x)
      case x {
        "." -> Empty
        "#" -> Obstruction
        "^" -> Player
        _ -> panic
      }
    })
    |> list.map(glearray.from_list)
    |> glearray.from_list

  let start = find_marker(grid)
  let path = walk_graph(grid, start, North, set.new())

  path
  |> set.to_list()
  |> list.filter(fn(x) { x != start })
  |> list.filter_map(fn(x) {
    let #(r, c) = x
    let assert Ok(row) = grid |> glearray.get(r)
    let assert Ok(updated_row) = glearray.copy_set(row, c, Obstruction)
    glearray.copy_set(grid, r, updated_row)
  })
  |> list.count(fn(x) { has_cycle(x, start, North, set.new()) })
  |> int.to_string
  |> io.println
  |> Ok
}