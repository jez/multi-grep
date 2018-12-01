extern crate regex;

use regex::Regex;

use std::env;
use std::io;
use std::fs::File;
use std::io::BufReader;
use std::io::BufRead;


fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();

    let pattern = match args.as_slice() {
        [] => {
            println!("usage: multi-grep <pattern>");
            // TODO(jez) These should be an error exit
            return Ok(())
        }
        [_arg0, arg1] => arg1,
        _ => {
            println!("usage: multi-grep <pattern>");
            return Ok(())
        }
    };

    let re = match Regex::new(pattern) {
        Ok(re) => re,
        Err(error) => panic!("Invalid regex: {}", error),
    };

    let mut prev_filename: Option<String> = None;
    let mut next_lineno = 1;

    let mut open_file: Option<BufReader<File>> = None;

    let mut i = 0;
    loop {
        i += 1;
        let mut curr_stdin_line = String::new();
        if io::stdin().read_line(&mut curr_stdin_line)? == 0 {
            // TODO(jez) Block until EOF
            break
        }
        let mut parts = curr_stdin_line.split(":");
        let curr_filename = match parts.next() {
            Some(filename) => filename,
            None => {
                println!("error: Line {} missing filename part", i);
                return Ok(())
            }
        };
        let curr_lineno = match parts.next() {
            Some(lineno) => {
                lineno.trim().parse::<u32>().unwrap()
            },
            None => {
                println!("error: Line {} missing line number part", i);
                return Ok(())
            }
        };

        let mut curr_file = match open_file {
            None => {
                BufReader::new(File::open(curr_filename)?)
            }
            Some(f) => {
                if prev_filename != Some(curr_filename.to_string()) {
                    next_lineno = 1;
                    BufReader::new(File::open(curr_filename)?)
                } else {
                    f
                }
            }
        };

        loop {
            let check_this_line = next_lineno == curr_lineno;

            let mut curr_file_line = String::new();
            if curr_file.read_line(&mut curr_file_line)? == 0 {
                break
            }
            next_lineno += 1;

            if check_this_line {
                if re.is_match(&curr_file_line) {
                    println!("{}:{}", curr_filename, curr_lineno);
                }
                break
            }
        }

        prev_filename = Some(curr_filename.to_string());
        open_file = Some(curr_file);
    }

    Ok(())
}
