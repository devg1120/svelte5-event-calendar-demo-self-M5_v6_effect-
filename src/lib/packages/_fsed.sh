

#"run(()"
#"$effect(()"


#find $1 -type f -name "*.svelte" | xargs sed -i "s/run(()/\$effect(()/g"
sed -i "s/run(()/\$effect(()/g" $1
#sed -i "s/\$effect(()/run(()/g" $1



