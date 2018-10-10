#!/bin/bash
IFS=""
while read -r line ; do
    while [[ "$line" =~ (\$\{[a-zA-Z_][a-zA-Z_0-9]*\}) ]] ; do
        LHS=${BASH_REMATCH[1]}
        RHS="$(eval echo "\"$LHS\"")"
        line=${line//$LHS/$RHS}
        # line=$(echo "$line" | sed "s/$LHS/$RHS/g")
    done
    echo "$line"
done

# brew install gettext
# brew link --force gettext

# ./.env:
# SOME_VARIABLE_1=value_1
# SOME_VARIABLE_2=value_2

# ./template
# this_variable_1 = ${SOME_VARIABLE_1}
# this_variable_2 = ${SOME_VARIABLE_2}

# . .env
# cat template | envsubst > test
