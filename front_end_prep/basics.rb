require 'sinatra'

get '/secret' do
  erb :secret
end

post '/secret' do
  params[:secret].reverse
end

post '/secret' do
  params[:secret].reverse
end

get '/' do
  "Hello, World!"
end

get '/about' do
  'A little about me.'
end

get '/hello/:name' do
  "Hello there, #{params[:name].reverse}."
end

get '/hello/:name/:city' do
  "Hey there #{params[:name]} from #{params[:city]}."
end

get '/more/*' do
  params[:splat]
end

get '/form' do
  erb :form
end

post '/form' do
  "You said '#{params[:message]}'"
end

get '/recipe' do
  html :pb_grilled_cheese
end
