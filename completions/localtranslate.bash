# Final bash completion script for localtranslate

_localtranslate_completions() {
    local cur prev i opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # --- State tracking variables ---
    local from_present=0
    local to_present=0
    local exclusive_opt_present=0

    # --- Scan the command line for used options ---
    # Iterate through all words *before* the current cursor position.
    for ((i=1; i < COMP_CWORD; i++)); do
        local word="${COMP_WORDS[i]}"
        case "$word" in
            --from) from_present=1 ;;
            --to) to_present=1 ;;
            -h|--help|--help-all|-v|--version|--list-languages)
                exclusive_opt_present=1
                ;;
        esac
    done

    # --- Rule 1: Handle terminating conditions ---

    # If an exclusive option like --version is already used, offer no more suggestions.
    if [[ $exclusive_opt_present -eq 1 ]]; then
        COMPREPLY=()
        return 0
    fi

    # --- Rule 2: Provide language code completions ---
    case "$prev" in
        --from|--to)
            # Dynamically get the list of language codes from the app itself.
            # The `awk '{print $1}'` command extracts the first column (the codes).
            local lang_codes
            lang_codes=$(localtranslate --list-languages | awk '{print $1}')
            
            # Suggest the language codes.
            COMPREPLY=($(compgen -W "${lang_codes}" -- "${cur}"))
            return 0
            ;;
    esac

    # --- Rule 3: Build the list of valid next options ---
    
    if [[ $from_present -eq 1 && $to_present -eq 1 ]]; then
        # Both --from and --to are present, so no more options should be suggested.
        opts=""
    elif [[ $from_present -eq 1 ]]; then
        # If --from is used, the ONLY valid next option is --to.
        opts="--to"
    elif [[ $to_present -eq 1 ]]; then
        # If --to is used, the ONLY valid next option is --from.
        opts="--from"
    else
        # If neither are present, offer all initial options.
        opts="-h --help --help-all -v --version --list-languages --from --to"
    fi

    # --- Generate completions for flags ---
    COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    return 0
}

# Register the completion function for your program
complete -F _localtranslate_completions localtranslate
