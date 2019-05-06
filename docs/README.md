---
title: README(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

README - Documentation for Geodesic

## SYNOPSIS
 
This directory contains a number of markdown-formatted "man" pages. These will be available inside of the container.

## USAGE

### Build

To rebuild the man pages, run `docs update`

### List

To list all available man pages, run `help`. Then for more information on any topic, run `help` and pass the command as an argument. 

### Search 

To search for help, run `help "topic"` where `"topic"` is what you want more information on.

## CONTRIBUTING

All documentation for `geodesic` belongs in the `docs/` folder. Use markdown appropriate formatting and styles. 

## LAYOUT

In order to be consistent with UNIX Man pages, all section titles should be *UPPERCASE* and begin with a single `##`. 
Subsections should be properly capitalized and use `###`. Avoid going more than (2) sections deep.

Use standard section names. 

### Here are some examples.

- `## NAME` The name of the command or function, followed by a one-line description of what it does.
- `## SYNOPSIS` In the case of a command, a formal description of how to run it and what command line options it takes. For program functions, a list of the parameters the function takes and which header file contains its declaration.
- `## DESCRIPTION` A textual description of the functioning of the command or function.
- `## EXAMPLES` Some examples of common usage.
- `## SEE ALSO` A list of related commands or functions.
- `## OPTIONS` A list of supported options for the command
- `## SYNTAX` An explation of the command's syntax
- `## ENVIRONMENT` A list of supported environment variables
- `## RETURN VALUES` A breakdown of the expected return values or exit codes
- `## STANDARDS` Some of the "best practices"
- `## SECURITY CONSIDERATIONS` Recommended settings for safer operation
- `## BUGS` Some known issues
- `## HISTORY` Background on command to give readers more context


# SEE ALSO
- https://pandoc.org/MANUAL.html
- https://en.wikipedia.org/wiki/Man_page
- https://en.wikipedia.org/wiki/RTFM
