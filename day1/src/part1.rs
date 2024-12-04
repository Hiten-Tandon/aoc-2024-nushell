use itertools::Itertools;
use utilities::{AocError, get_input};
pub fn main() -> Result<(), AocError> {
    let (mut l, mut r): (Vec<_>, Vec<_>) = get_input(1)?
        .lines()
        .filter_map(|l| {
            l.split_ascii_whitespace()
                .map(str::parse::<u32>)
                .filter_map(Result::ok)
                .collect_tuple()
        })
        .unzip();
    l.sort();
    r.sort();
    let res: u32 = l.into_iter().zip(r).map(|(a, b)| a.abs_diff(b)).sum();
    println!("{res}");
    Ok(())
}