# this script counts the number of times an artist has done a collaboration in our data
require 'csv'

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

			# Add date to begnning of each row before writing to csv
			artist_array.unshift(row['date'])

			# Count number of collabooraters
			artist_array.unshift(artist_array.length - 1)

			csv << artist_array
		end
	end
end