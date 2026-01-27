#!/usr/bin/env bash

# COLORS
BRed='\e[1;31m'
Red='\e[0;31m'
BGre='\e[1;32m'
Gre='\e[0;32m'
BWht='\e[1;37m'
NoC='\e[0m'

THRESHOLD=${1:-30}

if [ ! -d "src" ] && [ $# -ne 2 ]; then
    echo -e "${BRed}Erreur : Le dossier 'src' est introuvable dans le répertoire actuel.$(pwd)${NoC}"
    exit 1
fi

# REGEX & CONSTANTS
regex='^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_\t\* ]+[[:space:]]+\**([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\((([^\(\),]+|\([^\(\)]*\))(\s*,\s*([^\(\),]+|\([^\(\)]*\))*)*)\)'
opening_brace="^[[:space:]]*\{"
closing_brace="^[[:space:]]*\}"
empty_line="^[[:space:]]*($|//)"
big_comment_open="^[[:space:]]*/\*"
big_comment_close="^[[:space:]]*\*/"
proto_start_regex='^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_[:space:]\*]+\([a-zA-Z_][a-zA-Z0-9_]*'

count_lines() {
    braces=0
    skip=0
    proto=""
    exported_funcs=0
    line_count=0
    func_name=""

    while IFS= read -r line; do
        if [ $braces -eq 0 ]; then
            line_count=0
        fi

        if [ $skip -eq 0 ] && [[ $line =~ $big_comment_open ]]; then
            if ! [[ $line =~ \*/$ ]]; then
                skip=1
                continue
            fi
        elif [ $skip -eq 1 ] && [[ $line =~ $big_comment_close ]]; then
            skip=0
            continue
        fi
        [[ $skip -eq 1 ]] && continue

        if [ $braces -eq 0 ] && [[ -n $proto || $line =~ $proto_start_regex ]]; then
            proto+="$line "
            if [[ $line =~ \)\s* ]]; then
                if [[ $proto =~ $regex ]]; then
                    func_name=${BASH_REMATCH[1]}
                    line_count=0
                    braces=0
                    exported_funcs=$((exported_funcs + 1))
                    if [[ $proto =~ ^static ]]; then
                        exported_funcs=$((exported_funcs - 1))
                    fi
                fi
                proto=""
            fi
            continue
        fi

        if [[ $line =~ $opening_brace ]]; then
            braces=$((braces + 1))
        elif [[ $line =~ $closing_brace ]]; then
            braces=$((braces - 1))
            if [ $braces -eq 0 ]; then
                if [ $line_count -gt $THRESHOLD ]; then
                    echo -e "    $BRed$func_name: $Red$line_count$NoC"
                else
                    echo -e "    $BGre$func_name: $Gre$line_count$NoC"
                fi
            fi
        elif [[ $line =~ $empty_line ]]; then
            continue
        else
            line_count=$((line_count + 1))
        fi
    done < "$1"

    if [ $exported_funcs -gt 10 ]; then
        echo -e "${Red}=== ${BRed}$exported_funcs ${Red}===${NoC}"
    else
        echo -e "${Gre}=== ${BGre}$exported_funcs ${Gre}===${NoC}"
    fi
}

parser() {
    local path=$1
    local MODE=$2

    # Utilisation de find pour éviter les bugs avec ls
    for file in $(find . -maxdepth 1 -not -path '*/.*' | sort -r); do
        file=$(basename "$file")
        if [ "$file" = "." ]; then continue; fi

        if [ -d "$file" ]; then
            cd "$file"
            parser "$path/$file" "$MODE"
            cd ..
        elif [ -f "$file" ]; then
            if [ "$MODE" -eq 1 ]; then
                if [[ "$file" == *.c ]] || [[ "$file" == *.h ]]; then
                    echo "$path/$file"
                    clang-format -i "$file"
                fi
            elif [ "$MODE" -eq 2 ] && [[ "$file" == *.c ]]; then
                echo "$path/$file:"
                count_lines "$file"
                echo
            fi
        fi
    done
}

if [ $# -ne 2 ]; then

    if [ -f "Makefile" ]; then
        echo -e "${BWht}make clean:${NoC}"
        make clean
        echo ""
    fi

    cd src

    echo -e "${BWht}Seuil sélectionné : $THRESHOLD lignes${NoC}"
    echo -e "${BWht}clang-format:${NoC}"
    parser . 1

    echo ""

    echo -e "${BWht}count-lines:${NoC}"
    parser . 2

    n=$(find . -type f \( -name "*.c" -o -name "*.h" \) -exec wc -l {} + | tail -n1)
    echo "Total code-lines written: $n"

    cd ..

else

    FILENAME=$2

    if [ -f "Makefile" ]; then
        echo -e "${BWht}make clean:${NoC}"
        make clean
        echo ""
    fi

    echo -e "${BWht}Seuil sélectionné : $THRESHOLD lignes${NoC}"
    echo -e "${BWht}clang-format:${NoC}"
    echo "./$FILENAME"

    echo ""

    echo -e "${BWht}count-lines:${NoC}"
    count_lines $2

fi
