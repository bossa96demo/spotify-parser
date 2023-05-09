# getting user data
read -p "playlist id(ex. 37i9dQZF1DX2pprEpa9URZ): " playlist_id
read -p "client id(see readme): " client_id
read -p "client secret(see readme): " client_secret

# getting access token from spotify
url="https://accounts.spotify.com/api/token"
req=$(curl --request POST --url "$url" --header "Content-Type: application/x-www-form-urlencoded" --data "grant_type=client_credentials&client_id=$client_id&client_secret=$client_secret")
token=$(echo $req | jq ".access_token" | tr -d '"')

# counting all the songs user got in playlist
url="https://api.spotify.com/v1/playlists/$playlist_id/tracks"
req=$(curl --request GET --url "$url" --header "Authorization: Bearer $token")
total=$(echo $req | jq ".total")
echo "you have $total songs in your playlist"

#function to parse and write songs in 1 file
function last_step {
	for i in {0..99}; do
		abob=$(cat $1 | jq ".items" | jq ".[$i]" | jq ".track")
		name=$(echo $abob | jq '.name' | tr -d '"')
		artist=$(echo $abob | jq '.artists' | jq '.[0]' | jq '.name' | tr -d '"')
		echo "$name - $artist" >> "a-little-bit-left"
	done
}

# doing math to exract all songs and to forget anything
batch_size=100
num_batches=$(echo "($total + $batch_size - 1) / $batch_size" | bc)
echo $num_batches 

# getting songs with spotify api
for i in $(seq 0 $num_batches); do
	offset=$(( $i * $batch_size ))
	echo $offset songs already extracted
	songs=$(curl --silent --request GET --url "$url?limit=$batch_size&offset=$offset" --header "Authorization: Bearer $token")
	echo $songs > "abob_song$i"
done

# parsing and writing (last step)
for i in $(seq 0 $num_batches); do
	echo "$(( $i * 100 )) songs was carefully parsed and added to file"
	last_step "abob_song$i"
	rm "abob_song$i"
done
cat "a-little-bit-left" | sed "s/null - null//g" | grep -v "^$" > final_output.txt
rm a-little-bit-left
