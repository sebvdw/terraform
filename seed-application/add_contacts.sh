# TODO: parse data.txt and add to database

# The json format in which your need to post the data has to look like this:
# { 
#     "email": "example@example.com,
#     "shortname": "abc01",
#     "fullname": "name of person"
# }
#!/bin/bash

while IFS= read -r line; do
  if [[ $line == "person[" ]]; then
    # Initialize variables
    name=""
    email=""
    code=""
  elif [[ $line == "  name{"* ]]; then
    # Extract name
    name=$(echo "$line" | sed 's/.*{"\(.*\)"}$/\1/')
  elif [[ $line == "  email{"* ]]; then
    # Extract email
    email=$(echo "$line" | sed 's/.*{"\(.*\)"}$/\1/')
  elif [[ $line == "  code{"* ]]; then
    # Extract code
    code=$(echo "$line" | sed 's/.*{"\(.*\)"}$/\1/')
  elif [[ $line == "]" ]]; then
    # Send JSON body using curl
    json=$(cat <<EOF
{
  "fullname": "$name",
  "email": "$email",
  "shortname": "$code"
}
EOF
)
    curl -X POST -H "Content-Type: application/json" -d "$json" http://localhost:5000
  fi
done < "data.txt"
