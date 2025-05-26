dc() {
  local logo=(
"     _==/          i     i          \\==_"
"   /XX/            |\\___/|            \\XX\\"
"  /XXXX\\            |XXXXX|            /XXXX\\"
" |XXXXXX\\_         _XXXXXXX_         _/XXXXXX|"
"X|XXXXXXXXXXxxxxxxxXXXXXXXXXXXxxxxxxxXXXXXXXX|X"
"|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|"
"XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
"|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|"
"X|XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|X"
" |XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX|"
"  \\XXX/    \\XXXXXXXXXXXXXXXXXXXXXX/    \\XXX/"
"   \\XX\\      \\XXXXXXXXXXXXXXXXXX/      /XX/"
"      \"        \\XXXXXXXXXXXXXX/        \""
"                 \\XXXXXXXXXXX/" 
"                   \\XXXXXXX/" 
"                     \\XXX/" 
"                       !" 
) 


  local cols=$(tput cols)
  local rows=$(tput lines)
  local logo_height=${#logo[@]}
  local logo_width=0

  for line in "${logo[@]}"; do
    (( ${#line} > logo_width )) && logo_width=${#line}
  done

  local start_row=$(( (rows - logo_height) / 2 ))

  tput civis
  trap 'tput cnorm; tput rmcup; exit' INT

  tput smcup

  for ((pos = -logo_width; pos < cols; pos++)); do
    for ((i = 0; i < logo_height; i++)); do
      tput cup $((start_row + i)) 0
      local line="${logo[$i]}"
      local visible

      if (( pos < 0 )); then
        visible="${line: -pos}"
      else
        visible="$(printf "%${pos}s%s" "" "$line")"
      fi

      printf "%-${cols}s" "${visible:0:$cols}"
    done
    sleep 0.01
  done

  tput rmcup
  tput cnorm
}
