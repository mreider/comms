require 'sinatra'
require 'bunny'
require 'pg'
require 'json'
require 'uri'

rabbitmq_url = ENV['RABBITMQ_URL'] || 'amqp://localhost:5672'
conn = Bunny.new(rabbitmq_url)
conn.start
channel = conn.create_channel
exchange = channel.fanout('chat_exchange')
queue = channel.queue('', exclusive: true)
queue.bind(exchange)

# Connect to Postgres
postgres_url = ENV['POSTGRES_URL'] || 'postgres://demo:demo@localhost:5432/demo'
uri = URI.parse(postgres_url)
conn_pg = PG.connect(
  host: uri.host,
  port: uri.port,
  user: uri.user,
  password: uri.password,
  dbname: uri.path[1..-1]
)
conn_pg.exec("CREATE TABLE IF NOT EXISTS logs (id SERIAL PRIMARY KEY, message TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP);")

Thread.new do
  queue.subscribe(block: false) do |_delivery_info, _properties, body|
    data = JSON.parse(body)
    puts "Logging message: #{data['message']}"
    conn_pg.exec_params("INSERT INTO logs (message) VALUES ($1)", [data['message']])
  end
end

get '/' do
  "Logging Service - Listening for messages..."
end

sleep