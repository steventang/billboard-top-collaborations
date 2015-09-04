# this script counts the number of times an artist has done a collaboration in our data
require 'csv'
require 'date'
require 'json'
# Creates a csv that separates out each artist from a collab
def pull_artists
	return_array = []
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

			# Remove all subbed commas
			artist_array.delete(",")
			artist_array.unshift(row['title']).unshift(row['date'])

			# Count number of collaborators
			return_array << artist_array.unshift(artist_array.length - 1)
		end
	end
	return_array
end

# Returns an array of arrays with unique_artists[0] as artist name and unique_artist[1] as occurences of artist
def get_song_weeks(start_date: '01-Jan-1990')
	all_artists = []
	CSV.foreach('data/complete_collabs_only.csv') do |row|
		# Add each artist entry into the array, with dupes, remove nils
		if Date.parse(row[1]) >= Date.parse(start_date)
			all_artists += row[3..-1].compact
		end
	end
	all_artists.uniq.map { |x| [x, all_artists.count(x)] }
end

# Returns all unique [artist, song] pairs
def get_artists_songs(start_date: '01-Jan-1990')
	all_artists_songs = []
	CSV.foreach('data/complete_collabs_only.csv') do |row|
		if Date.parse(row[1]) >= Date.parse(start_date)
			row[3..-1].compact.each do |i|
				all_artists_songs << [i, row[2]]
			end
		end
	end
	all_artists_songs.uniq
end

# Returns array of array of artists along with num of unique collab songs they've been a part of
def get_num_songs(start_date: '01-Jan-1990')
	artist_nums = []
	all_artists_songs = get_artists_songs(start_date: start_date)
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
def get_top_collaborators(by: 'song_weeks', results: 10, start_date: '01-Jan-1990')
	if by == 'song_weeks'
		get_song_weeks(start_date: start_date).sort{ |a,b| a[1] <=> b[1] }.reverse.take(results)
	elsif by == 'num_songs'
		get_num_songs(start_date: start_date).sort{ |a,b| a[1] <=> b[1] }.reverse.take(results)
	end
end

# Given an array of artists, count how many times they were the lead of a collab song and return an array
def count_num_leads(by: 'songs', artist_array: ['lil wayne'])
	counting_array = []
	return_array = []
	if by == 'songs'
		songs = pull_artists.uniq { |i| i[2] }
	elsif by == 'weeks'
		songs = pull_artists
	end
	songs.each do |row|
		if artist_array.include?(row[3])
			counting_array << row[3]
		end
	end
	artist_array.each do |artist|
		return_array << [artist, counting_array.count(artist)]
	end
	return_array
end

# Given an array of artists, count how many weeks they've had a collab song in top 10 and return in an array
def count_lead_weeks(artist_array: ['lil wayne'])
	counting_array = []
	return_array = []
	# Don't do unique here because we want to count every week
	songs = pull_artists
	songs.each do |row|
		if artist_array.include?(row[3])
			counting_array << row[3]
		end
	end
	artist_array.each do |artist|
		return_array << [artist, counting_array.count(artist)]
	end
	return_array
end
# we do it so that chord diagram points to itself if the collab was not with someone else in the group
# Diagram will show how many times a lead artist featured others
def create_chord_matrix(num_artists: 5, start_date: '01-Jan-1990')
	chord_matrix = []
	# Get array of top artists, sorted by num of collabs
	p artists = get_top_collaborators(by: 'num_songs', results: num_artists, start_date: start_date).transpose[0]
	# Initialize nxn matrix of 0's as default num times artists have collabed with one another
	artists.length.times { chord_matrix << Array.new(artists.length, 0) }
	p chord_matrix
	# Get only the unique instances of songs
	p songs = pull_artists.uniq { |i| i[2] }.keep_if { |i| Date.parse(i[1]) >= Date.parse(start_date) }
	songs.each do |row|
		if artists.include?(row[3])
			i = artists.index(row[3]) # i is the current artist for which we're trying to find all collaborators
			puts "i is #{i} features #{row[3]} with song #{row[2]}"
			row[4..-1].compact.each do |a|
				puts "a is #{a}"
				if artists.include?(a)
					j = artists.index(a) # j is the sorted position of the other collaborator
					#Increase ijth element by 1 if collaborator is also one of the top artists
					chord_matrix[i][j] += 1
				else
					#Increase i0th element by 1 if collaborator is not one of top artists
					chord_matrix[i][0] += 1
				end
			end
		end
	end
	chord_matrix
end

def create_directed_graph_json(num_artists: 5, start_date: '01-Jan-1990')
	links = []
	nodes = []
	links_array = []
	nodes_array = []
	# Get top artists
	artists = get_top_collaborators(by: 'num_songs', results: num_artists, start_date: start_date).transpose[0]
	# Get only the unique instances of songs
	songs = pull_artists.uniq { |i| i[2] }.keep_if { |i| Date.parse(i[1]) >= Date.parse(start_date) }
	
	## CREATE LINKS
	# First, get an array of all [source, collaborator] pairs
	songs.each do |row|
		# If at least 2 top artists are in a song
		if (artists & row[3..-1].compact).length > 1
			# Set source as the first top artist to appear as credited
			source = row[3..-1].find{ |i| artists.include?(i) }
			targets = (artists & row[3..-1])
			targets.delete(source)
			targets.each { |collaborator| links_array << [source, collaborator] }
		end
	end
	p "LNKS ARRAY #{links_array}"
	# Turn links_array pairs into hashes
	links_array.each do |source, target|
		value = links_array.count{ |pair| pair == [source, target] || pair == [target, source] } 
		links << {source: artists.index(source), target: artists.index(target), value: value}
		puts "created link #{source}, #{target}, #{value}"
		# Prevent inserting same hash multiple times
		# links_array.delete_if{ |pair| pair == [source, target] || pair == [target, source] }
	end
	links = links.uniq
	p links
	## CREATE NODES
	artists.each do |artist|
		# Assume using 20 colors in D3
		group = (artists.index(artist).to_f * (8.0 / artists.length.to_f)).round
		nodes << {name: artist, group: group }
	end
	# Return final json object, turning hashes into pretty json
  output = {nodes: nodes, links: links}
  output.to_json
	JSON.pretty_generate(output)
end

def count_unique_collab_songs
	pull_artists.uniq { |i| i[2] }.length
end

def count_all_unique_songs
	CSV.read('data/complete_song_data.csv').uniq { |i| i[2] }.length
end

# Returns the ratio of unique songs in the top 10
def song_collab_ratio
	count_unique_collab_songs.to_f / count_all_unique_songs.to_f
end