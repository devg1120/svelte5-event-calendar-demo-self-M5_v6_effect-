

#"run(()"
#"$effect(()"


#find $1 -type f -name "*.svelte" | xargs sed -i "s/run(()/\$effect(()/g"
find $1 -type f -name "*.svelte" | xargs sed -i "s/\$effect(()/run(()/g"



