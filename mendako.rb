require 'mini_magick'
require 'net/https'
require 'twitter'
require 'uri'

### get image from twitter
puts "get image..."
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

query = 'from:daily_mendako filter:images'
puts "query: #{query}"

allowlist = [1118339375299850241]
puts "allowlist:\n\t#{allowlist.join "\n\t"}"

N = 10

result_tweets = twitter_client.search(
	query,
	count: N,
	result_type: 'recent'
)

$image_uri = []
$count_new = 0

first = true
result_tweets.take(N).each{|tw|
	if allowlist.include? tw.user.id
		sleep 10
		t = twitter_client.status tw, tweet_mode: 'extended'
		t.media.each{
			$image_uri << "#{_1.media_uri_https}?name=orig"
			$count_new += 1 if first
		} if t.media?
	end
	
	break if $image_uri.length >= 4
	first = false
}

puts "image_uri:\n\t#{$image_uri.join "\n\t"}"

### create directory
puts "create directory..."
Dir.mkdir 'public' unless Dir.exists? 'public'
puts "created: public"

### create image
puts "create image..."
BASE_W = 1024
BASE_H = 1448
SIZE = 1000
NEW_ICON_X = [-146, -48, 50, 148]

MiniMagick::Tool::Convert.new{|c|
	c.size "#{BASE_W}x#{BASE_H}"
	c << 'canvas:#fcece1'
	c << 'base.png'
}

image = MiniMagick::Image
.open('base.png')
.combine_options{
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
.combine_options{
	pos = '55, 160'
	text = '@daily_mendako'
	_1.font '.font/Noto_Sans_JP/NotoSansJP-Regular.otf'
	_1.fill '#000000'
	_1.gravity 'NorthEast'
	_1.pointsize 30
	_1.draw "text #{pos} '#{text}'"
}
.combine_options{
	pos_nw = "0, #{BASE_H - 88*2}"
	pos_se = "#{BASE_W}, #{BASE_H}"
	_1.fill '#ffc575'
	_1.draw "rectangle #{pos_nw} #{pos_se}"
}

$count_new.times{|i|
	image.combine_options{
		pos = "#{NEW_ICON_X[i]*2}, 536"
		text = 'NEW!'
		_1.font './.font/memoir-round.otf'
		_1.fill '#a31d12'
		_1.gravity 'Center'
		_1.pointsize 25
		_1.draw "text #{pos} '#{text}'"
	}
}

image.write 'base.png'
puts "created: base.png"

4.times{|p|
	image = MiniMagick::Image
	.open('base.png')
	.composite(
		MiniMagick::Image
		.open($image_uri[p] || 'not_found.png')
		.resize("#{SIZE}x#{SIZE}")
	){
		_1.compose 'Over'
		_1.gravity 'Center'
		_1.geometry "+0+0"
	}
	
	image.write "public/mendako#{p}.png"
	puts "created: mendako#{p}.png"
}

### optimize
puts "optimize"
`pngquant --force --ext .png --speed 1 public/mendako*.png`
`advpng -z -4 -i 10 public/mendako*.png`

puts "finished"
