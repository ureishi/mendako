require 'twitter'

ENVIRONMENT = {
	'TWITTER_CONSUMER_KEY' => ARGV[0],
	'TWITTER_CONSUMER_SECRET' => ARGV[1],
	'TWITTER_ACCESS_TOKEN' => ARGV[2],
	'TWITTER_ACCESS_TOKEN_SECRET' => ARGV[3]
}

$client
def twitter_client
  return $client ||= Twitter::REST::Client.new{|config|
    config.consumer_key = ENVIRONMENT['TWITTER_CONSUMER_KEY']
    config.consumer_secret = ENVIRONMENT['TWITTER_CONSUMER_SECRET']
    config.access_token = ENVIRONMENT['TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENVIRONMENT['TWITTER_ACCESS_TOKEN_SECRET']
  }
end

query = "from:aivrc リズム"
since_id = nil
result_tweets = twitter_client.search(
	query,
	count: 100
)

pictures = result_tweets.take(100).map{|tw|
	if tw.media.first
		tw.media.map{"#{_1.media_uri_https}?format=jpg&name=orig"}
	end
}
a = pictures.flatten.uniq
p a
file_name = 'hitokoto.jpg'
c = "wget -O #{file_name} #{a[0]}"
`#{c}`
