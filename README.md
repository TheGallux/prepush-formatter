# prepush-formatter

## Description 
**Prepush formatter** is a useful tool used, developed by me, which is used to format a C project before committing.  

## How to use ?
As you pull this project, the file is designed to work in this directory:  
```
.  
├── .clang-format  
├── prepush.sh (this file)  
├── Makefile  
├── src  
│   ├── *  
│   ├── *.c  
│   ├── *.h  
│   └── *example-dir* (optional)  
│       ├── *.c  
│       └── *.h  
└── *  
```
You simply need to execute this command: `./prepush.sh`.

## How does it work ?
First, the C-coding style needs to be in Allman style.  
`prepush.sh` will firstly execute `make clean` to get rid of all trashfiles and temporary files.  
Then it will enter src to :  
    - `clang-format` all files in this dir (and recursively), as well as print the file names.  
    - count the number of lines in all functions, warning you if it gets above a threshold value (which you can modify).  
    - Lastly, it will print the number of exported functions, with a warning if it exceeds 10 functions.  
Finally, it will print the numbers of lines written in all files which have as parent "src", and the number of lines written in a subdirectories of the working dir.  
