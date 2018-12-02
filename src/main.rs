extern crate regex;

use regex::Regex;

use std::cmp::Ordering::{Less, Equal, Greater};
use std::env;
use std::fs::File;
use std::io::BufReader;
use std::io::BufRead;
use std::process;

fn usage(arg0: &str) -> Result<(), i32> {
    eprintln!("usage: {} <locs.txt> <pattern>", arg0);
    Err(1)
}

fn run() -> Result<(), i32> {
    let args: Vec<String> = env::args().collect();

    if args.len() != 3 {
        return usage(&args[0])
    }

    let input_filename = &args[1];
    let pattern = &args[2];

    let re = match Regex::new(pattern) {
        Ok(re) => re,
        Err(error) => {
            eprintln!("error: Invalid regex ({})", error);
            return Err(1)
        },
    };

    let input_file = match File::open(input_filename) {
        Ok(file) => file,
        Err(err) => {
            eprintln!("error: Couldn't open input file. Original error:");
            eprintln!("{}", err);
            return Err(1)
        }
    };
    for (i, maybe_input_line) in BufReader::new(input_file).lines().enumerate() {
        let input_line = match maybe_input_line {
            Ok(input_line) => input_line,
            Err(err) => {
                eprintln!("error: Couldn't read input line. Original error:");
                eprintln!("{}", err);
                return Err(1)
            }
        };

        let parts: Vec<_> = input_line.split(":").collect();
        let (filename, lineno) = match parts.len() {
            2 => {
                let filename = &parts[0];
                let lineno_str = &parts[1];
                match lineno_str.parse::<usize>() {
                    Ok(lineno) => (filename, lineno),
                    Err(_) => {
                        eprintln!("error: Invalid line number ({}) on line {}", lineno_str, i + 1);
                        return Err(1)
                    }
                }
            }
            _ => {
                eprintln!("error: Couldn't parse input line {}", i);
                return Err(1)
            }
        };

        let file = match File::open(filename) {
            Ok(file) => file,
            Err(err) => {
                eprintln!("error: Couldn't open {}. Original error:", filename);
                eprintln!("{}", err);
                return Err(1)
            }
        };
        for (j, maybe_line) in BufReader::new(file).lines().enumerate() {
            match j.cmp(&(lineno - 1)) {
                Less => continue,
                Greater => break,
                Equal => (),
            }

            let line = match maybe_line {
                Ok(line) => line,
                Err(err) => {
                    eprintln!("error: Couldn't read line {} in {}. Original error:", j, filename);
                    eprintln!("{}", err);
                    return Err(1)
                }
            };

            if re.is_match(&line) {
                println!("{}:{}", filename, lineno);
            }
        }
    }

    Ok(())
}

fn main() {
    process::exit(match run() {
        Ok(()) => 0,
        Err(err) => err
    });
}
