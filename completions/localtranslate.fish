# fish completion for localtranslate

function __fish_localtranslate_completions
    set -l cmd (commandline -opc)

    # Rule 1: Exclusive options terminate completion.
    if contains -- -h --help --help-all -v --version --list-languages $cmd
        return
    end

    set -l last_item (commandline -opc)[-1]

    # Rule 2: Suggest language codes after --from or --to.
    if test "$last_item" = "--from" -o "$last_item" = "--to"
        localtranslate --list-languages | awk '{desc=$0; sub($1"[ 	]+", "", desc); print $1 "\t" desc}'
        return
    end

    # Rule 3: If both --from and --to are present, suggest no more options.
    if contains -- --from $cmd; and contains -- --to $cmd
        return
    end

    # Rule 4: If only --from is present, suggest only --to.
    if contains -- --from $cmd
        printf "%s\t%s\n" "--to" "Set target language"
        return
    end

    # Rule 5: If only --to is present, suggest only --from.
    if contains -- --to $cmd
        printf "%s\t%s\n" "--from" "Set source language"
        return
    end

    # Rule 6: Default case. If none of the above, suggest initial options.
    printf "%s\t%s\n" "--from" "Set source language"
    printf "%s\t%s\n" "--to" "Set target language"
    printf "%s\t%s\n" "-h" "Show help message"
    printf "%s\t%s\n" "--help" "Show help message"
    printf "%s\t%s\n" "--help-all" "Show all help options"
    printf "%s\t%s\n" "-v" "Show version information"
    printf "%s\t%s\n" "--version" "Show version information"
    printf "%s\t%s\n" "--list-languages" "List available languages"
end

# Register the completion function.
complete -c localtranslate -f -a "(__fish_localtranslate_completions)"
