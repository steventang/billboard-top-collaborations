# this script counts the number of times an artist has done a collaboration in our data
require 'csv'

# Creates a csv that separates out each artist from a collab
def pull_artists
	CSV.open('data/artist_counts.csv', "w") do |csv|
		CSV.foreach('data/complete_song_data.csv', headers: true) do |row|
		
			if row['collab'] == "1"
				# First, split artist string into individual artists
				artist_array = row['artist'].downcase.gsub("featuring", " , ")
																						 .gsub(" & ", " , ")
																						 .gsub("feat.", " , ")
																						 .gsub(" and ", " , ")
																						 .gsub(" with ", " , ")
																						 .gsub(" duet ", " , ")
																						 .gsub("/", " , ")
																						 .gsub(" + ", " , ")
																						 .gsub(/[()]/, "")
																						 .split(",")
																						 .map(&:strip)

				# Remove all entries that are commas
				artist_array.delete(",")


				# Add date and title to begnning of each row before writing to csv
				artist_array.unshift(row['title']).unshift(row['date'])

				# Count number of collabooraters
				artist_array.unshift(artist_array.length - 1)

				csv << artist_array
			end
		end
	end
	puts "artist_counts.csv generated"
end

# Returns an array of arrays with unique_artists[0] as artist name and unique_artist[1] as occurences of artist
def get_song_weeks
	all_artists = []
	CSV.foreach('data/artist_counts.csv') do |row|
		# Add each artist entry into the array, with dupes, remove nils
		all_artists += row[3..-1].compact
	end
	all_artists.uniq.map { |x| [x, all_artists.count(x)] }
end

# Returns all unique [artist, song] pairs
def get_artists_songs
	all_artists_songs = []
	CSV.foreach('data/artist_counts.csv') do |row|
		row[3..-1].compact.each do |i|
			all_artists_songs << [i, row[2]]
		end
	end
	all_artists_songs.uniq
end

# Returns array of array of artists along with num of unique collab songs they've been a part of
def get_num_songs
	artist_nums = []
	all_artists_songs = get_artists_songs
	all_artists_songs.each do |artist, songs|
		# Count occurence of artist in first row of all_artist_songs
		artist_nums << [artist, all_artists_songs.find_all { |i| i[0] == artist }.length]
		# Delete all occurances of artist to reduce redundancy
		all_artists_songs.delete_if { |i| i[0] == artist }
	end
	artist_nums
end

def generate_csv(file_name, data_array, header_array)
	CSV.open("data/#{file_name}.csv", "w") do |csv|
		csv << header_array
		data_array.each { |row| csv << row }
	end
	puts "Generated #{file_name}.csv"
end

# Return array of arrays of size list_size of artists who have collaborated the most and the # of collabs they have
def get_top_collaborators(by: 'song_weeks', results: 10)
	if by == 'song_weeks'
		get_song_weeks.sort{ |a,b| a[1] <=> b[1] }.reverse.take(results)
	elsif by == 'num_songs'
		get_num_songs.sort{ |a,b| a[1] <=> b[1] }.reverse.take(results)
	end
end

# puts array = get_top_collaborators(by: 'num_songs', results: 20)
# puts array.length
puts array = get_top_collaborators(by: 'num_songs', results: 10)
generate_csv("top_collabs", array, ["artist", "num"])