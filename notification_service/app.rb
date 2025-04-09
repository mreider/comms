require 'sinatra'
require 'bunny'
require 'json'

rabbitmq_url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672'
conn = Bunny.new(rabbitmq_url)
conn.start
channel = conn.create_channel
exchange = channel.fanout('chat_exchange')
queue = channel.queue('', exclusive: true)
queue.bind(exchange)

Thread.new do
  queue.subscribe(block: false) do |_delivery_info, _properties, body|
    data = JSON.parse(body)
    puts "New notification: #{data['message']}"
  end
end

get '/' do
  "Notification Service - Listening for messages..."
end

sleep