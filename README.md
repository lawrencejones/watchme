## Installation

Install via [npm](https://npmjs.org/), node package manager. Example
would be...

    npm install -g watchme

## Motivation

Well, frankly iNotify was annoying me. Along with most of the other
mac alternatives. So I've created a watching app in coffeescript that
will watch a target filehandle for any changes and rerun the given
command when it senses them.

## Example

Great for web development- just write a quick applescript to refresh
Google Chrome (like [here](https://gist.github.com/LawrenceJones/8906909))
and then run this script like...

    watchme app --exec "osascript ~/refresh.applescript"

## Usage

    Watchme - CoffeeScript
    
    Usage:
      watchme -c [ file | dir ]... -e "<cmd>"
      watchme -i <regex> -e "<cmd>"
      watchme -h | --help
      watchme -v | --version
    
    Options:
      -e --exec     Prefix for the command to execute.
      -c --clear    Clear the screen on each trigger.
      -q --quiet    Do not display repeat trigger.
      -h --hidden   Include hidden files.
      -i --regex    Recursively match regex for files.
      -h --help     Show this screen.
      --version     Show version.

