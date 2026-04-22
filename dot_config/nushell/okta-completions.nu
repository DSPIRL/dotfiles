def "nu-complete okta profiles" [] {
    if (which okta-aws-cli | is-empty) {
        []
    } else {
        ^okta-aws-cli list-profiles
        | lines
        | each {|line| $line | str trim }
        | where {|line| $line != "" and $line != "Profiles:" }
    }
}

extern "okta-aws-cli" [
    --profile(-p): string@"nu-complete okta profiles"
    ...rest
]
