#!/bin/bash

# =========================
# Password Security Toolkit
# =========================

RED="\e[31m"
YELLOW="\e[33m"
GREEN="\e[32m"
BLUE="\e[34m"
CYAN="\e[36m"
RESET="\e[0m"

COMMON_FILE="common_passwords.txt"
LOG_DIR="logs"
LOG_FILE="$LOG_DIR/password_checker.log"

mkdir -p "$LOG_DIR"

score=0
feedback=()
password=""

show_banner() {
    clear
    echo -e "${CYAN}======================================${RESET}"
    echo -e "${CYAN}      Password Security Toolkit       ${RESET}"
    echo -e "${CYAN}======================================${RESET}"
    echo
}

pause() {
    echo
    read -p "Press Enter to continue..."
}

log_result() {
    local result_strength="$1"
    local result_score="$2"
    local length="${#password}"

    echo "$(date '+%Y-%m-%d %H:%M:%S') | Strength: $result_strength | Score: $result_score/100 | Length: $length" >> "$LOG_FILE"
}

reset_checker() {
    score=0
    feedback=()
}

get_password() {
    echo
    read -s -p "Enter your password: " password
    echo
}

check_length() {
    local len=${#password}

    if [ "$len" -ge 16 ]; then
        score=$((score + 30))
    elif [ "$len" -ge 12 ]; then
        score=$((score + 25))
    elif [ "$len" -ge 8 ]; then
        score=$((score + 15))
        feedback+=("Use 12 or more characters for better security.")
    else
        feedback+=("Password is too short. Use at least 8 characters.")
    fi
}

check_lowercase() {
    if [[ "$password" =~ [a-z] ]]; then
        score=$((score + 10))
    else
        feedback+=("Add lowercase letters.")
    fi
}

check_uppercase() {
    if [[ "$password" =~ [A-Z] ]]; then
        score=$((score + 10))
    else
        feedback+=("Add uppercase letters.")
    fi
}

check_numbers() {
    if [[ "$password" =~ [0-9] ]]; then
        score=$((score + 10))
    else
        feedback+=("Add numbers.")
    fi
}

check_special() {
    if [[ "$password" =~ [\!\@\#\$\%\^\&\*\(\)_\+\=\-\[\]\{\}\;\:\'\"\,\.\<\>\/\?\|\\] ]]; then
        score=$((score + 15))
    else
        feedback+=("Add special characters.")
    fi
}

check_common_passwords() {
    if [ -f "$COMMON_FILE" ]; then
        while IFS= read -r common; do
            if [[ -n "$common" && "${password,,}" == "${common,,}" ]]; then
                score=$((score - 30))
                feedback+=("This is a very common password. Choose something unique.")
                return
            fi
        done < "$COMMON_FILE"
    fi
}

check_repeated_chars() {
    if [[ "$password" =~ (.)\1\1 ]]; then
        score=$((score - 10))
        feedback+=("Avoid repeated characters like 'aaa' or '111'.")
    fi
}

check_sequences() {
    local lower_pass="${password,,}"

    if [[ "$lower_pass" == "123" ]] || \
       [[ "$lower_pass" == "abc" ]] || \
       [[ "$lower_pass" == "qwerty" ]] || \
       [[ "$lower_pass" == "password" ]]; then
        score=$((score - 15))
        feedback+=("Avoid predictable sequences like '123', 'abc', 'qwerty', or 'password'.")
    fi
}

check_only_letters_or_numbers() {
    if [[ "$password" =~ ^[a-zA-Z]+$ ]]; then
        score=$((score - 10))
        feedback+=("Do not use only letters. Add numbers and symbols.")
    elif [[ "$password" =~ ^[0-9]+$ ]]; then
        score=$((score - 15))
        feedback+=("Do not use only numbers.")
    fi
}

check_spaces() {
    if [[ "$password" =~ [[:space:]] ]]; then
        feedback+=("Avoid spaces in the password.")
    fi
}

check_variety_bonus() {
    local classes=0

    [[ "$password" =~ [a-z] ]] && classes=$((classes + 1))
    [[ "$password" =~ [A-Z] ]] && classes=$((classes + 1))
    [[ "$password" =~ [0-9] ]] && classes=$((classes + 1))
    [[ "$password" =~ [\!\@\#\$\%\^\&\*\(\)_\+\=\-\[\]\{\}\;\:\'\"\,\.\<\>\/\?\|\\] ]] && classes=$((classes + 1))

    if [ "$classes" -eq 4 ]; then
        score=$((score + 10))
    fi
}

calculate_strength() {
    if [ "$score" -lt 0 ]; then
        score=0
    elif [ "$score" -gt 100 ]; then
        score=100
    fi

    if [ "$score" -lt 40 ]; then
        strength="Weak"
        color="$RED"
    elif [ "$score" -lt 70 ]; then
        strength="Medium"
        color="$YELLOW"
    else
        strength="Strong"
        color="$GREEN"
    fi
}

show_result() {
    echo
    echo -e "Password Strength: ${color}${strength}${RESET}"
    echo "Score: $score/100"
    echo

    if [ ${#feedback[@]} -gt 0 ]; then
        echo "Suggestions:"
        for tip in "${feedback[@]}"; do
            echo "- $tip"
        done
    else
        echo -e "${GREEN}Great password!${RESET}"
    fi
}

check_password_flow() {
    reset_checker
    get_password

    if [ -z "$password" ]; then
        echo -e "${RED}Error: Password cannot be empty.${RESET}"
        pause
        return
    fi

    check_length
    check_lowercase
    check_uppercase
    check_numbers
    check_special
    check_common_passwords
    check_repeated_chars
    check_sequences
    check_only_letters_or_numbers
    check_spaces
    check_variety_bonus
    calculate_strength
    show_result
    log_result "$strength" "$score"

    pause
}

generate_password() {
    echo
    read -p "Enter desired password length (default 16): " length

    if [[ -z "$length" ]]; then
        length=16
    fi

    if ! [[ "$length" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Invalid length. Please enter a number.${RESET}"
        pause
        return
    fi

    if [ "$length" -lt 8 ]; then
        echo -e "${YELLOW}Length too short. Using 8 instead.${RESET}"
        length=8
    fi

    local charset='A-Za-z0-9!@#$%^&*()_+=-[]{};:,.<>?'
    local generated

    generated=$(tr -dc "$charset" < /dev/urandom | head -c "$length")

    echo
    echo -e "${GREEN}Generated Password:${RESET} $generated"
    echo

    pause
}

view_logs() {
    echo
    if [ -f "$LOG_FILE" ]; then
        echo -e "${BLUE}Saved Check Results:${RESET}"
        echo "--------------------------------------"
        cat "$LOG_FILE"
    else
        echo -e "${YELLOW}No logs found yet.${RESET}"
    fi
    pause
}

show_common_file_status() {
    echo
    if [ -f "$COMMON_FILE" ]; then
        echo -e "${GREEN}Common password file loaded:${RESET} $COMMON_FILE"
    else
        echo -e "${YELLOW}No common password file found.${RESET}"
        echo "Create $COMMON_FILE to improve detection."
    fi
    pause
}

main_menu() {
    while true; do
        show_banner
        echo "1) Check password strength"
        echo "2) Generate strong password"
        echo "3) View saved logs"
        echo "4) Check common password file status"
        echo "5) Exit"
        echo
        read -p "Choose an option: " choice

        case "$choice" in
            1) check_password_flow ;;
            2) generate_password ;;
            3) view_logs ;;
            4) show_common_file_status ;;
            5)
                echo
                echo -e "${CYAN}Goodbye.${RESET}"
                exit 0
                ;;
            *)
                echo
                echo -e "${RED}Invalid choice. Try again.${RESET}"
                pause
                ;;
        esac
    done
}

main_menu 
