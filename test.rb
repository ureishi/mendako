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

query = '"今日のありがたカレンダー"'
result_tweets = $twitter_client.search(
	query, 
	count: 100,
	result_type: 'recent'
)

result_tweets.take(20).each_with_index{|tw, i|
	puts "#{i}: @#{tw.user.screen_name}: #{tw.full_text}"
}
