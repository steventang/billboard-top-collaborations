require 'mechanize'
require 'nokogiri'
require 'open-uri'

#Song = Struct.new(:title, :date, :artist)#

# agent = Mechanize.new { |agent|
	# agent.user_agent_alias = 'Windows Chrome'
# }
# 
# page = agent.get('http://www.billboard.com/charts/hot-100/1990-02-03')
# 
# puts page.at('span.this-week').text
# puts page.at('div.row-title h2').text
# puts page.at('div.row-title h3').text

date = Date.new(1990, 1, 6)
end_date = Date.new(1990, 1, 27)

while date < end_date
	page = Nokogiri::HTML(open("http://www.billboard.com/charts/hot-100/#{date.to_s}"))# 
	song_ranks = page.css('span.this-week')
	song_names = page.css('div.row-title h2')
	song_artists = page.css("div.row-title h3") #.css("a[data-tracklabel='Artist Name']")# 
	puts song_ranks[5].text
	puts song_names[5].text
	puts song_artists[1].text
end