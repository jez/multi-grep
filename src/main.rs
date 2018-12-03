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
        Err(_) => panic!("error: Invalid line number ({}) on line {}", lineno_str, i + 1),
    }
}

fn run() -> Result<(), Error> {
    let args: Vec<String> = env::args().collect();
    let (input_filename, pattern) = match &args[..] {
        [_arg0, input_filename, pattern] => (input_filename, pattern),
        _ => panic!("usage: {} <locs.txt> <pattern>", args[0]),
    };

    let input_file = File::open(input_filename)?;
    let re = Regex::new(pattern)?;

    let mut prev_filename = None;
    let mut prev_lineno = 1;
    let mut open_file_iter = None;

    for (i, maybe_input_line) in BufReader::new(input_file).lines().enumerate() {
        let input_line = maybe_input_line?;

        let parts: Vec<_> = input_line.split(":").collect();
        let (filename, lineno) = match &parts[..] {
            [filename, lineno_str] => (filename, parse_lineno(lineno_str, i)?),
            _ => panic!("error: Couldn't parse input line {}", i),
        };

        let mut file_iter = match open_file_iter {
            None => BufReader::new(File::open(filename)?).lines(),
            Some(iter) => {
                if prev_filename != Some(filename.to_string()) {
                    prev_lineno = 1;
                    BufReader::new(File::open(filename)?).lines()
                } else {
                    iter
                }
            }
        };

        for line in &mut file_iter {
            prev_lineno += 1;
            match (prev_lineno - 1).cmp(&lineno) {
                Less => continue,
                Greater => panic!("Read too many lines from {}", filename),
                Equal => {
                    if re.is_match(&line?) {
                        println!("{}:{}", filename, lineno);
                    }
                    break
                }
            }
        }

        prev_filename = Some(filename.to_string());
        open_file_iter = Some(file_iter);
    }

    Ok(())
}

fn main() {
    process::exit(match run() {
        Ok(()) => 0,
        Err(_err) => 1,
    });
}
