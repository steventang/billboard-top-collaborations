require 'nokogiri'
require 'open-uri'
require 'csv'

date = Date.new(1990, 1, 6)
end_date = Date.new(2015, 8, 22)
entries_per_week = 10

CSV.open('data/song_data.csv', "w") do |file|
	file << %w(date rank title artist)
	while date <= end_date
		page = Nokogiri::HTML(open("http://www.billboard.com/charts/hot-100/#{date.to_s}"))
		song_ranks = page.css('span.this-week')
		song_names = page.css('div.row-title h2')
		song_artists = page.css("div.row-title h3")
		for i in 0..entries_per_week-1
			file << [date.to_s,
							 song_ranks[i].text.strip,
							 song_names[i].text.strip,
							 song_artists[i].text.strip
							]
		end
		date += 7
		sleep 0.3
	end
end