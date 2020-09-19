require 'mini_magick'
require 'net/https'
require 'twitter'
require 'uri'

ENVIRONMENT = {
	TWITTER_CONSUMER_KEY: ARGV[0],
	TWITTER_CONSUMER_SECRET: ARGV[1],
	TWITTER_ACCESS_TOKEN: ARGV[2],
	TWITTER_ACCESS_TOKEN_SECRET: ARGV[3]
}

$client
def twitter_client
	return $client ||= Twitter::REST::Client.new{|config|
		config.consumer_key = ENVIRONMENT[:TWITTER_CONSUMER_KEY]
		config.consumer_secret = ENVIRONMENT[:TWITTER_CONSUMER_SECRET]
		config.access_token = ENVIRONMENT[:TWITTER_ACCESS_TOKEN]
		config.access_token_secret = ENVIRONMENT[:TWITTER_ACCESS_TOKEN_SECRET]
	}
end

def get_orig_image_uri s
	"#{s}?format=jpg&name=orig"
end

query = File.open('query.txt'){_1.gets}.chomp
puts "query: #{query}"

allowlist = File.open('allowlist.txt'){|f|
	f.each_line.map{|l| l.split.first.to_i}
}
puts "allowlist: #{allowlist}"

N = 10

result_tweets = twitter_client.search(
	query,
	count: N,
	result_type: 'recent'
)

puts

is_new = []
image_uri = []

first = true
result_tweets.take(N).each{|tw|
	if allowlist.include? tw.user.id
		sleep 10
		t = twitter_client.status tw, tweet_mode: 'extended'

		if t.media?
			t.media.each{
				image_uri << (_1.media_uri_https)
				is_new << first
			}
		end
	end
	
	break if image_uri.length >= 4
	first = false
}

puts "image_uri:\n\t#{image_uri.join "\n"}"

### create image
4.times{|page|
	image_url = image_uri[page]

	BASE_W = 1024
	BASE_H = 1448
	SIZE = 1024

	image = MiniMagick::Image.open 'base.png'
	image.resize "#{BASE_W}x#{BASE_H}!"
	image.format 'png'

	image.combine_options{
		pos_nw = '0, 0'
		pos_se = "#{BASE_W}, #{BASE_H}"
		_1.fill '#fcece1'
		_1.draw "rectangle #{pos_nw} #{pos_se}"
	}

	image_base = image

	image_over = MiniMagick::Image.open image_url
	#image_over = MiniMagick::Image.open 'mendako_none.png'
	image_over.resize "#{SIZE}x#{SIZE}"

	image = image_base.composite image_over{
		_1.compose 'Over'
		_1.gravity 'Center'
		_1.geometry "+0+0"
	}

	image.combine_options{
		pos = '0, 30'
		text = 'まいにちめんだこ'
		_1.font './.font/memoir-round.otf'
		_1.fill '#f9832c'
		_1.gravity 'North'
		_1.pointsize 125
		_1.stroke '#ffffff'
		_1.strokewidth 3
		_1.draw "text #{pos} '#{text}'"
	}

	image.combine_options{
		pos = '55, 160'
		text = '@daily_mendako'
		_1.font '.font/Noto_Sans_JP/NotoSansJP-Regular.otf'
		_1.fill '#000000'
		_1.gravity 'NorthEast'
		_1.pointsize 30
		_1.draw "text #{pos} '#{text}'"
	}

	NEW_ICON_X = [-146, -48, 50, 148]
	4.times{|i|
		next if !is_new[i]
		image.combine_options{
			pos = "#{NEW_ICON_X[i]}, 625"
			text = 'NEW!'
			_1.font './.font/memoir-round.otf'
			_1.fill '#a31d12'
			_1.gravity 'Center'
			_1.pointsize 25
			_1.draw "text #{pos} '#{text}'"
		}
	}

	image.combine_options{
		pos_nw = "0, #{BASE_H - 88}"
		pos_se = "#{BASE_W}, #{BASE_H}"
		_1.fill '#ffc575'
		_1.draw "rectangle #{pos_nw} #{pos_se}"
	}

	image.write "public/mendako#{page}.png"
}