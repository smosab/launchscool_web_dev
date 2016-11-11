require "sinatra"
require "sinatra/reloader" if development?
require "pry"

get "/" do
  # data_dir = Dir.new("data/")
  # @entries = data_dir.grep /.txt/

  @files = Dir["data/*.txt"].map { |file| File.basename(file) }
  erb :index
end

get "/:file" do
  # binding.pry
  headers["Content-Type"] = "text/plain"
  file = File.read("data/#{params[:file]}")
end
