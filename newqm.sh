o#!/bin/bash

# Bash IOS-style ? Helper
# This script adds Cisco IOS-style '?' help to Bash by using Readline key bindings.

# Temporary file to store command completions
HELP_FILE="/tmp/bash_ios_helper_completions.txt"

# Function to generate command completions with descriptions
_bash_ios_helper() {
    local cur prev opts
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # If the current command is empty, list all available commands
    if [[ -z "$cur" ]]; then
        COMPREPLY=( $(compgen -c) )
    else
        # Generate completions for the current command context
        COMPREPLY=( $(compgen -A command -- "$cur") )
    fi

    # Collect commands and their descriptions
    > "$HELP_FILE"
    for cmd in "${COMPREPLY[@]}"; do
        desc=$(man "$cmd" 2>/dev/null | col -bx | sed -n '/^NAME/,/^$/p' | head -n 2 | tail -n 1 | sed 's/^ *//')
        if [[ -z "$desc" ]]; then
            desc="No description available."
        fi
        printf "%s - %s\n" "$cmd" "$desc" >> "$HELP_FILE"
    done

    # Sort the output alphabetically
    sort "$HELP_FILE" -o "$HELP_FILE"
}

# Bind the ? key using octal representation to trigger the helper
bind '"\C-x?": "\C-a_display_bash_ios_help \n"'

# Function to display help suggestions when ? is pressed
_display_bash_ios_help() {
    # Get the current command line buffer
    local current_command
    current_command=$(fc -ln -0)

    # If the last character is a space or the line is empty, show help
    if [[ -z "$current_command" || "$current_command" =~ \ $ ]]; then
        _bash_ios_helper
        if [[ -s "$HELP_FILE" ]]; then
            echo -e "\nAvailable commands:\n"
            cat "$HELP_FILE"
        else
            echo -e "\nNo suggestions found."
        fi
    else
        # Otherwise, insert the ? character as usual
        READLINE_LINE+="?"
        READLINE_POINT=$((READLINE_POINT+1))
    fi
}

# Load the script into the current shell session
if [[ "$0" == "$BASH_SOURCE" ]]; then
    echo "Run 'source bash_ios_helper.sh' to activate the helper in your current shell session."
fi
