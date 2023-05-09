# getting user data
read -p "playlist id(ex. 37i9dQZF1DX2pprEpa9URZ): " playlist_id
read -p "client id(see readme): " client_id
read -p "client secret(see readme): " client_secret

# getting access token from spotify
url="https://accounts.spotify.com/api/token"
req=$(curl --silent --request POST --url "$url" --header "Content-Type: application/x-www-form-urlencoded" --data "grant_type=client_credentials&client_id=$client_id&client_secret=$client_secret")
token=$(echo $req | jq ".access_token" | tr -d '"')

# counting all the songs user got in playlist
url="https://api.spotify.com/v1/playlists/$playlist_id/tracks"
req=$(curl --silent --request GET --url "$url" --header "Authorization: Bearer $token")
total=$(echo $req | jq ".total")
echo "you have $total songs in your playlist"

#function to parse and write songs in 1 file
function last_step {
	for i in {0..99}; do
		abob=$(cat $1 | jq ".items" | jq ".[$i]" | jq ".track")
		name=$(echo $abob | jq '.name' | tr -d '"')
		artist=$(echo $abob | jq '.artists' | jq '.[0]' | jq '.name' | tr -d '"')
		echo "$name - $artist" | sed 's/null - null//g' | grep -v '^$' >> "final_output.txt"
	done
}

# in case the script runs more than 1 time
test -e final_output.txt | rm -i final_output.txt

# doing math to exract all songs and to forget anything
batch_size=100
num_batches=$(echo "($total + $batch_size - 1) / $batch_size" | bc)
echo $num_batches 

# getting songs with spotify api
for i in $(seq 0 $num_batches); do
	offset=$(( $i * $batch_size ))
	echo -ne "$offset songs already extracted\r"
	songs=$(curl --silent --request GET --url "$url?limit=$batch_size&offset=$offset" --header "Authorization: Bearer $token")
	echo $songs > "abob_song$i"
done
echo "extracting finished. starting parsing."

# parsing and writing (last step)
for i in $(seq 0 $num_batches); do
	echo -ne "$(( $i * 100 )) songs was carefully parsed and added to file\r"
	last_step "abob_song$i"
done

echo "everything is done! result waits you in final_output.txt"
rm abob_song*
