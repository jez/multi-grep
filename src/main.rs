extern crate regex;
extern crate failure;

use regex::Regex;

use failure::Error;

use std::cmp::Ordering::{Less, Equal, Greater};
use std::env;
use std::fs::File;
use std::io::BufReader;
use std::io::BufRead;
use std::process;

fn run() -> Result<i32, Error> {
    let args: Vec<String> = env::args().collect();

    if args.len() != 3 {
        eprintln!("usage: {} <locs.txt> <pattern>", args[0]);
        return Ok(1)
    }

    let input_filename = &args[1];
    let pattern = &args[2];

    let re = Regex::new(pattern)?;

    let input_file = File::open(input_filename)?;
    for (i, maybe_input_line) in BufReader::new(input_file).lines().enumerate() {
        let input_line = maybe_input_line?;

        let parts: Vec<_> = input_line.split(":").collect();
        let (filename, lineno) = match parts.len() {
            2 => {
                let filename = &parts[0];
                let lineno_str = &parts[1];
                match lineno_str.parse::<usize>() {
                    Ok(lineno) => (filename, lineno),
                    Err(_) => {
                        eprintln!("error: Invalid line number ({}) on line {}", lineno_str, i + 1);
                        return Ok(1)
                    }
                }
            }
            _ => {
                eprintln!("error: Couldn't parse input line {}", i);
                return Ok(1)
            }
        };

        let file = File::open(filename)?;
        for (j, maybe_line) in BufReader::new(file).lines().enumerate() {
            match j.cmp(&(lineno - 1)) {
                Less => continue,
                Greater => break,
                Equal => (),
            }

            let line = maybe_line?;

            if re.is_match(&line) {
                println!("{}:{}", filename, lineno);
            }
        }
    }

    Ok(0)
}

fn main() {
    process::exit(match run() {
        Ok(exit_code) => exit_code,
        Err(_err) => 1,
    });
}
