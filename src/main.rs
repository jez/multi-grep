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

fn parse_lineno(lineno_str: &str, i: usize) -> Result<usize, Error> {
    match lineno_str.parse::<usize>() {
        Ok(lineno) => Ok(lineno),
        Err(_) => {
            panic!("error: Invalid line number ({}) on line {}", lineno_str, i + 1);
        }
    }
}

fn run() -> Result<(), Error> {
    let args: Vec<String> = env::args().collect();
    let (input_filename, pattern) = match &args[..] {
        [_arg0, input_filename, pattern] => (input_filename, pattern),
        _ => {
            panic!("usage: {} <locs.txt> <pattern>", args[0]);
        }
    };

    let re = Regex::new(pattern)?;

    let input_file = File::open(input_filename)?;
    for (i, maybe_input_line) in BufReader::new(input_file).lines().enumerate() {
        let input_line = maybe_input_line?;

        let parts: Vec<_> = input_line.split(":").collect();
        let (filename, lineno) = match &parts[..] {
            [filename, lineno_str] => (filename, parse_lineno(lineno_str, i)?),
            _ => {
                panic!("error: Couldn't parse input line {}", i);
            }
        };

        let file = File::open(filename)?;
        for (j, line) in BufReader::new(file).lines().enumerate() {
            match j.cmp(&(lineno - 1)) {
                Less => continue,
                Greater => break,
                Equal => {
                    if re.is_match(&line?) {
                        println!("{}:{}", filename, lineno);
                    }
                }
            }
        }
    }

    Ok(())
}

fn main() {
    process::exit(match run() {
        Ok(()) => 0,
        Err(_err) => 1,
    });
}
