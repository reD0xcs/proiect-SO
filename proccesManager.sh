#!/bin/bash

get_process_type() {
    local pid=$1
    local cpu_usage=$(ps -p "$pid" -o %cpu --no-headers)
    local io_usage=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')

    if (( $(echo "$cpu_usage > $io_usage" | bc 2> /dev/null) )); then
        echo "CPU-bound"
    elif (( $(echo "$io_usage > $cpu_usage" | bc 2> /dev/null) )); then
        echo "I/O-bound"
    else
        echo "Balanced"
    fi
}

show_commands() {
    echo "Usage: ./your_script.sh [options]"
    echo "Options:"
    echo "  cpu             Display CPU usage information"
    echo "  memory          Display memory usage information"
    echo "  sortcpu         Display processes sorted by CPU usage"
    echo "  sortmem         Display processes sorted by memory usage"
    echo "  tree            Display process tree"
    echo "  nonzero         Display processes with nonzero CPU and memory usage"
    echo "  save            Save the output to a file"
    echo "  help            Display this help menu"
    echo "  Example: ./your_script.sh cpu sortcpu save"
}

is_numeric() {
    local value=$1


    # Use a regular expression to check if the value is numeric
    if [[ "$value" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        return 1  # Success, it's numeric
    else
        return 0  # Failure, it's not numeric
    fi
}

check_greater_than_zero() {
    local value=$1
    # Use awk for floating-point comparison
    awk -v value="$value" 'BEGIN { if (value > 0.0) exit 0; else exit 1; }'
}

tree_print(){
    # Obtine arborele de procese
pstree -p -c > procese_arbore.txt

# Itereaza prin fiecare linie din fisier
while IFS= read -r line; do
    # Extrage PID-urile din linie
    pids=$(echo "$line" | grep -oP '\(\K[0-9]+')

    # Construieste un string pentru fiecare proces cu informatii despre CPU si memorie
    for pid in $pids; do
        # Debugging: Print the PID for each iteration

        # Debugging: Print the process information for each PID

        cpu_info=$(ps -p "$pid" -o %cpu --no-headers)
        mem_info=$(ps -p "$pid" -o %mem --no-headers)

        # Debugging: Print CPU and memory info for each PID

        line=$(echo "$line" | sed "s/\($pid\)/\1 C: $cpu_info M: $mem_info/")

    done

    # Afiseaza linia actualizata
    echo "$line"

done < procese_arbore.txt

# Sterge fisierul temporar
rm procese_arbore.txt
}

print_header(){
    local format=$1
    local output_file=$2
    local save=$3

    case $format in
        0)
            printf "%-10s %-38s %-10s %-10s %-10s %s\n" "PID" "Name" "CPU (%)" "Memory (%)" "I/O (KB/s)" "Type"
            echo "=========================================================================================="

            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s %-10s %-10s %s\n" "PID" "Name" "CPU (%)" "Memory (%)" "I/O (KB/s)" "Type" > "$output_file"
                echo "==========================================================================================" >> "$output_file"
            fi
            ;;
        1)
            printf "%-10s %-38s %-10s\n" "PID" "Name" "CPU (%)"
            echo "==========================================================="
            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s\n" "PID" "Name" "CPU (%)" > "$output_file"
                echo "===========================================================" >> "$output_file"
            fi
            ;;
        2)
            printf "%-10s %-38s %-10s\n" "PID" "Name" "Memory (%)"
            echo "==========================================================="

            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s\n" "PID" "Name" "Memory (%)" > "$output_file"
                echo "===========================================================" >> "$output_file"
            fi
            ;;
        3)
            printf "%-10s %-38s %-10s %-10s\n" "PID" "Name" "CPU (%)" "Memory (%)"
            echo "====================================================================="

            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s %-10s\n" "PID" "Name" "CPU (%)" "Memory (%)" > "$output_file"
                echo "=====================================================================" >> "$output_file"
            fi
            ;;
        *)
            echo "Invalid argument . Please use 'cpu', 'memory', or 'both'."
            exit 1
            ;;
    esac
}
print_process_info() {
    local format=$1
    local pid=$2
    local name=$3
    local cpu=$4
    local memory=$5
    local io=$6
    local type=$7
    local save=$8

    case $format in
        0)
            printf "%-10s %-38s %-10s %-10s %-10s %s\n" "$pid" "$name" "$cpu" "$memory" "$io" "$type"

            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s %-10s %-10s %s\n" "$pid" "$name" "$cpu" "$memory" "$io" "$type" >> "$output_file"

            fi
            ;;
        1)
            if is_numeric "$cpu"; then
                printf "%-10s %-38s %-10s \n" "$pid" "$name" "$cpu"
            fi
            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s \n" "$pid" "$name" "$cpu" >> "$output_file"

            fi
            ;;
        2)
            printf "%-10s %-38s %-10s \n" "$pid" "$name"  "$memory"
            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s \n" "$pid" "$name"  "$memory" >> "$output_file"

            fi
            ;;
        3)
            printf "%-10s %-38s %-10s %-10s \n" "$pid" "$name" "$cpu" "$memory"
            if [ "$save" -eq 1 ]; then

                printf "%-10s %-38s %-10s %-10s \n" "$pid" "$name" "$cpu" "$memory" >> "$output_file"

            fi
            ;;
    esac
}

itarate_through_pids(){
    local format=$1
    local header=$2
    local save=$3

    case $format in
        0)
            for pid in $(ps -e -o pid --no-headers); do
                # Get process information
                name=$(ps -p "$pid" -o comm=)
                cpu=$(ps -p "$pid" -o %cpu --no-headers)
                memory=$(ps -p "$pid" -o %mem --no-headers)
                io=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')
                type=$(get_process_type "$pid")

                print_process_info "$header" "$pid" "$name" "$cpu" "$memory" "$io" "$type" "$save"
            done
            ;;
        1)
            for pid in $(ps -e --sort=-%cpu -o pid --no-headers); do
                # Get process information
                name=$(ps -p "$pid" -o comm=)
                cpu=$(ps -p "$pid" -o %cpu --no-headers)
                memory=$(ps -p "$pid" -o %mem --no-headers)
                io=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')
                type="test"

                print_process_info "$header" "$pid" "$name" "$cpu" "$memory" "$io" "$type" "$save"
            done
            ;;
        2)
           for pid in $(ps -e --sort=-%mem -o pid --no-headers); do
                # Get process information
                name=$(ps -p "$pid" -o comm=)
                cpu=$(ps -p "$pid" -o %cpu --no-headers)
                memory=$(ps -p "$pid" -o %mem --no-headers)
                io=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')
                type=$(get_process_type "$pid")

                print_process_info "$header" "$pid" "$name" "$cpu" "$memory" "$io" "$type" "$save"
            done
            ;;
        3)
            for pid in $(ps -e -o pid --no-headers); do
                # Get process information
                name=$(ps -p "$pid" -o comm=)
                cpu=$(ps -p "$pid" -o %cpu --no-headers)
                memory=$(ps -p "$pid" -o %mem --no-headers)
                io=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')
                type=$(get_process_type "$pid")

                if  check_greater_than_zero "$cpu" ||  check_greater_than_zero "$memory"; then
                    print_process_info "$header" "$pid" "$name" "$cpu" "$memory" "$io" "$type" "$save"
                fi
            done
            ;;
        4)
            for pid in $(ps -e --sort=-%cpu -o pid --no-headers); do
                # Get process information
                name=$(ps -p "$pid" -o comm=)
                cpu=$(ps -p "$pid" -o %cpu --no-headers)
                memory=$(ps -p "$pid" -o %mem --no-headers)
                io=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')
                type=$(get_process_type "$pid")

                if  check_greater_than_zero "$cpu" ||  check_greater_than_zero "$memory"; then
                    print_process_info "$header" "$pid" "$name" "$cpu" "$memory" "$io" "$type" "$save"
                fi
            done
            ;;
        5)
           for pid in $(ps -e --sort=-%mem -o pid --no-headers); do
                # Get process information
                name=$(ps -p "$pid" -o comm=)
                cpu=$(ps -p "$pid" -o %cpu --no-headers)
                memory=$(ps -p "$pid" -o %mem --no-headers)
                io=$(sudo iotop -b -n 1 -P -p "$pid" | awk '/Total/ {print $10}')
                type=$(get_process_type "$pid")

                if  check_greater_than_zero "$cpu" ||  check_greater_than_zero "$memory"; then
                    print_process_info "$header" "$pid" "$name" "$cpu" "$memory" "$io" "$type" "$save"
                fi
            done
            ;;
    esac

}

tree=0
output_file="output.txt"
save=0
today=$(date +"%Y-%m-%d_%H-%M-%S")
output_file_today="output_$today.txt"
help=0

if [ "$#" -eq 0 ]; then
    header_format=0
    info_format=0
elif [ "$#" -eq 1 ]; then
    case "$1" in
    "cpu")
        header_format=1
        info_format=0
        ;;
    "memory")
        header_format=2
        info_format=0
        ;;
    "save")
        header_format=0
        info_format=0
        save=1
        ;;
    "sortcpu")
        header_format=0
        info_format=1
        ;;
    "sortmem")
        header_format=0
        info_format=2
        ;;
    "tree")
        tree=1
        ;;
    "nonzero")
        header_format=0
        info_format=3
        ;;
    "help")
        help=1
        ;;
    esac

elif [ "$#" -eq 2 ]; then
    case "$1 $2" in
        "cpu memory")
            header_format=3
            info_format=0
            ;;
        "memory cpu")
            header_format=3
            info_format=0
            ;;
        "cpu sortcpu")
            header_format=1
            info_format=1
            ;;
        "sortcpu cpu")
            header_format=1
            info_format=1
            ;;
        "memory sortcpu")
            header_format=2
            info_format=1
            ;;
        "sortcpu memory")
            header_format=2
            info_format=1
            ;;
        "cpu sortmem")
            header_format=1
            info_format=2
            ;;
        "sortmem cpu")
            header_format=1
            info_format=2
            ;;
        "memory sortmem")
            header_format=2
            info_format=2
            ;;
        "sortmem memory")
            header_format=2
            info_format=2
            ;;
        "cpu nonzero")
            header_format=1
            info_format=3
            ;;
        "nonzero cpu")
            header_format=1
            info_format=3
            ;;
        "memory nonzero")
            header_format=2
            info_format=3
            ;;
        "nonzero memory")
            header_format=2
            info_format=3
            ;;
        "cpu save")
            header_format=1
            save=1
            ;;
        "save cpu")
            header_format=1
            save=1
            info_format=0
            ;;
        "memory save")
            header_format=2
            save=2
            info_format=0
            ;;
        ("save memory")
            header_format=2
            save=2
            info_format=0
            ;;
        "sortcpu save")
            header_format=0
            info_format=1
            save=1
            ;;
        "save sortcpu")
            header_format=0
            info_format=1
            save=1
            ;;
        "sortmem save")
            header_format=0
            info_format=2
            save=1
            ;;
        "save sortmem")
            header_format=0
            info_format=2
            save=1
            ;;
        "save nonzero")
            header_format=0
            info_format=3
            save=1
            ;;
        "sortcpu nonzero")
            header_format=0
            info_format=4
            ;;
        "nonzero sortcpu")
            header_format=0
            info_format=4
            ;;
        "nonzero sortmem")
            header_format=0
            info_format=5
            ;;
        "sortmem nonzero")
            header_format=0
            info_format=5
            ;;
    esac
else
    header_format=4
    info_format=0
fi
if [ "$help" -eq 1 ]; then
    show_commands
fi

if [ "$tree" -eq 1 ]; then
    tree_print
else
    print_header "$header_format" "$output_file" "$save"
    itarate_through_pids "$info_format" "$header_format" "$save"
    if [ "$save" -eq 1 ]; then
        cp "$output_file" "$output_file_today"
        rm "$output_file"
    fi
fi