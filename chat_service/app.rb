require 'sinatra'
require 'bunny'
require 'json'

# Connect to RabbitMQ
rabbitmq_url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672'
conn = Bunny.new(rabbitmq_url)
conn.start
channel = conn.create_channel
exchange = channel.fanout('chat_exchange')

post '/send' do
  content_type :json
  message = params[:message] || "Hello from chat!"
  exchange.publish({ message: message }.to_json)
  { status: 'sent', message: message }.to_json
end

get '/' do
  "Chat Service - send your message via /send?message=your_message"
end